import logging

from celery import shared_task
from django.utils import timezone

from .models import Notification, NotificationStatus
from .push import get_firebase_app, send_notification

logger = logging.getLogger(__name__)

# Se mantiene el nombre por compatibilidad con quien ya lo importaba.
firebase_app = None


@shared_task
def send_push_notification_task(notification_id):
    """
    Entrega la notificación a los teléfonos y la marca como enviada.

    Antes esta tarea sólo cambiaba el estado en la base de datos, así que el
    aviso únicamente aparecía si la persona tenía la app abierta y esperaba al
    siguiente sondeo. Ahora sale por Firebase y llega también con la
    aplicación cerrada.

    Si no hay credenciales configuradas la notificación se registra igual y el
    motivo queda anotado: se seguirá viendo dentro de la app.
    """
    try:
        notification = Notification.objects.get(id=notification_id)
    except Notification.DoesNotExist:
        logger.error('La notificación %s ya no existe.', notification_id)
        return

    # El aviso se reserva antes de enviarlo, cambiando su estado en una sola
    # operación de base de datos. Ahora hay dos caminos que pueden pedir el
    # mismo envío —la tarea programada con `eta` y la ronda de repesca de cada
    # cinco minutos—, y sin esta reserva la gente recibiría el aviso dos veces:
    # si la ronda pasa justo cuando vence la hora, o mientras un envío largo
    # sigue en curso, encolaría un duplicado. Quien llega primero se lo queda.
    reservado = Notification.objects.filter(
        id=notification_id,
        status__in=[NotificationStatus.PENDING, NotificationStatus.FAILED],
    ).update(status=NotificationStatus.SENT, sent_at=timezone.now())

    if not reservado:
        logger.info('La notificación %s ya estaba entregada; no se repite.', notification_id)
        return

    resultado = send_notification(notification)

    notification.status = NotificationStatus.SENT
    notification.error_message = '' if resultado['sent'] else resultado['detail']
    # `sent_at` ya quedó anotado al reservar el aviso; no se vuelve a tocar.
    notification.save(update_fields=['status', 'error_message'])

    logger.info('Notificación %s: %s', notification_id, resultado['detail'])
    return resultado


@shared_task
def deliver_pending_notifications():
    """
    Reintenta las notificaciones que quedaron pendientes.

    Cubre el caso de que el envío fallara por una caída momentánea de red o
    porque el servidor estuviera reiniciándose a la hora programada.

    Encolar un aviso que ya salió no lo duplica: la tarea de envío lo reserva
    antes de entregarlo y descarta la repetición.
    """
    # La lista se materializa aquí: al encolar, cada aviso pasa a «enviado», de
    # modo que volver a contar la consulta al final devolvía cero.
    vencidas = list(
        Notification.objects.filter(
            status=NotificationStatus.PENDING,
            scheduled_for__lte=timezone.now(),
        ).values_list('id', flat=True)
    )

    for notification_id in vencidas:
        send_push_notification_task.delay(notification_id)

    return len(vencidas)


__all__ = [
    'deliver_pending_notifications',
    'firebase_app',
    'get_firebase_app',
    'send_push_notification_task',
]
