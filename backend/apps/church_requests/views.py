from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from apps.roles.permissions import HasAppPermission
from .models import PrayerRequest, VisitorRequest
from .serializers import (
    PrayerRequestSerializer,
    PrayerRequestCreateSerializer,
    VisitorRequestSerializer,
    VisitorRequestCreateSerializer,
    AssignSerializer,
    ChangeStatusSerializer,
)

# Los codenames deben coincidir con el catálogo de apps/roles. Antes se exigían
# PRAYER_* y VISITOR_*, que no existen en ninguna parte: como HasAppPermission
# sólo concede lo que está asignado, el rol de Soporte y Consejería —cuyo
# trabajo es justamente atender estas solicitudes— no podía ni listarlas.
PRAYER_PERM_MAP = {
    'list':           'REQUESTS_VIEW',
    'retrieve':       'REQUESTS_VIEW',
    'create':         None,   # public
    'update':         'REQUESTS_RESPOND',
    'partial_update': 'REQUESTS_RESPOND',
    'destroy':        'REQUESTS_DELETE',
    'assign':         'REQUESTS_ASSIGN',
    'change_status':  'REQUESTS_RESPOND',
}

VISITOR_PERM_MAP = {
    'list':           'REQUESTS_VIEW',
    'retrieve':       'REQUESTS_VIEW',
    'create':         None,   # public
    'update':         'REQUESTS_RESPOND',
    'partial_update': 'REQUESTS_RESPOND',
    'destroy':        'REQUESTS_DELETE',
    'assign':         'REQUESTS_ASSIGN',
    'change_status':  'REQUESTS_RESPOND',
}


class PrayerRequestViewSet(viewsets.ModelViewSet):
    queryset = PrayerRequest.objects.select_related('assigned_to').all()
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'is_anonymous', 'assigned_to']
    search_fields = ['requester_name', 'subject', 'description']
    ordering_fields = ['created_at', 'status']
    ordering = ['-created_at']

    def get_permissions(self):
        if self.action == 'create':
            return [AllowAny()]
        return [IsAuthenticated(), HasAppPermission()]

    def get_serializer_class(self):
        if self.action == 'create':
            return PrayerRequestCreateSerializer
        return PrayerRequestSerializer

    def check_permissions(self, request):
        perm = PRAYER_PERM_MAP.get(self.action)
        if perm:
            self.required_permission = perm
        super().check_permissions(request)

    @action(detail=True, methods=['post'], url_path='assign')
    def assign(self, request, pk=None):
        obj = self.get_object()
        ser = AssignSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        obj.assigned_to = ser.validated_data['assigned_to_id']
        obj.save(update_fields=['assigned_to', 'updated_at'])
        return Response(PrayerRequestSerializer(obj).data)

    @action(detail=True, methods=['post'], url_path='change-status')
    def change_status(self, request, pk=None):
        obj = self.get_object()
        ser = ChangeStatusSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        obj.status = ser.validated_data['status']
        if ser.validated_data.get('notes'):
            obj.notes = ser.validated_data['notes']
        obj.save(update_fields=['status', 'notes', 'updated_at'])
        return Response(PrayerRequestSerializer(obj).data)


class VisitorRequestViewSet(viewsets.ModelViewSet):
    queryset = VisitorRequest.objects.select_related('assigned_to', 'cell_group', 'user').all()
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'how_did_you_find_us', 'preferred_contact', 'age_range', 'assigned_to', 'cell_group']
    search_fields = ['full_name', 'email', 'phone', 'message']
    ordering_fields = ['created_at', 'status']
    ordering = ['-created_at']

    def get_permissions(self):
        if self.action in ['create', 'my_status']:
            return [AllowAny()]
        return [IsAuthenticated(), HasAppPermission()]

    def get_serializer_class(self):
        if self.action == 'create':
            return VisitorRequestCreateSerializer
        return VisitorRequestSerializer

    def check_permissions(self, request):
        perm = VISITOR_PERM_MAP.get(self.action)
        if perm:
            self.required_permission = perm
        super().check_permissions(request)

    def perform_create(self, serializer):
        user = self.request.user if self.request.user.is_authenticated else None
        serializer.save(user=user)

    def _sync_cell_assignment(self, obj):
        if obj.status == 'RESOLVED' and obj.cell_group:
            target_user = obj.user
            if not target_user and obj.email:
                from apps.users.models import CustomUser
                target_user = CustomUser.objects.filter(email=obj.email).first()
            if target_user:
                target_user.assigned_cell = obj.cell_group
                target_user.save(update_fields=['assigned_cell', 'updated_at'])

                # Send Notification & Push Notification
                try:
                    from apps.notifications.models import Notification, NotificationStatus, FCMDevice
                    from django.utils import timezone
                    title = "¡Bienvenido a tu nueva Célula! 🎉"
                    cell_name = obj.cell_group.name
                    body = f"Hola {target_user.first_name or target_user.full_name or 'hermano'}, tu solicitud ha sido aprobada. Ahora formas parte de '{cell_name}'. ¡Te esperamos!"

                    notification = Notification.objects.create(
                        title=title,
                        body=body,
                        status=NotificationStatus.SENT,
                        scheduled_for=timezone.now(),
                        sent_at=timezone.now(),
                        error_message=f"Aprobación de célula para {target_user.email}"
                    )

                    devices = FCMDevice.objects.filter(user=target_user)
                    tokens = list(devices.values_list('token', flat=True).distinct())
                    if tokens:
                        from apps.notifications.tasks import firebase_app
                        if firebase_app:
                            from firebase_admin import messaging
                            message = messaging.MulticastMessage(
                                notification=messaging.Notification(title=title, body=body),
                                tokens=tokens,
                            )
                            messaging.send_multicast(message)
                except Exception as e:
                    pass

    def perform_update(self, serializer):
        obj = serializer.save()
        self._sync_cell_assignment(obj)

    @action(detail=True, methods=['post'], url_path='assign')
    def assign(self, request, pk=None):
        obj = self.get_object()
        ser = AssignSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        obj.assigned_to = ser.validated_data['assigned_to_id']
        obj.save(update_fields=['assigned_to', 'updated_at'])
        return Response(VisitorRequestSerializer(obj).data)

    @action(detail=True, methods=['post'], url_path='change-status')
    def change_status(self, request, pk=None):
        obj = self.get_object()
        ser = ChangeStatusSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        obj.status = ser.validated_data['status']
        if ser.validated_data.get('notes'):
            obj.notes = ser.validated_data['notes']
        obj.save(update_fields=['status', 'notes', 'updated_at'])
        self._sync_cell_assignment(obj)
        return Response(VisitorRequestSerializer(obj).data)

    @action(detail=False, methods=['get'], url_path='my-status')
    def my_status(self, request):
        user = request.user if request.user.is_authenticated else None
        email = request.query_params.get('email')

        assigned_cell_data = None
        pending_request_data = None

        if user:
            if user.assigned_cell:
                from .serializers import CellGroupSimpleSerializer
                assigned_cell_data = CellGroupSimpleSerializer(user.assigned_cell).data
            
            pending_req = VisitorRequest.objects.filter(
                user=user,
                status__in=['PENDING', 'IN_PROGRESS']
            ).first()
            if not pending_req and user.email:
                pending_req = VisitorRequest.objects.filter(
                    email=user.email,
                    status__in=['PENDING', 'IN_PROGRESS']
                ).first()
            if pending_req:
                pending_request_data = VisitorRequestSerializer(pending_req).data
        elif email:
            from apps.users.models import CustomUser
            matched_user = CustomUser.objects.filter(email=email).first()
            if matched_user and matched_user.assigned_cell:
                from .serializers import CellGroupSimpleSerializer
                assigned_cell_data = CellGroupSimpleSerializer(matched_user.assigned_cell).data

            pending_req = VisitorRequest.objects.filter(
                email=email,
                status__in=['PENDING', 'IN_PROGRESS']
            ).first()
            if pending_req:
                pending_request_data = VisitorRequestSerializer(pending_req).data

        return Response({
            'assigned_cell': assigned_cell_data,
            'pending_request': pending_request_data
        })
