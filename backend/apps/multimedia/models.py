import os
import mimetypes
from django.db import models
from django.conf import settings


class MediaType(models.TextChoices):
    IMAGE = 'IMAGE', 'Imagen'
    PDF = 'PDF', 'Documento PDF'
    AUDIO = 'AUDIO', 'Audio'
    VIDEO = 'VIDEO', 'Video'
    OTHER = 'OTHER', 'Otro'


class Multimedia(models.Model):
    title = models.CharField(max_length=255, db_index=True)
    file = models.FileField(upload_to='multimedia/')
    file_type = models.CharField(
        max_length=20,
        choices=MediaType.choices,
        default=MediaType.OTHER,
        db_index=True
    )
    file_size = models.IntegerField(help_text="Tamaño del archivo en bytes", blank=True, null=True)
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='uploaded_multimedia'
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Multimedia'
        verbose_name_plural = 'Biblioteca Multimedia'
        ordering = ['-created_at']

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        # Automatically set file size
        if self.file and not self.file_size:
            try:
                self.file_size = self.file.size
            except Exception:
                pass

        # Detect media type from filename
        if self.file and (self.file_type == MediaType.OTHER or not self.file_type):
            ext = os.path.splitext(self.file.name)[1].lower()
            mime_type, _ = mimetypes.guess_type(self.file.name)
            if mime_type:
                if mime_type.startswith('image/'):
                    self.file_type = MediaType.IMAGE
                elif mime_type.startswith('audio/'):
                    self.file_type = MediaType.AUDIO
                elif mime_type.startswith('video/'):
                    self.file_type = MediaType.VIDEO
                elif mime_type == 'application/pdf':
                    self.file_type = MediaType.PDF
                else:
                    self.file_type = MediaType.OTHER
            else:
                if ext in ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg']:
                    self.file_type = MediaType.IMAGE
                elif ext in ['.mp3', '.wav', '.ogg', '.m4a']:
                    self.file_type = MediaType.AUDIO
                elif ext in ['.mp4', '.avi', '.mov', '.mkv']:
                    self.file_type = MediaType.VIDEO
                elif ext == '.pdf':
                    self.file_type = MediaType.PDF
                else:
                    self.file_type = MediaType.OTHER

        super().save(*args, **kwargs)
