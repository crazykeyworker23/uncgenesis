from django.db import models
from django.conf import settings
from django.utils.text import slugify


class EventStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Borrador'
    PUBLISHED = 'PUBLISHED', 'Publicado'
    ARCHIVED = 'ARCHIVED', 'Archivado'
    CANCELLED = 'CANCELLED', 'Cancelado'


class Event(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, db_index=True, blank=True)
    description = models.TextField()
    cover_image = models.ImageField(upload_to='events/covers/', blank=True, null=True)
    start_date = models.DateTimeField(db_index=True)
    end_date = models.DateTimeField(db_index=True)
    location = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    capacity = models.PositiveIntegerField(null=True, blank=True, help_text="Dejar en blanco para aforo ilimitado")
    requires_registration = models.BooleanField(default=True, db_index=True)
    status = models.CharField(
        max_length=20,
        choices=EventStatus.choices,
        default=EventStatus.DRAFT,
        db_index=True
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'evento'
        verbose_name_plural = 'eventos'
        ordering = ['start_date', 'created_at']

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
            original_slug = self.slug
            queryset = Event.objects.all()
            if self.pk:
                queryset = queryset.exclude(pk=self.pk)
            count = 1
            while queryset.filter(slug=self.slug).exists():
                self.slug = f"{original_slug}-{count}"
                count += 1
        super().save(*args, **kwargs)

    def __str__(self):
        return self.title


class EventRegistrationStatus(models.TextChoices):
    CONFIRMED = 'CONFIRMED', 'Confirmado'
    CANCELLED = 'CANCELLED', 'Cancelado'
    ATTENDED = 'ATTENDED', 'Asistió'


class EventRegistration(models.Model):
    event = models.ForeignKey(
        Event,
        on_delete=models.CASCADE,
        related_name='registrations'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='event_registrations'
    )
    registered_at = models.DateTimeField(auto_now_add=True, db_index=True)
    status = models.CharField(
        max_length=20,
        choices=EventRegistrationStatus.choices,
        default=EventRegistrationStatus.CONFIRMED,
        db_index=True
    )

    class Meta:
        verbose_name = 'inscripción a evento'
        verbose_name_plural = 'inscripciones a eventos'
        unique_together = ('event', 'user')
        ordering = ['-registered_at']

    def __str__(self):
        return f"{self.user.email} -> {self.event.title} ({self.status})"
