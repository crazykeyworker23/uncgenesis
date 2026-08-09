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


def resolve_target_tokens(notification):
    """
    Tokens de los dispositivos que deben recibir esta notificación.

    Sigue las mismas reglas que el feed dentro de la app, para que lo que llega
    al teléfono y lo que se ve en el listado coincidan.
    """
    from django.contrib.auth import get_user_model

    from .models import FCMDevice, TargetAudience

    User = get_user_model()
    audience = notification.target_audience

    # 1. Aviso dirigido a una persona concreta.
    if notification.target_user_id:
        return list(
            FCMDevice.objects.filter(user_id=notification.target_user_id)
            .values_list('token', flat=True)
            .distinct()
        )

    # 2. Recordatorio de una célula: sus miembros y quien la lidera.
    if audience == TargetAudience.CELL and notification.target_cell_id:
        recipients = User.objects.filter(assigned_cell_id=notification.target_cell_id) | \
            User.objects.filter(led_cells__id=notification.target_cell_id)
        return list(
            FCMDevice.objects.filter(user__in=recipients.distinct())
            .values_list('token', flat=True)
            .distinct()
        )

    # 3. Audiencias masivas.
    if audience == TargetAudience.ALL:
        # Incluye los dispositivos sin cuenta asociada (modo invitado).
        return list(FCMDevice.objects.values_list('token', flat=True).distinct())

    role_by_audience = {
        TargetAudience.LEADERS: RoleType.CELL_LEADER,
        TargetAudience.MEMBERS: RoleType.MEMBER,
    }
    role = role_by_audience.get(audience)
    if role:
        return list(
            FCMDevice.objects.filter(user__user_roles__role__name=role)
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
    Pone en marcha el envío de una notificación ya creada.

    Lo normal es encolarlo para no hacer esperar a quien la escribió. Si el
    broker no responde se envía en el momento: es preferible tardar un segundo
    más que perder el aviso. En ningún caso se propaga el fallo, porque la
    notificación ya está registrada y debe verse dentro de la app.
    """
    from .tasks import send_push_notification_task

    try:
        send_push_notification_task.delay(notification.id)
        return
    except Exception as error:
        logger.warning('No se pudo encolar el envío (%s); se intenta en el momento.', error)

    try:
        send_notification(notification)
    except Exception as error:
        logger.error('Tampoco se pudo enviar en el momento: %s', error)
