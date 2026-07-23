from rest_framework import serializers
from apps.audit.models import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
    user_email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = AuditLog
        fields = ('id', 'user', 'user_email', 'action', 'module', 'object_id', 'description', 'ip_address', 'user_agent', 'created_at')
        read_only_fields = fields
