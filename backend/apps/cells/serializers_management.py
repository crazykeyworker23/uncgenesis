"""Serializers de la gestión interna de células: reuniones, asistencia y seguimiento."""

from django.contrib.auth import get_user_model
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .models import (
    Attendance,
    AttendanceStatus,
    CellGroup,
    CellMeeting,
    CellReport,
    MemberFollowUp,
)

User = get_user_model()


class PersonBriefSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'full_name', 'phone', 'status']

    def get_full_name(self, obj):
        full = f"{obj.first_name} {obj.last_name}".strip()
        return full or obj.email


class AttendanceSerializer(serializers.ModelSerializer):
    member = PersonBriefSerializer(read_only=True)
    member_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), source='member', write_only=True
    )
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Attendance
        fields = [
            'id', 'meeting', 'member', 'member_id',
            'status', 'status_display', 'notes', 'updated_at',
        ]
        read_only_fields = ['id', 'meeting', 'updated_at']


class CellMeetingSerializer(serializers.ModelSerializer):
    attendances = AttendanceSerializer(many=True, read_only=True)
    attendees_count = serializers.IntegerField(read_only=True)
    cell_name = serializers.CharField(source='cell.name', read_only=True)
    registered_by = PersonBriefSerializer(read_only=True)

    class Meta:
        model = CellMeeting
        fields = [
            'id', 'cell', 'cell_name', 'date', 'time', 'topic', 'notes',
            'guests_count', 'attendees_count', 'attendances',
            'registered_by', 'created_at',
        ]
        read_only_fields = ['id', 'cell_name', 'attendees_count', 'registered_by', 'created_at']

    def validate(self, attrs):
        """
        Una célula no puede tener dos reuniones el mismo día.

        La base de datos ya lo impide, pero sin esta comprobación el conflicto
        salía como error 500 en lugar de un mensaje que el líder pueda
        entender y corregir.
        """
        cell = attrs.get('cell') or getattr(self.instance, 'cell', None)
        date = attrs.get('date') or getattr(self.instance, 'date', None)

        if cell and date:
            duplicates = CellMeeting.objects.filter(cell=cell, date=date)
            if self.instance is not None:
                duplicates = duplicates.exclude(pk=self.instance.pk)
            if duplicates.exists():
                raise serializers.ValidationError({
                    'date': 'Ya existe una reunión registrada para esta célula en esa fecha.'
                })

        return attrs


class AttendanceBulkItemSerializer(serializers.Serializer):
    member_id = serializers.IntegerField()
    status = serializers.ChoiceField(choices=AttendanceStatus.choices)
    notes = serializers.CharField(required=False, allow_blank=True, max_length=255)


class AttendanceBulkSerializer(serializers.Serializer):
    """
    Registro de asistencia de una reunión completa en una sola operación.

    Pasar lista miembro por miembro generaría una petición por persona; así el
    líder guarda toda la reunión de una vez.
    """

    attendances = AttendanceBulkItemSerializer(many=True)


class MemberFollowUpSerializer(serializers.ModelSerializer):
    member = PersonBriefSerializer(read_only=True)
    member_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), source='member', write_only=True
    )
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    registered_by = PersonBriefSerializer(read_only=True)
    cell_name = serializers.CharField(source='cell.name', read_only=True)

    class Meta:
        model = MemberFollowUp
        fields = [
            'id', 'cell', 'cell_name', 'member', 'member_id',
            'type', 'type_display', 'date', 'summary', 'needs_attention',
            'registered_by', 'created_at',
        ]
        read_only_fields = ['id', 'cell_name', 'registered_by', 'created_at']


class CellMemberRegistrationSerializer(serializers.Serializer):
    """
    Alta de un integrante o visitante desde la célula.

    No abre la administración de cuentas: crea la persona ya asignada a la
    célula indicada y sin ningún rol administrativo.
    """

    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    email = serializers.EmailField(required=False, allow_blank=True)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    location = serializers.CharField(max_length=255, required=False, allow_blank=True)

    def validate_email(self, value):
        if value and User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('Ya existe una cuenta con ese correo.')
        return value


class CellStatisticsSerializer(serializers.Serializer):
    """Indicadores de una célula, para el líder y su coordinador."""

    cell = serializers.DictField()
    members_total = serializers.IntegerField()
    members_active = serializers.IntegerField()
    members_inactive = serializers.IntegerField()
    meetings_total = serializers.IntegerField()
    average_attendance = serializers.FloatField()
    attendance_by_status = serializers.DictField()
    attendance_trend = serializers.ListField()
    needs_attention = serializers.IntegerField()


class CellReportSerializer(serializers.ModelSerializer):
    """Informe de actividad que el líder envía sobre su célula."""

    cell_name = serializers.CharField(source='cell.name', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    submitted_by = PersonBriefSerializer(read_only=True)
    reviewed_by = PersonBriefSerializer(read_only=True)
    photo_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = CellReport
        fields = [
            'id', 'cell', 'cell_name',
            'period_start', 'period_end',
            'summary', 'highlights', 'challenges', 'prayer_needs',
            'photo', 'photo_url', 'photo_caption',
            'meetings_held', 'average_attendance', 'new_members',
            'status', 'status_display',
            'submitted_by', 'sent_at',
            'reviewed_by', 'reviewed_at', 'review_notes',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'cell_name', 'status', 'status_display', 'photo_url',
            'meetings_held', 'average_attendance', 'new_members',
            'submitted_by', 'sent_at',
            'reviewed_by', 'reviewed_at', 'review_notes',
            'created_at', 'updated_at',
        ]
        extra_kwargs = {
            # La imagen se devuelve resuelta en photo_url; este campo es sólo
            # para subirla.
            'photo': {'write_only': True, 'required': False, 'allow_null': True},
        }

    @extend_schema_field(serializers.CharField(allow_null=True))
    def get_photo_url(self, obj):
        """Dirección completa de la foto, para que el panel pueda mostrarla."""
        if not obj.photo:
            return None
        request = self.context.get('request')
        return request.build_absolute_uri(obj.photo.url) if request else obj.photo.url

    def validate(self, attrs):
        start = attrs.get('period_start') or getattr(self.instance, 'period_start', None)
        end = attrs.get('period_end') or getattr(self.instance, 'period_end', None)

        if start and end and start > end:
            raise serializers.ValidationError({
                'period_end': 'La fecha final del periodo no puede ser anterior a la inicial.'
            })
        return attrs


class CellReportReviewSerializer(serializers.Serializer):
    """Respuesta del coordinador o del pastorado a un informe recibido."""

    review_notes = serializers.CharField(required=False, allow_blank=True)
