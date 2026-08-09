from django.utils import timezone
from rest_framework import viewsets, filters, permissions, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from apps.roles.permissions import HasAppPermission
from apps.roles.scope import (
    can_manage_cell,
    can_reach_cell,
    describe_scope,
    get_accessible_cell_ids,
)
from apps.roles.utils import has_any_permission, is_superadmin
from .models import CellGroup
from .serializers import (
    CellGroupSerializer,
    CellMemberSerializer,
    CellReminderSerializer,
)
from .views_management import CellManagementMixin

PERM_MAP = {
    'list':    'CELLS_VIEW',
    'retrieve':'CELLS_VIEW',
    'create':  'CELLS_CREATE',
    'update':  'CELLS_EDIT',
    'partial_update': 'CELLS_EDIT',
    'destroy': 'CELLS_DELETE',
}

class CellGroupViewSet(CellManagementMixin, viewsets.ModelViewSet):
    queryset = CellGroup.objects.select_related('leader').all()
    serializer_class = CellGroupSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'meeting_day', 'leader']
    search_fields = ['name', 'address', 'leader__first_name', 'leader__last_name']
    ordering_fields = ['name', 'created_at', 'meeting_day']
    ordering = ['name']

    # Permisos que identifican a quien administra células a nivel de iglesia,
    # frente al líder que sólo gestiona la suya.
    MANAGE_PERMISSIONS = ['CELLS_CREATE', 'CELLS_EDIT', 'CELLS_DELETE']

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        # Las acciones del líder se autorizan por pertenencia (ser el líder de
        # esa célula), no por un permiso global del catálogo.
        if self.action in ['my_cells', 'members', 'send_reminder', 'statistics',
                           'attendance_history', 'register_member']:
            return [IsAuthenticated()]
        return [IsAuthenticated(), HasAppPermission()]

    def _can_manage_any_cell(self, user):
        return is_superadmin(user) or has_any_permission(user, self.MANAGE_PERMISSIONS)

    def update(self, request, *args, **kwargs):
        return self._guarded_write(request, super().update, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        return self._guarded_write(request, super().partial_update, *args, **kwargs)

    def _guarded_write(self, request, handler, *args, **kwargs):
        """
        Cada quien edita dentro de su alcance: el líder su célula, el
        coordinador las que supervisa, el pastor todas.
        """
        cell = self.get_object()
        if not can_manage_cell(request.user, cell.id):
            return Response(
                {"error": "Sólo puedes editar las células que tienes a tu cargo."},
                status=status.HTTP_403_FORBIDDEN
            )
        return handler(request, *args, **kwargs)

    @action(detail=False, methods=['get'], url_path='my-cells')
    def my_cells(self, request):
        """
        Células dentro del alcance de la persona autenticada.

        El líder recibe la suya, el coordinador las que supervisa y el pastor
        todas las de la iglesia.
        """
        allowed = get_accessible_cell_ids(request.user)
        cells = self.get_queryset() if allowed is None else self.get_queryset().filter(id__in=allowed)

        return Response({
            'scope': describe_scope(request.user),
            'results': self.get_serializer(cells, many=True).data,
        })

    @action(detail=True, methods=['get'])
    def members(self, request, pk=None):
        """
        Personas asignadas a la célula.

        Visible dentro del alcance: su líder, su coordinador y el pastorado.
        """
        cell = self.get_object()

        if not can_reach_cell(request.user, cell.id):
            return Response(
                {"error": "Sólo puedes ver los miembros de las células que tienes a tu cargo."},
                status=status.HTTP_403_FORBIDDEN
            )

        members = cell.members.all().order_by('first_name', 'email')
        serializer = CellMemberSerializer(members, many=True, context=self.get_serializer_context())
        return Response({
            'cell': {'id': cell.id, 'name': cell.name, 'slug': cell.slug},
            'count': members.count(),
            'results': serializer.data,
        })

    @action(detail=True, methods=['post'], url_path='send-reminder')
    def send_reminder(self, request, pk=None):
        """
        Envía un recordatorio a los miembros de la célula.

        El líder no necesita el permiso global de notificaciones: el alcance
        queda acotado a su propia célula mediante la audiencia CELL.
        """
        from apps.notifications.models import (
            Notification,
            NotificationStatus,
            TargetAudience,
        )
        from apps.notifications.tasks import send_push_notification_task

        cell = self.get_object()

        if not can_manage_cell(request.user, cell.id):
            return Response(
                {"error": "Sólo puedes enviar recordatorios a las células que tienes a tu cargo."},
                status=status.HTTP_403_FORBIDDEN
            )

        if not cell.members.exists():
            return Response(
                {"error": "Esta célula todavía no tiene miembros asignados."},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = CellReminderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        title = (serializer.validated_data.get('title') or '').strip()
        if not title:
            title = f"Recordatorio de {cell.name}"

        scheduled = serializer.validated_data.get('scheduled_for')
        is_immediate = not scheduled or scheduled <= timezone.now()

        notification = Notification.objects.create(
            title=title,
            body=serializer.validated_data['body'],
            sender=request.user,
            target_audience=TargetAudience.CELL,
            target_cell=cell,
            # Tocar el recordatorio abre la ficha de la célula.
            deep_link=f'/cells/{cell.id}',
            scheduled_for=scheduled,
            status=NotificationStatus.SENT if is_immediate else NotificationStatus.PENDING,
            sent_at=timezone.now() if is_immediate else None,
        )

        if is_immediate:
            from apps.notifications.push import dispatch
            dispatch(notification)
        else:
            try:
                send_push_notification_task.apply_async((notification.id,), eta=scheduled)
            except Exception:
                # Si el broker no está disponible, la notificación queda
                # pendiente y se puede enviar manualmente desde el panel.
                pass

        return Response(
            {
                'id': notification.id,
                'title': notification.title,
                'body': notification.body,
                'status': notification.status,
                'scheduled_for': notification.scheduled_for,
                'recipients': cell.members.count(),
                'detail': (
                    f"Recordatorio enviado a {cell.members.count()} miembro(s) de {cell.name}."
                    if is_immediate
                    else f"Recordatorio programado para {cell.members.count()} miembro(s) de {cell.name}."
                ),
            },
            status=status.HTTP_201_CREATED
        )

    def get_object(self):
        queryset = self.filter_queryset(self.get_queryset())
        lookup_url_kwarg = self.lookup_url_kwarg or self.lookup_field or 'pk'
        lookup_value = self.kwargs[lookup_url_kwarg]
        
        if lookup_value.isdigit():
            try:
                obj = queryset.get(pk=lookup_value)
                self.check_object_permissions(self.request, obj)
                return obj
            except (queryset.model.DoesNotExist, ValueError):
                pass
                
        try:
            obj = queryset.get(slug=lookup_value)
            self.check_object_permissions(self.request, obj)
            return obj
        except queryset.model.DoesNotExist:
            from django.http import Http404
            raise Http404("No se encontró la célula.")

    def get_required_permission(self):
        return PERM_MAP.get(self.action, 'CELLS_VIEW')

    def check_permissions(self, request):
        if self.action in ['list', 'retrieve']:
            return

        # Editar la célula propia se autoriza por responsabilidad, no por el
        # permiso global CELLS_EDIT, que corresponde a quien administra todas.
        if self.action in ['update', 'partial_update'] and self._manages_target_cell(request.user):
            if not request.user or not request.user.is_authenticated:
                self.permission_denied(request)
            return

        self.required_permission = self.get_required_permission()
        super().check_permissions(request)

    def _manages_target_cell(self, user):
        """Resuelve la célula de la URL y comprueba si el usuario la gestiona."""
        if not user or not user.is_authenticated:
            return False

        lookup_value = self.kwargs.get(self.lookup_url_kwarg or self.lookup_field or 'pk')
        if not lookup_value:
            return False

        cell = CellGroup.objects.filter(pk=lookup_value).first() if str(lookup_value).isdigit() else None
        if cell is None:
            cell = CellGroup.objects.filter(slug=lookup_value).first()

        return bool(cell and can_manage_cell(user, cell.id))
