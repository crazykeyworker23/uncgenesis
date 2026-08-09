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

    resultado = send_notification(notification)

    notification.status = NotificationStatus.SENT
    notification.sent_at = timezone.now()
    notification.error_message = '' if resultado['sent'] else resultado['detail']
    notification.save()

    logger.info('Notificación %s: %s', notification_id, resultado['detail'])
    return resultado


@shared_task
def deliver_pending_notifications():
    """
    Reintenta las notificaciones que quedaron pendientes.

    Cubre el caso de que el envío fallara por una caída momentánea de red o
    porque el servidor estuviera reiniciándose a la hora programada.
    """
    vencidas = Notification.objects.filter(
        status=NotificationStatus.PENDING,
        scheduled_for__lte=timezone.now(),
    )

    for notification in vencidas:
        send_push_notification_task.delay(notification.id)

    return vencidas.count()


__all__ = [
    'deliver_pending_notifications',
    'firebase_app',
    'get_firebase_app',
    'send_push_notification_task',
]
