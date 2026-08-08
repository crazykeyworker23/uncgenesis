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
    # El coordinador supervisa varias células: es el nivel intermedio entre el
    # pastor, que ve toda la iglesia, y el líder, que sólo ve la suya.
    coordinator = models.ForeignKey(
        CustomUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='coordinated_cells'
    )
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


class AttendanceStatus(models.TextChoices):
    PRESENT = 'PRESENT', 'Asistió'
    ABSENT = 'ABSENT', 'No asistió'
    LATE = 'LATE', 'Tardanza'
    EXCUSED = 'EXCUSED', 'Justificado'


class CellMeeting(models.Model):
    """Reunión realizada por una célula."""

    cell = models.ForeignKey(CellGroup, on_delete=models.CASCADE, related_name='meetings')
    date = models.DateField(db_index=True)
    time = models.TimeField(null=True, blank=True)
    topic = models.CharField(max_length=255, blank=True)
    notes = models.TextField(blank=True, verbose_name='observaciones')
    # Permite anotar visitantes que no están registrados como miembros.
    guests_count = models.PositiveIntegerField(default=0)
    registered_by = models.ForeignKey(
        CustomUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='registered_meetings'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-time']
        verbose_name = 'reunión de célula'
        verbose_name_plural = 'reuniones de célula'
        constraints = [
            models.UniqueConstraint(fields=['cell', 'date'], name='unique_meeting_per_cell_and_date')
        ]

    def __str__(self):
        return f"{self.cell.name} - {self.date}"

    @property
    def attendees_count(self):
        """Cuántos asistieron realmente, contando las tardanzas."""
        return self.attendances.filter(
            status__in=[AttendanceStatus.PRESENT, AttendanceStatus.LATE]
        ).count() + self.guests_count


class Attendance(models.Model):
    """Asistencia de una persona a una reunión concreta."""

    meeting = models.ForeignKey(CellMeeting, on_delete=models.CASCADE, related_name='attendances')
    member = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='attendances')
    status = models.CharField(
        max_length=20,
        choices=AttendanceStatus.choices,
        default=AttendanceStatus.PRESENT,
        db_index=True
    )
    notes = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['member__first_name', 'member__email']
        verbose_name = 'asistencia'
        verbose_name_plural = 'asistencias'
        constraints = [
            models.UniqueConstraint(fields=['meeting', 'member'], name='unique_attendance_per_meeting')
        ]

    def __str__(self):
        return f"{self.member.email} - {self.get_status_display()}"


class FollowUpType(models.TextChoices):
    CALL = 'CALL', 'Llamada'
    VISIT = 'VISIT', 'Visita'
    MESSAGE = 'MESSAGE', 'Mensaje'
    OTHER = 'OTHER', 'Otro'


class MemberFollowUp(models.Model):
    """
    Seguimiento pastoral de un miembro dentro de su célula.

    Deja constancia de los contactos y visitas realizadas, y permite marcar a
    quien necesita atención especial.
    """

    cell = models.ForeignKey(CellGroup, on_delete=models.CASCADE, related_name='follow_ups')
    member = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='follow_ups')
    type = models.CharField(max_length=20, choices=FollowUpType.choices, default=FollowUpType.CALL)
    date = models.DateField(db_index=True)
    summary = models.TextField()
    needs_attention = models.BooleanField(
        default=False,
        help_text='Marca a quien requiere seguimiento cercano.'
    )
    registered_by = models.ForeignKey(
        CustomUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='registered_follow_ups'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-created_at']
        verbose_name = 'seguimiento de miembro'
        verbose_name_plural = 'seguimientos de miembros'

    def __str__(self):
        return f"{self.member.email} - {self.get_type_display()} ({self.date})"


class CellReportStatus(models.TextChoices):
    DRAFT = 'DRAFT', 'Borrador'
    SENT = 'SENT', 'Enviado'
    REVIEWED = 'REVIEWED', 'Revisado'


class CellReport(models.Model):
    """
    Informe de actividad que el líder envía sobre su célula.

    Cierra el ciclo de supervisión: el líder cuenta cómo le fue en el periodo,
    y su coordinador —o el pastorado— lo lee y responde. Junto al texto se
    guarda una foto de las cifras del periodo, para que el informe siga siendo
    fiel aunque los datos cambien después.
    """

    cell = models.ForeignKey(CellGroup, on_delete=models.CASCADE, related_name='reports')
    period_start = models.DateField()
    period_end = models.DateField()

    summary = models.TextField(verbose_name='cómo le fue a la célula')
    highlights = models.TextField(blank=True, verbose_name='lo más destacado')
    challenges = models.TextField(blank=True, verbose_name='dificultades')
    prayer_needs = models.TextField(blank=True, verbose_name='motivos de oración')

    # Una foto de la actividad: al coordinador le dice más de la reunión que
    # cualquier resumen escrito.
    photo = models.ImageField(upload_to='cell_reports/', blank=True, null=True)
    photo_caption = models.CharField(max_length=255, blank=True, verbose_name='pie de foto')

    # Cifras del periodo, congeladas al enviar el informe.
    meetings_held = models.PositiveIntegerField(default=0)
    average_attendance = models.FloatField(default=0)
    new_members = models.PositiveIntegerField(default=0)

    status = models.CharField(
        max_length=20,
        choices=CellReportStatus.choices,
        default=CellReportStatus.DRAFT,
        db_index=True
    )
    submitted_by = models.ForeignKey(
        CustomUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='submitted_cell_reports'
    )
    sent_at = models.DateTimeField(null=True, blank=True)

    reviewed_by = models.ForeignKey(
        CustomUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_cell_reports'
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    review_notes = models.TextField(blank=True, verbose_name='respuesta del coordinador')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-period_end', '-created_at']
        verbose_name = 'informe de célula'
        verbose_name_plural = 'informes de célula'

    def __str__(self):
        return f"{self.cell.name} · {self.period_start} a {self.period_end}"
