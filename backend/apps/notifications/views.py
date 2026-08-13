import logging

from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone

from apps.roles.permissions import HasAppPermission
from .models import FCMDevice, Notification, NotificationStatus
from .serializers import FCMDeviceSerializer, NotificationSerializer
from .tasks import send_push_notification_task

logger = logging.getLogger(__name__)

PERM_MAP = {
    'list': 'NOTIFICATIONS_VIEW',
    'retrieve': 'NOTIFICATIONS_VIEW',
    'create': 'NOTIFICATIONS_CREATE',
    'destroy': 'NOTIFICATIONS_DELETE',
    'send_now': 'NOTIFICATIONS_SEND',
}


class FCMDeviceViewSet(viewsets.ModelViewSet):
    queryset = FCMDevice.objects.all()
    serializer_class = FCMDeviceSerializer

    def get_permissions(self):
        if self.action == 'create':
            return [AllowAny()]
        return [IsAuthenticated()]


class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.select_related('sender').all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated, HasAppPermission]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'target_audience']
    search_fields = ['title', 'body', 'sender__first_name', 'sender__last_name']
    ordering_fields = ['created_at', 'scheduled_for', 'sent_at']
    ordering = ['-created_at']

    def get_queryset(self):
        user = self.request.user
        qs = Notification.objects.select_related('sender', 'target_user')

        # Si el usuario no esta autenticado (invitado / app anonima) -> No recibir notificaciones hasta iniciar sesion
        if not user or not user.is_authenticated:
            return qs.none()

        # Gestion de comunicados en el Panel Web (listado admin_view, borrado,
        # edicion o envio manual). Antes estaba limitada al superadministrador,
        # asi que el pastor veia la seccion en el menu pero solo con su feed
        # personal: no podia gestionar los comunicados que si le competen.
        # Ahora la abre el permiso del catalogo, que el superadministrador
        # tiene por definicion.
        from apps.roles.utils import has_any_permission

        is_management = (
            self.request.query_params.get('admin_view') == 'true'
            or self.action in ['destroy', 'update', 'partial_update', 'send_now']
        )
        # NOTIFICATIONS_VIEW no basta: lo tiene tambien el lider, para quien
        # significa "recibir comunicados". Gestionar los de la iglesia exige un
        # permiso de gestion.
        manages_communications = has_any_permission(user, [
            'NOTIFICATIONS_CREATE',
            'NOTIFICATIONS_SEND',
            'NOTIFICATIONS_DELETE',
        ])
        if is_management and manages_communications:
            return qs.all()

        # Para el feed de la App Movil:
        from django.db.models import Q
        from apps.roles.models import UserRole, RoleType

        user_roles = set(UserRole.objects.filter(user=user).values_list('role__name', flat=True))

        # Regla Absoluta de Seguridad QA:
        # 1. Si la notificacion tiene un target_user especificado -> SOLO es visible para ese target_user
        # 2. Si no tiene target_user -> Se evalua la audiencia masiva (ALL, LEADERS, MEMBERS)
        query = Q(target_user=user)
        query |= Q(target_audience='ALL', target_user__isnull=True)

        if user.is_superuser or RoleType.CELL_LEADER in user_roles:
            query |= Q(target_audience='LEADERS', target_user__isnull=True)
        if user.is_superuser or RoleType.MEMBER in user_roles:
            query |= Q(target_audience='MEMBERS', target_user__isnull=True)
        # Lo que los lideres escriben hacia arriba lo lee el pastorado.
        if user.is_superuser or RoleType.ADMIN in user_roles:
            query |= Q(target_audience='PASTORS', target_user__isnull=True)

        # 3. Recordatorios que el lider envia a su celula: los recibe quien
        #    esta asignado a esa celula, y tambien el propio lider.
        if getattr(user, 'assigned_cell_id', None):
            query |= Q(
                target_audience='CELL',
                target_cell_id=user.assigned_cell_id,
                target_user__isnull=True,
            )

        led_cell_ids = list(user.led_cells.values_list('id', flat=True))
        if led_cell_ids:
            query |= Q(
                target_audience='CELL',
                target_cell_id__in=led_cell_ids,
                target_user__isnull=True,
            )

        return qs.filter(query, status='SENT').distinct()

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return [IsAuthenticated(), HasAppPermission()]

    def get_required_permission(self):
        return PERM_MAP.get(self.action, 'NOTIFICATIONS_VIEW')

    def check_permissions(self, request):
        self.required_permission = self.get_required_permission()
        super().check_permissions(request)

    def perform_create(self, serializer):
        scheduled = serializer.validated_data.get('scheduled_for')
        is_immediate = not scheduled or scheduled <= timezone.now()
        
        initial_status = NotificationStatus.SENT if is_immediate else NotificationStatus.PENDING
        sent_time = timezone.now() if is_immediate else None

        notification = serializer.save(
            sender=self.request.user,
            status=initial_status,
            sent_at=sent_time
        )
        
        if is_immediate:
            # Antes sólo se marcaba como enviada: nunca salía al telefono.
            from .push import dispatch
            dispatch(notification)
        else:
            try:
                send_push_notification_task.apply_async((notification.id,), eta=scheduled)
            except Exception as error:
                # Que el broker no responda no debe tumbar la creación del
                # aviso: queda pendiente y la ronda de Celery Beat lo entrega
                # en cuanto venza su hora.
                logger.warning('No se pudo programar el aviso %s: %s', notification.id, error)

    @action(detail=True, methods=['post'], url_path='send-now')
    def send_now(self, request, pk=None):
        notification = self.get_object()
        
        if notification.status == NotificationStatus.SENT:
            return Response(
                {"error": "Esta notificación ya fue enviada con éxito."},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        notification.status = NotificationStatus.PENDING
        notification.scheduled_for = timezone.now()
        notification.error_message = ""
        notification.save()

        # Se entrega aquí mismo. Antes se delegaba en Celery, así que si el
        # trabajador no estaba levantado el botón «Enviar ahora» devolvía un
        # error, y si el broker respondía pero nadie procesaba la cola no pasaba
        # nada en absoluto. Enviando en el momento se sabe si salió o no.
        from .push import dispatch
        dispatch(notification)

        notification.refresh_from_db()
        serializer = self.get_serializer(notification)
        return Response(serializer.data)

