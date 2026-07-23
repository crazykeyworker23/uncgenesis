from django.db import models


class AppSettings(models.Model):
    app_name = models.CharField(max_length=100, default="Génesis App")
    app_description = models.TextField(blank=True)
    splash_text = models.CharField(max_length=255, default="Una casa para todos")
    logo = models.ImageField(upload_to='settings/', blank=True, null=True)
    primary_color = models.CharField(max_length=7, default="#032F2F") # Deep Teal
    secondary_color = models.CharField(max_length=7, default="#D4AF37") # Dorado
    privacy_policy_url = models.URLField(blank=True)
    terms_url = models.URLField(blank=True)

    class Meta:
        verbose_name = 'configuración de aplicación'
        verbose_name_plural = 'configuración de aplicación'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get_solo(cls):
        obj, created = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return self.app_name


class ChurchSettings(models.Model):
    church_name = models.CharField(max_length=150, default="Iglesia Génesis")
    address = models.CharField(max_length=255)
    city = models.CharField(max_length=100)
    country = models.CharField(max_length=100)
    phone = models.CharField(max_length=20, blank=True)
    whatsapp = models.CharField(max_length=20)
    email = models.EmailField()
    website = models.URLField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    class Meta:
        verbose_name = 'configuración de iglesia'
        verbose_name_plural = 'configuración de iglesia'

    def save(self, *args, **kwargs):
        self.pk = 1
        super().save(*args, **kwargs)

    @classmethod
    def get_solo(cls):
        obj, created = cls.objects.get_or_create(pk=1)
        return obj

    def __str__(self):
        return self.church_name


class ServiceSchedule(models.Model):
    DAYS_OF_WEEK = [
        ('MONDAY', 'Lunes'),
        ('TUESDAY', 'Martes'),
        ('WEDNESDAY', 'Miércoles'),
        ('THURSDAY', 'Jueves'),
        ('FRIDAY', 'Viernes'),
        ('SATURDAY', 'Sábado'),
        ('SUNDAY', 'Domingo'),
    ]

    day_of_week = models.CharField(max_length=15, choices=DAYS_OF_WEEK, db_index=True)
    start_time = models.TimeField()
    title = models.CharField(max_length=100)
    description = models.TextField(blank=True)

    class Meta:
        verbose_name = 'horario de servicio'
        verbose_name_plural = 'horarios de servicios'
        ordering = ['day_of_week', 'start_time']

    def __str__(self):
        return f"{self.get_day_of_week_display()} {self.start_time.strftime('%H:%M')} - {self.title}"


class SocialNetwork(models.Model):
    name = models.CharField(max_length=50) # Facebook, Instagram, YouTube, etc.
    url = models.URLField()
    icon_name = models.CharField(max_length=50, blank=True) # e.g. "facebook", "instagram"

    class Meta:
        verbose_name = 'red social'
        verbose_name_plural = 'redes sociales'

    def __str__(self):
        return self.name
