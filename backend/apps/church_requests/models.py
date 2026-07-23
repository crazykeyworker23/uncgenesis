from django.db import models
from apps.users.models import CustomUser


class RequestStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pendiente'
    IN_PROGRESS = 'IN_PROGRESS', 'En proceso'
    RESOLVED = 'RESOLVED', 'Resuelto'
    ARCHIVED = 'ARCHIVED', 'Archivado'


class AgeRange(models.TextChoices):
    YOUTH = 'YOUTH', '15-25 años'
    YOUNG_ADULT = 'YOUNG_ADULT', '26-35 años'
    ADULT = 'ADULT', '36-50 años'
    SENIOR = 'SENIOR', '51+ años'
    PREFER_NOT_SAY = 'PREFER_NOT_SAY', 'Prefiero no decir'


class HowFound(models.TextChoices):
    SOCIAL_MEDIA = 'SOCIAL_MEDIA', 'Redes sociales'
    FRIEND_FAMILY = 'FRIEND_FAMILY', 'Amigo o familiar'
    WEBSITE = 'WEBSITE', 'Página web'
    STREET = 'STREET', 'Pasé por la iglesia'
    EVENT = 'EVENT', 'Evento'
    OTHER = 'OTHER', 'Otro'


class PreferredContact(models.TextChoices):
    EMAIL = 'EMAIL', 'Correo electrónico'
    PHONE = 'PHONE', 'Llamada telefónica'
    WHATSAPP = 'WHATSAPP', 'WhatsApp'


class PrayerRequest(models.Model):
    requester_name = models.CharField(max_length=150)
    requester_email = models.EmailField(blank=True)
    requester_phone = models.CharField(max_length=30, blank=True)
    subject = models.CharField(max_length=255)
    description = models.TextField()
    is_anonymous = models.BooleanField(default=False)
    status = models.CharField(
        max_length=20,
        choices=RequestStatus.choices,
        default=RequestStatus.PENDING,
    )
    assigned_to = models.ForeignKey(
        CustomUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_prayer_requests',
    )
    notes = models.TextField(blank=True, help_text='Notas internas para el pastor/líder')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        name = 'Anónimo' if self.is_anonymous else self.requester_name
        return f'[{self.status}] {self.subject} — {name}'


class VisitorRequest(models.Model):
    full_name = models.CharField(max_length=150)
    email = models.EmailField(blank=True)
    phone = models.CharField(max_length=30, blank=True)
    age_range = models.CharField(
        max_length=20,
        choices=AgeRange.choices,
        default=AgeRange.PREFER_NOT_SAY,
    )
    how_did_you_find_us = models.CharField(
        max_length=30,
        choices=HowFound.choices,
        default=HowFound.OTHER,
    )
    message = models.TextField(blank=True)
    preferred_contact = models.CharField(
        max_length=20,
        choices=PreferredContact.choices,
        default=PreferredContact.WHATSAPP,
    )
    status = models.CharField(
        max_length=20,
        choices=RequestStatus.choices,
        default=RequestStatus.PENDING,
    )
    user = models.ForeignKey(
        CustomUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='cell_requests',
    )
    cell_group = models.ForeignKey(
        'cells.CellGroup',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='visitor_requests',
    )
    assigned_to = models.ForeignKey(
        CustomUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_visitor_requests',
    )
    notes = models.TextField(blank=True, help_text='Notas internas del seguimiento')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.status}] Visitante: {self.full_name}'
