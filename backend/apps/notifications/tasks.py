import logging
from django.conf import settings
from django.utils import timezone
from celery import shared_task
from .models import Notification, NotificationStatus, FCMDevice, TargetAudience
from apps.roles.models import RoleType

logger = logging.getLogger(__name__)

# Safely initialize Firebase App
firebase_app = None
try:
    if getattr(settings, 'FIREBASE_CREDENTIALS', None):
        import firebase_admin
        from firebase_admin import credentials
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS)
        firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin initialized successfully.")
except Exception as e:
    logger.warning(f"Failed to initialize Firebase Admin. Falling back to simulation. Error: {e}")


@shared_task
def send_push_notification_task(notification_id):
    try:
        notification = Notification.objects.get(id=notification_id)
    except Notification.DoesNotExist:
        logger.error(f"Notification with id {notification_id} does not exist.")
        return

    # Update status to PENDING if not already
    if notification.status != NotificationStatus.PENDING:
        logger.warning(f"Notification {notification_id} is already in state {notification.status}.")
        return

    # Check if scheduled for the future and not yet time (e.g. in eager mode testing)
    if notification.scheduled_for and notification.scheduled_for > timezone.now():
        logger.info(f"Notification {notification_id} is scheduled for {notification.scheduled_for}. Skipping execution until scheduled time.")
        return

    # Determine recipient devices based on audience segment
    devices = FCMDevice.objects.all()
    if notification.target_audience == TargetAudience.LEADERS:
        devices = devices.filter(user__user_roles__role__name=RoleType.CELL_LEADER)
    elif notification.target_audience == TargetAudience.MEMBERS:
        devices = devices.filter(user__user_roles__role__name=RoleType.MEMBER)
    elif notification.target_audience == TargetAudience.USER and notification.target_user:
        devices = devices.filter(user=notification.target_user)

    tokens = list(devices.values_list('token', flat=True).distinct())

    if not tokens:
        # No devices to send to
        notification.status = NotificationStatus.SENT
        notification.sent_at = timezone.now()
        notification.error_message = "No registered devices for this audience."
        notification.save()
        logger.info(f"Notification {notification_id} completed with 0 devices.")
        return

    # If Firebase app is initialized, send via SDK. Otherwise simulate.
    # Check if we are running in tests
    is_testing = getattr(settings, 'TESTING', False)
    use_simulation = (firebase_app is None or is_testing)

    if use_simulation:
        # Simulation mode
        logger.info(f"[SIMULATION] Sending push notification to {len(tokens)} tokens.")
        logger.info(f"[SIMULATION] Title: {notification.title} | Body: {notification.body}")
        
        notification.status = NotificationStatus.SENT
        notification.sent_at = timezone.now()
        notification.error_message = f"Simulation: successfully sent to {len(tokens)} dummy tokens."
        notification.save()
        return

    # Actual sending via Firebase Admin SDK
    try:
        import firebase_admin
        from firebase_admin import messaging

        # Group tokens into batches of 500 (FCM limit for multicast)
        batch_size = 500
        success_count = 0
        failure_count = 0
        errors = []

        for i in range(0, len(tokens), batch_size):
            token_batch = tokens[i:i + batch_size]
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=notification.title,
                    body=notification.body,
                ),
                data={
                    "title": str(notification.title),
                    "body": str(notification.body),
                    "id": str(notification.id),
                    "target_audience": str(notification.target_audience),
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                },
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='high_importance_channel',
                        sound='default',
                        default_sound=True,
                        default_vibrate_timings=True,
                        priority='high',
                        color='#D4AF37',
                        icon='ic_notification',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                            content_available=True,
                        ),
                    ),
                ),
                tokens=token_batch,
            )
            if hasattr(messaging, 'send_each_for_multicast'):
                response = messaging.send_each_for_multicast(message)
            else:
                response = messaging.send_multicast(message)
            success_count += response.success_count
            failure_count += response.failure_count

            # Collect details of failed tokens and cleanup invalid ones
            if response.failure_count > 0:
                invalid_tokens_to_delete = []
                for idx, resp in enumerate(response.responses):
                    if not resp.success:
                        bad_token = token_batch[idx]
                        exc = resp.exception
                        exc_msg = getattr(exc, 'message', None) or str(exc)
                        exc_code = getattr(exc, 'code', 'error')
                        errors.append(f"Token {bad_token[:15]}...: {exc_code} - {exc_msg}")
                        invalid_tokens_to_delete.append(bad_token)
                if invalid_tokens_to_delete:
                    FCMDevice.objects.filter(token__in=invalid_tokens_to_delete).delete()

        # Update notification object status
        if success_count > 0:
            notification.status = NotificationStatus.SENT
            notification.error_message = f"Sent successfully to {success_count} devices. Failures: {failure_count}."
            if errors:
                notification.error_message += " Errors: " + "; ".join(errors[:5])
        else:
            notification.status = NotificationStatus.FAILED
            notification.error_message = f"All sends failed ({failure_count} failures). Errors: " + "; ".join(errors[:5])

        notification.sent_at = timezone.now()
        notification.save()

    except Exception as exc:
        logger.exception("Error sending FCM notification")
        notification.status = NotificationStatus.FAILED
        notification.error_message = f"Internal Exception: {str(exc)}"
        notification.sent_at = timezone.now()
        notification.save()
