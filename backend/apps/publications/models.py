from django.db import models
from django.conf import settings
from django.utils.text import slugify


class PublicationContentType(models.TextChoices):
    NEWS = 'NEWS', 'Noticia'
    SERVICE = 'SERVICE', 'Servicio realizado'
    DEVOTIONAL = 'DEVOTIONAL', 'Devocional'
    EVENT = 'EVENT', 'Evento'
    YOUTH = 'YOUTH', 'Jóvenes'
    GENERAL = 'GENERAL', 'General'


class PublicationStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Borrador'
    SCHEDULED = 'SCHEDULED', 'Programado'
    PUBLISHED = 'PUBLISHED', 'Publicado'
    ARCHIVED = 'ARCHIVED', 'Archivado'


class PublicationCategory(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(max_length=120, unique=True, db_index=True, blank=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'categoría de publicación'
        verbose_name_plural = 'categorías de publicaciones'

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class PublicationTag(models.Model):
    name = models.CharField(max_length=50, unique=True)
    slug = models.SlugField(max_length=60, unique=True, db_index=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'etiqueta de publicación'
        verbose_name_plural = 'etiquetas de publicaciones'

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class Publication(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, db_index=True, blank=True)
    summary = models.TextField(blank=True)
    content = models.TextField()
    cover_image = models.ImageField(upload_to='publications/covers/', blank=True, null=True)
    category = models.ForeignKey(
        PublicationCategory,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='publications'
    )
    content_type = models.CharField(
        max_length=20,
        choices=PublicationContentType.choices,
        default=PublicationContentType.GENERAL,
        db_index=True
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='publications'
    )
    status = models.CharField(
        max_length=20,
        choices=PublicationStatus.choices,
        default=PublicationStatus.DRAFT,
        db_index=True
    )
    published_at = models.DateTimeField(null=True, blank=True, db_index=True)
    scheduled_at = models.DateTimeField(null=True, blank=True, db_index=True)
    is_featured = models.BooleanField(default=False, db_index=True)
    show_in_app = models.BooleanField(default=True, db_index=True)
    send_notification = models.BooleanField(default=False)
    views_count = models.PositiveIntegerField(default=0)
    seo_title = models.CharField(max_length=150, blank=True)
    seo_description = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    tags = models.ManyToManyField(PublicationTag, related_name='publications', blank=True)

    class Meta:
        verbose_name = 'publicación'
        verbose_name_plural = 'publicaciones'
        ordering = ['-published_at', '-created_at']

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
            original_slug = self.slug
            queryset = Publication.objects.all()
            if self.pk:
                queryset = queryset.exclude(pk=self.pk)
            count = 1
            while queryset.filter(slug=self.slug).exists():
                self.slug = f"{original_slug}-{count}"
                count += 1
        super().save(*args, **kwargs)

    def __str__(self):
        return self.title


class PublicationGallery(models.Model):
    publication = models.ForeignKey(
        Publication,
        on_delete=models.CASCADE,
        related_name='gallery_images'
    )
    image = models.ImageField(upload_to='publications/gallery/')
    order = models.PositiveIntegerField(default=0)
    caption = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'imagen de galería'
        verbose_name_plural = 'imágenes de galería'
        ordering = ['order', 'created_at']

    def __str__(self):
        return f"Imagen {self.id} de {self.publication.title}"
