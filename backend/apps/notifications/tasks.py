import logging
from django.conf import settings
from django.utils import timezone
from celery import shared_task
from .models import Notification, NotificationStatus, FCMDevice, TargetAudience
from apps.roles.models import RoleType

logger = logging.getLogger(__name__)


@shared_task
def send_push_notification_task(notification_id):
    """
    Procesamiento de notificaciones directo a través del Backend de Django.
    No requiere Firebase ni servicios de terceros.
    """
    try:
        notification = Notification.objects.get(id=notification_id)
    except Notification.DoesNotExist:
        logger.error(f"Notificación con ID {notification_id} no existe.")
        return

    # Marcar la notificación como enviada directamente en el backend de Django
    notification.status = NotificationStatus.SENT
    notification.sent_at = timezone.now()
    notification.error_message = ""
    notification.save()

    logger.info(f"Notificación {notification_id} enviada exitosamente desde el backend de Django.")
