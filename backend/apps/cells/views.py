from django.utils import timezone
from rest_framework import viewsets, filters, permissions, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from apps.roles.permissions import HasAppPermission
from apps.roles.utils import has_any_permission, is_superadmin
from .models import CellGroup
from .serializers import (
    CellGroupSerializer,
    CellMemberSerializer,
    CellReminderSerializer,
)

PERM_MAP = {
    'list':    'CELLS_VIEW',
    'retrieve':'CELLS_VIEW',
    'create':  'CELLS_CREATE',
    'update':  'CELLS_EDIT',
    'partial_update': 'CELLS_EDIT',
    'destroy': 'CELLS_DELETE',
}

class CellGroupViewSet(viewsets.ModelViewSet):
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
        if self.action in ['my_cells', 'members', 'send_reminder']:
            return [IsAuthenticated()]
        return [IsAuthenticated(), HasAppPermission()]

    def _leads(self, cell, user):
        """`True` si el usuario es el líder de esa célula."""
        return bool(cell.leader_id) and cell.leader_id == getattr(user, 'id', None)

    def _can_manage_any_cell(self, user):
        return is_superadmin(user) or has_any_permission(user, self.MANAGE_PERMISSIONS)

    def update(self, request, *args, **kwargs):
        return self._guarded_write(request, super().update, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        return self._guarded_write(request, super().partial_update, *args, **kwargs)

    def _guarded_write(self, request, handler, *args, **kwargs):
        """
        Un líder puede editar la célula que tiene a cargo, pero no las ajenas.
        Quien administra células a nivel de iglesia mantiene el acceso completo.
        """
        cell = self.get_object()
        if not self._can_manage_any_cell(request.user) and not self._leads(cell, request.user):
            return Response(
                {"error": "Sólo puedes editar la célula que tienes a tu cargo."},
                status=status.HTTP_403_FORBIDDEN
            )
        return handler(request, *args, **kwargs)

    @action(detail=False, methods=['get'], url_path='my-cells')
    def my_cells(self, request):
        """Células que la persona autenticada tiene a su cargo."""
        cells = self.get_queryset().filter(leader=request.user)
        serializer = self.get_serializer(cells, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def members(self, request, pk=None):
        """
        Personas asignadas a la célula.

        Visible para el líder de esa célula y para quien administra células.
        """
        cell = self.get_object()

        if not self._can_manage_any_cell(request.user) and not self._leads(cell, request.user):
            return Response(
                {"error": "Sólo puedes ver los miembros de la célula que tienes a tu cargo."},
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

        if not self._can_manage_any_cell(request.user) and not self._leads(cell, request.user):
            return Response(
                {"error": "Sólo puedes enviar recordatorios a la célula que tienes a tu cargo."},
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
            scheduled_for=scheduled,
            status=NotificationStatus.SENT if is_immediate else NotificationStatus.PENDING,
            sent_at=timezone.now() if is_immediate else None,
        )

        if not is_immediate:
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

        # El líder edita la célula que tiene a cargo sin necesitar el permiso
        # global CELLS_EDIT, que corresponde a quien administra todas.
        if self.action in ['update', 'partial_update'] and self._leads_target_cell(request.user):
            if not request.user or not request.user.is_authenticated:
                self.permission_denied(request)
            return

        self.required_permission = self.get_required_permission()
        super().check_permissions(request)

    def _leads_target_cell(self, user):
        """Resuelve la célula de la URL y comprueba si el usuario la lidera."""
        if not user or not user.is_authenticated:
            return False

        lookup_value = self.kwargs.get(self.lookup_url_kwarg or self.lookup_field or 'pk')
        if not lookup_value:
            return False

        cell = CellGroup.objects.filter(pk=lookup_value).first() if str(lookup_value).isdigit() else None
        if cell is None:
            cell = CellGroup.objects.filter(slug=lookup_value).first()

        return bool(cell and cell.leader_id == user.id)
