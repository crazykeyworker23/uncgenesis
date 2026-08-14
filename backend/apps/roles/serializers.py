from rest_framework import serializers
from .models import Role, Permission, RolePermission


class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permission
        fields = ['id', 'codename', 'name', 'description']


class RoleSerializer(serializers.ModelSerializer):
    permissions = serializers.SerializerMethodField(read_only=True)
    assigned_permissions = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False
    )

    class Meta:
        model = Role
        fields = [
            'id', 'name', 'description', 'created_at', 'updated_at',
            'permissions', 'assigned_permissions'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_permissions(self, obj):
        # Returns list of permission codenames mapped to the role
        return list(obj.role_permissions.values_list('permission__codename', flat=True))

    def create(self, validated_data):
        assigned_permissions = validated_data.pop('assigned_permissions', [])
        role = Role.objects.create(**validated_data)
        self._sync_permissions(role, assigned_permissions)
        return role

    def update(self, instance, validated_data):
        assigned_permissions = validated_data.pop('assigned_permissions', None)
        role = super().update(instance, validated_data)
        
        if assigned_permissions is not None:
            self._sync_permissions(role, assigned_permissions)
            
        return role

    def _sync_permissions(self, role, codenames):
        # 1. Clear existing permissions
        RolePermission.objects.filter(role=role).delete()
        # 2. Create new permissions
        for codename in codenames:
            try:
                permission = Permission.objects.get(codename=codename)
                RolePermission.objects.create(role=role, permission=permission)
            except Permission.DoesNotExist:
                pass
