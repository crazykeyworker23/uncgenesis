from django.db import models
from django.conf import settings
from django.utils.text import slugify


class DevotionalStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Borrador'
    PUBLISHED = 'PUBLISHED', 'Publicado'
    ARCHIVED = 'ARCHIVED', 'Archivado'


class Devotional(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, db_index=True, blank=True)
    date = models.DateField(unique=True, db_index=True)
    bible_passage = models.CharField(max_length=150)
    # El versículo transcrito. Opcional: en un plan de lecturas semanal se
    # indica el pasaje a leer —«Hebreos 13»— y la gente lo abre en su Biblia;
    # exigir el texto completo obligaba a copiar capítulos enteros para cargar
    # una semana.
    bible_text = models.TextField(blank=True, default='')
    content = models.TextField()
    audio_url = models.URLField(max_length=500, blank=True, null=True)
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='devotionals'
    )
    status = models.CharField(
        max_length=20,
        choices=DevotionalStatus.choices,
        default=DevotionalStatus.DRAFT,
        db_index=True
    )
    views_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'devocional'
        verbose_name_plural = 'devocionales'
        ordering = ['-date', '-created_at']

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
            original_slug = self.slug
            queryset = Devotional.objects.all()
            if self.pk:
                queryset = queryset.exclude(pk=self.pk)
            count = 1
            while queryset.filter(slug=self.slug).exists():
                self.slug = f"{original_slug}-{count}"
                count += 1
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.title} ({self.date})"
