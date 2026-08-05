from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth import get_user_model
from django.db.models import Q

from apps.roles.permissions import HasAppPermission
from apps.roles.utils import SUPERADMIN_ROLE, is_superadmin
from .models import UserStatus
from .serializers import CustomUserAdminSerializer, SetPasswordSerializer

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
    'set_password': 'USERS_EDIT',
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

    def _guard_superadmin_target(self, target):
        """
        Una cuenta de superadministrador sólo puede ser intervenida por otro
        superadministrador. Evita que un administrador de menor alcance le
        cambie la contraseña, la bloquee o la elimine.
        """
        if is_superadmin(target) and not is_superadmin(self.request.user):
            return Response(
                {"error": "Sólo un superadministrador puede modificar otra cuenta de superadministrador."},
                status=status.HTTP_403_FORBIDDEN
            )
        return None

    def update(self, request, *args, **kwargs):
        blocked = self._guard_superadmin_target(self.get_object())
        if blocked:
            return blocked
        return super().update(request, *args, **kwargs)

    def partial_update(self, request, *args, **kwargs):
        blocked = self._guard_superadmin_target(self.get_object())
        if blocked:
            return blocked
        return super().partial_update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        target = self.get_object()

        # Evita que alguien se quede sin acceso borrando su propia cuenta.
        if target == request.user:
            return Response(
                {"error": "No puedes eliminar tu propia cuenta."},
                status=status.HTTP_400_BAD_REQUEST
            )

        blocked = self._guard_superadmin_target(target)
        if blocked:
            return blocked

        # El sistema debe conservar siempre al menos un superadministrador.
        if is_superadmin(target) and self._count_superadmins() <= 1:
            return Response(
                {"error": "No puedes eliminar al único superadministrador del sistema."},
                status=status.HTTP_400_BAD_REQUEST
            )

        return super().destroy(request, *args, **kwargs)

    def _count_superadmins(self):
        """Cuántas cuentas activas conservan control total del sistema."""
        return User.objects.filter(is_active=True).filter(
            Q(is_superuser=True) | Q(user_roles__role__name=SUPERADMIN_ROLE)
        ).distinct().count()

    @action(detail=True, methods=['post'], url_path='set-password')
    def set_password(self, request, pk=None):
        """
        Restablece la contraseña de una cuenta.

        Permite al superadministrador actualizar las credenciales de acceso de
        cualquier persona sin necesitar la contraseña anterior.
        """
        user = self.get_object()

        blocked = self._guard_superadmin_target(user)
        if blocked:
            return blocked

        serializer = SetPasswordSerializer(data=request.data, context={'user': user})
        serializer.is_valid(raise_exception=True)

        user.set_password(serializer.validated_data['password'])
        user.save(update_fields=['password'])

        return Response(
            {"detail": f"Contraseña actualizada para {user.email}."},
            status=status.HTTP_200_OK
        )

    @action(detail=True, methods=['post'], url_path='block')
    def block(self, request, pk=None):
        user = self.get_object()
        if user == request.user:
            return Response(
                {"error": "No puedes bloquearte a ti mismo."},
                status=status.HTTP_400_BAD_REQUEST
            )

        blocked = self._guard_superadmin_target(user)
        if blocked:
            return blocked

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
