"""
Envío de notificaciones push a través de Firebase Cloud Messaging.

Hasta ahora la "notificación" sólo se marcaba como enviada en la base de datos
y la app la descubría sondeando mientras estaba abierta: con la aplicación
cerrada no llegaba nada. Aquí está el envío de verdad.

Si no hay credenciales configuradas el sistema no se rompe: la notificación
queda registrada igual y se anota el motivo, de modo que siga viéndose dentro
de la app aunque no salte el aviso en el teléfono.
"""

import logging

import firebase_admin
from django.conf import settings
from django.db.models import Q
from firebase_admin import credentials, exceptions, messaging

from apps.roles.models import RoleType

logger = logging.getLogger(__name__)

#: Nombre propio para no chocar con otra inicialización del SDK.
_APP_NAME = 'genesis-push'

#: FCM admite hasta 500 destinatarios por envío.
_BATCH_SIZE = 500


def get_firebase_app():
    """
    Devuelve la aplicación de Firebase, inicializándola la primera vez.

    Devuelve `None` cuando no hay credenciales: quien llama decide qué hacer,
    en lugar de fallar y dejar la notificación a medias.
    """
    # Las credenciales se comprueban antes que la caché: si se retiran, el
    # envío debe detenerse aunque la aplicación siguiera inicializada de antes.
    raw_credentials = getattr(settings, 'FIREBASE_CREDENTIALS', None)
    if not raw_credentials:
        return None

    existing = firebase_admin._apps.get(_APP_NAME)
    if existing is not None:
        return existing

    try:
        certificate = credentials.Certificate(raw_credentials)
        return firebase_admin.initialize_app(certificate, name=_APP_NAME)
    except Exception as error:
        logger.error('No se pudo inicializar Firebase: %s', error)
        return None


def _excluding_sender(devices, notification):
    """
    Aparta del reparto los dispositivos de quien firma el aviso.

    A nadie le informa recibir en su propio teléfono el mensaje que acaba de
    escribir: es ruido, y encima hace dudar de si salió de verdad o se quedó
    dando vueltas. El líder escribe para su célula; el pastor, para la iglesia.

    Los dispositivos sin cuenta —modo invitado— se conservan siempre. Hay que
    decirlo con `user__isnull`, porque en SQL comparar un nulo no da ni
    verdadero ni falso, y un `exclude` a secas se los llevaría por delante.
    """
    if not notification.sender_id:
        return devices

    return devices.filter(
        Q(user__isnull=True) | ~Q(user_id=notification.sender_id)
    )


def resolve_target_tokens(notification):
    """
    Tokens de los dispositivos que deben recibir esta notificación.

    Sigue las reglas del feed dentro de la app, con una diferencia buscada:
    quien envía no se recibe a sí mismo. En el listado su aviso sí aparece,
    como constancia de lo que mandó, pero el teléfono no le suena.
    """
    from django.contrib.auth import get_user_model

    from .models import FCMDevice, TargetAudience

    User = get_user_model()
    audience = notification.target_audience

    # 1. Aviso dirigido a una persona concreta.
    #
    # Aquí no se aparta a nadie: si alguien se escribe a sí mismo, es lo que
    # ha pedido expresamente.
    if notification.target_user_id:
        return list(
            FCMDevice.objects.filter(user_id=notification.target_user_id)
            .values_list('token', flat=True)
            .distinct()
        )

    # 2. Recordatorio de una célula: sus miembros y quien la lidera.
    #
    # El líder sigue en la lista, y es a propósito: cuando el recordatorio lo
    # manda su coordinador o el pastorado, tiene que enterarse como el que
    # más. Lo que no ocurre es que se lo mande él y le vuelva.
    if audience == TargetAudience.CELL and notification.target_cell_id:
        recipients = User.objects.filter(assigned_cell_id=notification.target_cell_id) | \
            User.objects.filter(led_cells__id=notification.target_cell_id)
        return list(
            _excluding_sender(
                FCMDevice.objects.filter(user__in=recipients.distinct()), notification
            )
            .values_list('token', flat=True)
            .distinct()
        )

    # 3. Audiencias masivas.
    if audience == TargetAudience.ALL:
        # Incluye los dispositivos sin cuenta asociada (modo invitado).
        return list(
            _excluding_sender(FCMDevice.objects.all(), notification)
            .values_list('token', flat=True)
            .distinct()
        )

    role_by_audience = {
        TargetAudience.LEADERS: RoleType.CELL_LEADER,
        TargetAudience.MEMBERS: RoleType.MEMBER,
        # Lo que un líder escribe hacia arriba llega a quien pastorea la
        # iglesia, no al superadministrador, que es una figura técnica.
        TargetAudience.PASTORS: RoleType.ADMIN,
    }
    role = role_by_audience.get(audience)
    if role:
        return list(
            _excluding_sender(
                FCMDevice.objects.filter(user__user_roles__role__name=role), notification
            )
            .values_list('token', flat=True)
            .distinct()
        )

    return []


def _build_message(notification, token):
    """
    Construye el aviso para un dispositivo.

    Los datos viajan también en `data` para que la app pueda actuar al tocarlo
    aunque el sistema ya haya mostrado el aviso por su cuenta.
    """
    return messaging.Message(
        token=token,
        notification=messaging.Notification(
            title=notification.title,
            body=notification.body,
        ),
        data={
            'notification_id': str(notification.id),
            'title': notification.title,
            'body': notification.body,
            'audience': str(notification.target_audience),
            'cell_id': str(notification.target_cell_id or ''),
            # Vista que abre la app al tocar el aviso.
            'deep_link': notification.deep_link or '',
            # Android sólo entrega al `onMessageOpenedApp` de Flutter los avisos
            # que traen esta marca; sin ella, tocar la notificación con la app
            # cerrada abría la pantalla de inicio y se perdía el destino.
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='genesis_channel',
                sound='default',
                # Que el aviso aparezca sobre la pantalla, no sólo en la barra.
                priority='max',
            ),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound='default', badge=1),
            ),
        ),
    )


def _discard_invalid_tokens(tokens, responses):
    """
    Borra los tokens que Firebase declara inservibles.

    Un teléfono que desinstaló la app deja su token muerto; conservarlos hace
    que cada envío falle una parte y ensucie el diagnóstico.
    """
    from .models import FCMDevice

    # Se comprueba el tipo de error, no su texto: Firebase expone el codigo en
    # mayusculas y con guion bajo ('NOT_FOUND'), asi que comparar cadenas
    # sueltas dejaba pasar todos los tokens muertos.
    descartables = (
        messaging.UnregisteredError,      # la app se desinstalo
        messaging.SenderIdMismatchError,  # el token es de otro proyecto
        exceptions.NotFoundError,         # el registro ya no existe
        exceptions.InvalidArgumentError,  # token mal formado
    )

    dead = []
    for token, response in zip(tokens, responses):
        if response.success:
            continue
        error = getattr(response, 'exception', None)
        if isinstance(error, descartables):
            dead.append(token)

    if dead:
        FCMDevice.objects.filter(token__in=dead).delete()
        logger.info('Se descartaron %d dispositivos con token inservible.', len(dead))

    return len(dead)


def send_notification(notification):
    """
    Envía la notificación a los dispositivos que corresponda.

    Devuelve un resumen del envío: cuántos recibieron, cuántos fallaron y, si
    no se pudo enviar, el motivo, que se guarda en la propia notificación.
    """
    app = get_firebase_app()
    if app is None:
        return {
            'sent': 0,
            'failed': 0,
            'detail': (
                'Sin credenciales de Firebase: la notificación queda registrada y '
                'se verá dentro de la app, pero no llega al teléfono con la app cerrada. '
                'Define FIREBASE_CREDENTIALS en el entorno del servidor.'
            ),
        }

    tokens = resolve_target_tokens(notification)
    if not tokens:
        return {'sent': 0, 'failed': 0, 'detail': 'No hay dispositivos registrados para esta audiencia.'}

    enviados = 0
    fallidos = 0
    descartados = 0

    for start in range(0, len(tokens), _BATCH_SIZE):
        lote = tokens[start:start + _BATCH_SIZE]
        mensajes = [_build_message(notification, token) for token in lote]
        try:
            resultado = messaging.send_each(mensajes, app=app)
        except Exception as error:
            logger.error('Fallo al enviar el lote de notificaciones: %s', error)
            fallidos += len(lote)
            continue

        enviados += resultado.success_count
        fallidos += resultado.failure_count
        descartados += _discard_invalid_tokens(lote, resultado.responses)

    detalle = f'Entregada a {enviados} dispositivo(s).'
    if fallidos:
        detalle += f' {fallidos} fallo(s).'
    if descartados:
        detalle += f' {descartados} dispositivo(s) dado(s) de baja.'

    return {'sent': enviados, 'failed': fallidos, 'detail': detalle}


def dispatch(notification):
    """
    Entrega el aviso en el momento y deja anotado cómo fue.

    Antes esto se encolaba en Celery. Parece más prudente, pero si el trabajador
    no estaba levantado `.delay()` no da ningún error: la tarea se quedaba en la
    cola, nadie la ejecutaba y el panel seguía mostrando «enviado». El fallo era
    invisible justo cuando más importaba, y no había forma de distinguirlo de un
    envío correcto.

    Un envío son una o dos llamadas a Firebase —los destinatarios van en lotes
    de 500—, así que hacerlo aquí cuesta poco y a cambio el estado que se
    muestra es verdad. Los avisos programados sí siguen pasando por Celery, que
    es para lo que sirve.

    Nunca propaga el fallo: la notificación ya está registrada y debe verse
    dentro de la app aunque no haya salido al teléfono.
    """
    from django.utils import timezone

    from .models import NotificationStatus

    try:
        resultado = send_notification(notification)
    except Exception as error:
        logger.error('No se pudo enviar la notificación %s: %s', notification.id, error)
        resultado = {'sent': 0, 'failed': 0, 'detail': f'Error al enviar: {error}'}

    notification.error_message = '' if resultado['sent'] else resultado['detail']
    if notification.status != NotificationStatus.SENT:
        notification.status = NotificationStatus.SENT
        notification.sent_at = timezone.now()

    try:
        notification.save(update_fields=['status', 'sent_at', 'error_message'])
    except Exception as error:
        logger.error('No se pudo anotar el resultado del envío: %s', error)

    return resultado
