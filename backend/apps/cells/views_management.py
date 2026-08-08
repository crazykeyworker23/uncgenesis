"""
Gestión interna de la célula: reuniones, asistencia, seguimiento y estadísticas.

Cada endpoint filtra por el alcance del usuario (apps/roles/scope.py), de modo
que un líder sólo alcanza su célula, un coordinador las que tiene asignadas y
el pastor toda la iglesia. Escribir la URL de una célula ajena devuelve 404 o
403, nunca sus datos.
"""

from django.contrib.auth import get_user_model
from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.roles.permissions import HasAppPermission
from apps.roles.scope import (
    can_manage_cell,
    can_reach_cell,
    filter_cell_queryset,
)

from .models import (
    Attendance,
    AttendanceStatus,
    CellGroup,
    CellMeeting,
    MemberFollowUp,
)
from .serializers_management import (
    AttendanceBulkSerializer,
    AttendanceSerializer,
    CellMeetingSerializer,
    CellMemberRegistrationSerializer,
    MemberFollowUpSerializer,
)

User = get_user_model()


class ScopedCellResourceMixin:
    """Comportamiento común de los recursos que cuelgan de una célula."""

    #: Ruta desde el modelo hasta la célula, para el filtrado por alcance.
    cell_path = 'cell_id'
    #: Permiso por acción.
    perm_map = {}

    permission_classes = [IsAuthenticated, HasAppPermission]

    def get_required_permission(self):
        return self.perm_map.get(self.action)

    def check_permissions(self, request):
        self.required_permission = self.get_required_permission()
        super().check_permissions(request)

    def get_queryset(self):
        return filter_cell_queryset(self.queryset, self.request.user, field=self.cell_path)

    def _resolve_cell_id(self, serializer):
        raise NotImplementedError

    def _deny_out_of_scope(self):
        return Response(
            {"error": "No puedes registrar información en una célula que no tienes a tu cargo."},
            status=status.HTTP_403_FORBIDDEN,
        )


class CellMeetingViewSet(ScopedCellResourceMixin, viewsets.ModelViewSet):
    """Reuniones realizadas por la célula."""

    queryset = CellMeeting.objects.select_related('cell', 'registered_by').prefetch_related(
        'attendances__member'
    )
    serializer_class = CellMeetingSerializer
    filterset_fields = ['cell', 'date']
    ordering = ['-date']

    perm_map = {
        'list': 'MEETINGS_VIEW',
        'retrieve': 'MEETINGS_VIEW',
        'create': 'MEETINGS_CREATE',
        'update': 'MEETINGS_EDIT',
        'partial_update': 'MEETINGS_EDIT',
        'destroy': 'MEETINGS_DELETE',
        'attendance': 'ATTENDANCE_EDIT',
    }

    def create(self, request, *args, **kwargs):
        cell_id = request.data.get('cell')
        if not can_manage_cell(request.user, int(cell_id) if cell_id else None):
            return self._deny_out_of_scope()
        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        serializer.save(registered_by=self.request.user)

    def update(self, request, *args, **kwargs):
        if not can_manage_cell(request.user, self.get_object().cell_id):
            return self._deny_out_of_scope()
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if not can_manage_cell(request.user, self.get_object().cell_id):
            return self._deny_out_of_scope()
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if not can_manage_cell(request.user, self.get_object().cell_id):
            return self._deny_out_of_scope()
        return super().destroy(request, *args, **kwargs)

    @action(detail=True, methods=['post'])
    def attendance(self, request, pk=None):
        """
        Registra la asistencia de toda la reunión.

        Acepta los cuatro estados del sistema: asistió, no asistió, tardanza y
        justificado. Sólo admite personas que pertenezcan a esa célula.
        """
        meeting = self.get_object()

        if not can_manage_cell(request.user, meeting.cell_id):
            return self._deny_out_of_scope()

        serializer = AttendanceBulkSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        member_ids = set(meeting.cell.members.values_list('id', flat=True))
        saved, rejected = [], []

        for item in serializer.validated_data['attendances']:
            if item['member_id'] not in member_ids:
                rejected.append(item['member_id'])
                continue
            attendance, _ = Attendance.objects.update_or_create(
                meeting=meeting,
                member_id=item['member_id'],
                defaults={
                    'status': item['status'],
                    'notes': item.get('notes', ''),
                },
            )
            saved.append(attendance)

        payload = {
            'meeting': meeting.id,
            'saved': AttendanceSerializer(saved, many=True).data,
            'attendees_count': meeting.attendees_count,
        }
        if rejected:
            payload['rejected'] = rejected
            payload['detail'] = 'Se ignoraron personas que no pertenecen a esta célula.'

        return Response(payload, status=status.HTTP_200_OK)


class MemberFollowUpViewSet(ScopedCellResourceMixin, viewsets.ModelViewSet):
    """Contactos, visitas y seguimiento pastoral dentro de la célula."""

    queryset = MemberFollowUp.objects.select_related('cell', 'member', 'registered_by')
    serializer_class = MemberFollowUpSerializer
    filterset_fields = ['cell', 'member', 'type', 'needs_attention']
    ordering = ['-date']

    perm_map = {
        'list': 'FOLLOWUPS_VIEW',
        'retrieve': 'FOLLOWUPS_VIEW',
        'create': 'FOLLOWUPS_CREATE',
        'update': 'FOLLOWUPS_EDIT',
        'partial_update': 'FOLLOWUPS_EDIT',
        'destroy': 'FOLLOWUPS_EDIT',
    }

    def create(self, request, *args, **kwargs):
        cell_id = request.data.get('cell')
        if not can_manage_cell(request.user, int(cell_id) if cell_id else None):
            return self._deny_out_of_scope()
        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        serializer.save(registered_by=self.request.user)

    def update(self, request, *args, **kwargs):
        if not can_manage_cell(request.user, self.get_object().cell_id):
            return self._deny_out_of_scope()
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        if not can_manage_cell(request.user, self.get_object().cell_id):
            return self._deny_out_of_scope()
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        if not can_manage_cell(request.user, self.get_object().cell_id):
            return self._deny_out_of_scope()
        return super().destroy(request, *args, **kwargs)


def build_cell_statistics(cell):
    """Indicadores de una célula: composición, asistencia y seguimiento."""
    members = cell.members.all()
    members_total = members.count()
    members_active = members.filter(status='ACTIVE').count()

    meetings = cell.meetings.all()
    meetings_total = meetings.count()

    attendance_counts = {
        row['status']: row['total']
        for row in Attendance.objects.filter(meeting__cell=cell)
        .values('status')
        .annotate(total=Count('id'))
    }
    attendance_by_status = {
        choice.value: attendance_counts.get(choice.value, 0)
        for choice in AttendanceStatus
    }

    present = attendance_by_status[AttendanceStatus.PRESENT] + attendance_by_status[AttendanceStatus.LATE]
    average_attendance = round(present / meetings_total, 1) if meetings_total else 0.0

    # Evolución: asistentes de las últimas ocho reuniones, de más antigua a más
    # reciente, para que el panel dibuje la tendencia sin recalcular nada.
    trend = [
        {
            'date': meeting.date.isoformat(),
            'attendees': meeting.attendees_count,
            'topic': meeting.topic,
        }
        for meeting in meetings.order_by('-date')[:8][::-1]
    ]

    return {
        'cell': {'id': cell.id, 'name': cell.name, 'slug': cell.slug},
        'members_total': members_total,
        'members_active': members_active,
        'members_inactive': members_total - members_active,
        'meetings_total': meetings_total,
        'average_attendance': average_attendance,
        'attendance_by_status': attendance_by_status,
        'attendance_trend': trend,
        'needs_attention': cell.follow_ups.filter(needs_attention=True)
        .values('member_id')
        .distinct()
        .count(),
    }


class CellManagementMixin:
    """
    Acciones que se añaden al viewset de células.

    Se mantienen aquí para que `apps/cells/views.py` no crezca sin control.
    """

    @action(detail=True, methods=['get'])
    def statistics(self, request, pk=None):
        """Estadísticas de la célula: miembros, asistencia y seguimiento."""
        cell = self.get_object()

        if not can_reach_cell(request.user, cell.id):
            return Response(
                {"error": "No puedes consultar las estadísticas de esta célula."},
                status=status.HTTP_403_FORBIDDEN,
            )

        return Response(build_cell_statistics(cell))

    @action(detail=True, methods=['get'], url_path='attendance-history')
    def attendance_history(self, request, pk=None):
        """Historial de asistencia de la célula, reunión por reunión."""
        cell = self.get_object()

        if not can_reach_cell(request.user, cell.id):
            return Response(
                {"error": "No puedes consultar el historial de esta célula."},
                status=status.HTTP_403_FORBIDDEN,
            )

        member_id = request.query_params.get('member')
        attendances = Attendance.objects.filter(meeting__cell=cell).select_related(
            'meeting', 'member'
        )
        if member_id:
            attendances = attendances.filter(member_id=member_id)

        return Response({
            'cell': {'id': cell.id, 'name': cell.name},
            'results': [
                {
                    'meeting_id': a.meeting_id,
                    'date': a.meeting.date.isoformat(),
                    'topic': a.meeting.topic,
                    'member_id': a.member_id,
                    'member_name': f"{a.member.first_name} {a.member.last_name}".strip() or a.member.email,
                    'status': a.status,
                    'status_display': a.get_status_display(),
                    'notes': a.notes,
                }
                for a in attendances.order_by('-meeting__date')
            ],
        })

    @action(detail=True, methods=['post'], url_path='register-member')
    def register_member(self, request, pk=None):
        """
        Da de alta a un integrante o visitante en la célula.

        Crea la persona ya asignada al grupo y sin rol administrativo: el líder
        suma gente a su célula sin tocar la administración de cuentas.
        """
        cell = self.get_object()

        if not can_manage_cell(request.user, cell.id):
            return Response(
                {"error": "Sólo puedes registrar integrantes en la célula que tienes a tu cargo."},
                status=status.HTTP_403_FORBIDDEN,
            )

        from apps.roles.permissions import HasAppPermission as _HasAppPermission
        from apps.roles.utils import has_any_permission

        if not has_any_permission(request.user, ['MEMBERS_REGISTER']):
            return Response(
                {"error": "Tu rol no puede dar de alta integrantes."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = CellMemberRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        email = (data.get('email') or '').strip()
        if not email:
            # Un visitante puede no tener correo: se genera uno interno para
            # cumplir con la identidad única del sistema.
            stamp = timezone.now().strftime('%Y%m%d%H%M%S%f')
            email = f'visitante.{cell.slug}.{stamp}@genesis.local'

        person = User.objects.create_user(
            email=email,
            first_name=data['first_name'],
            last_name=data.get('last_name', ''),
            phone=data.get('phone', ''),
            location=data.get('location', ''),
        )
        person.assigned_cell = cell
        person.save(update_fields=['assigned_cell'])

        from apps.roles.models import Role, RoleType, UserRole

        member_role = Role.objects.filter(name=RoleType.MEMBER).first()
        if member_role:
            UserRole.objects.get_or_create(user=person, role=member_role)

        return Response(
            {
                'id': person.id,
                'email': person.email,
                'full_name': f"{person.first_name} {person.last_name}".strip(),
                'cell': {'id': cell.id, 'name': cell.name},
                'detail': f'{person.first_name} quedó registrado en {cell.name}.',
            },
            status=status.HTTP_201_CREATED,
        )
