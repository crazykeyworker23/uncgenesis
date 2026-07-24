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

        # Si la consulta proviene explicitamente del Panel Web Administrativo -> Superusuario ve todo el historial
        if user.is_superuser and self.request.query_params.get('admin_view') == 'true':
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
        
        if not is_immediate:
            send_push_notification_task.apply_async((notification.id,), eta=scheduled)

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
        
        # Trigger task immediately
        send_push_notification_task.delay(notification.id)
        
        serializer = self.get_serializer(notification)
        return Response(serializer.data)

