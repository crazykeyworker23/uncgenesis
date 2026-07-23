from rest_framework import generics, permissions
from apps.audit.models import AuditLog
from apps.audit.serializers import AuditLogSerializer
from apps.roles.permissions import HasAppPermission


class AuditLogListView(generics.ListAPIView):
    """
    Vista administrativa para consultar los logs de auditoría del sistema.
    Requiere que el usuario tenga rol administrativo (permiso USERS_VIEW).
    """
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
    permission_classes = [HasAppPermission]
    required_permission = 'USERS_VIEW'
    filterset_fields = ['action', 'module', 'user']
    search_fields = ['description', 'ip_address', 'object_id']
