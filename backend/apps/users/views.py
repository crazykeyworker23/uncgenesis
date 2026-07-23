from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth import get_user_model

from apps.roles.permissions import HasAppPermission
from .models import UserStatus
from .serializers import CustomUserAdminSerializer

User = get_user_model()

PERM_MAP = {
    'list': 'USERS_VIEW',
    'retrieve': 'USERS_VIEW',
    'create': 'USERS_EDIT',
    'update': 'USERS_EDIT',
    'partial_update': 'USERS_EDIT',
    'destroy': 'USERS_EDIT',
    'block': 'USERS_BLOCK',
    'unblock': 'USERS_BLOCK',
}


class CustomUserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.prefetch_related('user_roles__role').all()
    serializer_class = CustomUserAdminSerializer
    permission_classes = [IsAuthenticated, HasAppPermission]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status']
    search_fields = ['email', 'first_name', 'last_name', 'phone']
    ordering_fields = ['created_at', 'email', 'first_name']
    ordering = ['-created_at']

    def get_required_permission(self):
        return PERM_MAP.get(self.action, 'USERS_VIEW')

    def check_permissions(self, request):
        self.required_permission = self.get_required_permission()
        super().check_permissions(request)

    @action(detail=True, methods=['post'], url_path='block')
    def block(self, request, pk=None):
        user = self.get_object()
        if user == request.user:
            return Response(
                {"error": "No puedes bloquearte a ti mismo."},
                status=status.HTTP_400_BAD_REQUEST
            )
        user.status = UserStatus.BLOCKED
        user.save()
        serializer = self.get_serializer(user)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='unblock')
    def unblock(self, request, pk=None):
        user = self.get_object()
        user.status = UserStatus.ACTIVE
        user.save()
        serializer = self.get_serializer(user)
        return Response(serializer.data)
