from django.db import models
from django.utils.text import slugify
from apps.users.models import CustomUser

class MeetingDay(models.TextChoices):
    MONDAY = 'MONDAY', 'Lunes'
    TUESDAY = 'TUESDAY', 'Martes'
    WEDNESDAY = 'WEDNESDAY', 'Miércoles'
    THURSDAY = 'THURSDAY', 'Jueves'
    FRIDAY = 'FRIDAY', 'Viernes'
    SATURDAY = 'SATURDAY', 'Sábado'
    SUNDAY = 'SUNDAY', 'Domingo'

class CellStatus(models.TextChoices):
    ACTIVE = 'ACTIVE', 'Activo'
    INACTIVE = 'INACTIVE', 'Inactivo'

class CellGroup(models.Model):
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, blank=True)
    leader = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, related_name='led_cells')
    meeting_day = models.CharField(max_length=20, choices=MeetingDay.choices)
    meeting_time = models.TimeField()
    address = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=CellStatus.choices, default=CellStatus.ACTIVE)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            base_slug = slugify(self.name)
            slug = base_slug
            counter = 1
            while CellGroup.objects.filter(slug=slug).exists():
                slug = f"{base_slug}-{counter}"
                counter += 1
            self.slug = slug
        super().save(*args, **kwargs)
