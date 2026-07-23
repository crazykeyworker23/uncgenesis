from django.db import models
from django.utils.text import slugify


class ServiceStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Borrador'
    PUBLISHED = 'PUBLISHED', 'Publicado'
    ARCHIVED = 'ARCHIVED', 'Archivado'


class ChurchService(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, db_index=True, blank=True)
    date = models.DateField(db_index=True)
    video_url = models.URLField(max_length=500, blank=True, null=True)
    audio_url = models.URLField(max_length=500, blank=True, null=True)
    sermon_notes = models.TextField(blank=True)
    views_count = models.PositiveIntegerField(default=0)
    is_live = models.BooleanField(default=False, db_index=True)
    status = models.CharField(
        max_length=20,
        choices=ServiceStatus.choices,
        default=ServiceStatus.DRAFT,
        db_index=True
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'servicio religioso'
        verbose_name_plural = 'servicios religiosos'
        ordering = ['-date', '-created_at']

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
            original_slug = self.slug
            queryset = ChurchService.objects.all()
            if self.pk:
                queryset = queryset.exclude(pk=self.pk)
            count = 1
            while queryset.filter(slug=self.slug).exists():
                self.slug = f"{original_slug}-{count}"
                count += 1
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.title} ({self.date})"


class ServiceVerse(models.Model):
    service = models.ForeignKey(
        ChurchService,
        on_delete=models.CASCADE,
        related_name='verses'
    )
    book = models.CharField(max_length=100)
    chapter = models.PositiveIntegerField()
    verses = models.CharField(max_length=50, help_text="ej. 1-5 o 12")
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'versículo del servicio'
        verbose_name_plural = 'versículos del servicio'

    def __str__(self):
        return f"{self.book} {self.chapter}:{self.verses}"
