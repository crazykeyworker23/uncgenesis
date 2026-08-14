from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated

from apps.roles.permissions import HasAppPermission
from .models import Role, Permission
from .serializers import RoleSerializer, PermissionSerializer

ROLE_PERM_MAP = {
    'list': 'ROLES_VIEW',
    'retrieve': 'ROLES_VIEW',
    'create': 'ROLES_EDIT',
    'update': 'ROLES_EDIT',
    'partial_update': 'ROLES_EDIT',
    'destroy': 'ROLES_EDIT',
}


class RoleViewSet(viewsets.ModelViewSet):
    queryset = Role.objects.prefetch_related('role_permissions__permission').all()
    serializer_class = RoleSerializer
    permission_classes = [IsAuthenticated, HasAppPermission]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description']
    pagination_class = None

    def get_required_permission(self):
        return ROLE_PERM_MAP.get(self.action, 'ROLES_VIEW')

    def check_permissions(self, request):
        self.required_permission = self.get_required_permission()
        super().check_permissions(request)


class PermissionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Permission.objects.all()
    serializer_class = PermissionSerializer
    permission_classes = [IsAuthenticated, HasAppPermission]
    filter_backends = [filters.SearchFilter]
    search_fields = ['codename', 'name']
    pagination_class = None

    def get_required_permission(self):
        return 'ROLES_VIEW'

    def check_permissions(self, request):
        self.required_permission = self.get_required_permission()
        super().check_permissions(request)
