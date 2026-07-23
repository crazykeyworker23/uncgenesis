from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.roles.models import Role, UserRole

User = get_user_model()


class CustomUserAdminSerializer(serializers.ModelSerializer):
    roles = serializers.SerializerMethodField(read_only=True)
    assigned_roles = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False
    )

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'phone', 'avatar', 'location', 'bio', 'status',
            'is_staff', 'is_superuser', 'created_at', 'roles', 'assigned_roles'
        ]
        read_only_fields = ['id', 'full_name', 'created_at']

    def get_roles(self, obj):
        # Return list of role names associated with the user
        return list(obj.user_roles.values_list('role__name', flat=True))

    def create(self, validated_data):
        assigned_roles = validated_data.pop('assigned_roles', [])
        # Provide a default password since this is an admin creation flow
        # In a real app, we'd trigger a reset password email.
        password = validated_data.pop('password', 'genesis_default_123')
        
        user = User.objects.create_user(password=password, **validated_data)
        self._sync_roles(user, assigned_roles)
        return user

    def update(self, instance, validated_data):
        assigned_roles = validated_data.pop('assigned_roles', None)
        
        instance = super().update(instance, validated_data)
        
        if assigned_roles is not None:
            self._sync_roles(instance, assigned_roles)
            
        return instance

    def _sync_roles(self, user, role_names):
        # 1. Clear existing roles
        UserRole.objects.filter(user=user).delete()
        # 2. Add new roles
        for role_name in role_names:
            try:
                role = Role.objects.get(name=role_name)
                UserRole.objects.create(user=user, role=role)
            except Role.DoesNotExist:
                pass
