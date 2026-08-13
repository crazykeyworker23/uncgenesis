from django.db import models
from django.conf import settings

class DeviceType(models.TextChoices):
    ANDROID = 'ANDROID', 'Android'
    IOS = 'IOS', 'iOS'
    WEB = 'WEB', 'Web'


class FCMDevice(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='fcm_devices'
    )
    token = models.TextField(unique=True)
    device_type = models.CharField(
        max_length=20,
        choices=DeviceType.choices,
        default=DeviceType.ANDROID
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'dispositivo FCM'
        verbose_name_plural = 'dispositivos FCM'

    def __str__(self):
        owner = self.user.email if self.user else "Invitado"
        return f"{owner} - {self.device_type} ({self.token[:20]}...)"


class NotificationStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pendiente'
    SENT = 'SENT', 'Enviado'
    FAILED = 'FAILED', 'Fallido'


class TargetAudience(models.TextChoices):
    ALL = 'ALL', 'Todos'
    LEADERS = 'LEADERS', 'Líderes de Célula'
    MEMBERS = 'MEMBERS', 'Miembros Registrados'
    USER = 'USER', 'Usuario Específico'
    CELL = 'CELL', 'Miembros de una Célula'
    # Permite que un líder escriba hacia arriba, a quien pastorea la iglesia,
    # sin abrirle la difusión general.
    PASTORS = 'PASTORS', 'Pastorado'


class Notification(models.Model):
    title = models.CharField(max_length=150)
    body = models.TextField()
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='sent_notifications'
    )
    target_audience = models.CharField(
        max_length=20,
        choices=TargetAudience.choices,
        default=TargetAudience.ALL
    )
    target_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='received_notifications'
    )
    # Destinatario cuando la audiencia es CELL: permite que un líder avise
    # únicamente a los miembros de la célula que tiene a su cargo.
    target_cell = models.ForeignKey(
        'cells.CellGroup',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='notifications'
    )
    status = models.CharField(
        max_length=20,
        choices=NotificationStatus.choices,
        default=NotificationStatus.PENDING
    )
    # Vista que debe abrirse al tocar el aviso, como ruta de la app
    # ('/devotionals/mi-slug', '/cells/3'). Vacío significa que se abre el
    # listado de notificaciones, que es lo razonable para un aviso suelto.
    deep_link = models.CharField(max_length=200, blank=True, default='')
    scheduled_for = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    error_message = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'notificación'
        verbose_name_plural = 'notificaciones'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.get_status_display()})"
