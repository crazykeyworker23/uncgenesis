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

        # Si es superusuario / admin en el panel web -> Ver historial completo
        if user and user.is_authenticated and user.is_superuser:
            return qs.all()

        # Si el usuario no esta autenticado (invitado / app anonima) -> No recibir notificaciones hasta iniciar sesion
        if not user or not user.is_authenticated:
            return qs.none()

        # Para un usuario autenticado en la App Movil:
        from django.db.models import Q
        from apps.roles.models import UserRole, RoleType

        user_roles = set(UserRole.objects.filter(user=user).values_list('role__name', flat=True))

        query = Q(target_audience='ALL')
        query |= Q(target_audience='USER', target_user=user)

        if RoleType.CELL_LEADER in user_roles:
            query |= Q(target_audience='LEADERS')
        if RoleType.MEMBER in user_roles:
            query |= Q(target_audience='MEMBERS')

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
        notification = serializer.save(sender=self.request.user, status=NotificationStatus.PENDING)
        
        scheduled = notification.scheduled_for
        if scheduled and scheduled > timezone.now():
            send_push_notification_task.apply_async((notification.id,), eta=scheduled)
        else:
            try:
                send_push_notification_task.delay(notification.id)
            except Exception:
                send_push_notification_task(notification.id)

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

