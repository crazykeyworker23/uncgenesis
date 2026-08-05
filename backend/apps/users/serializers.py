from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from apps.roles.models import Role, UserRole
from apps.roles.utils import SUPERADMIN_ROLE, get_user_permissions, is_superadmin

User = get_user_model()


def _validate_password_strength(value):
    """Aplica los validadores de contraseña configurados en Django."""
    try:
        validate_password(value)
    except DjangoValidationError as exc:
        raise serializers.ValidationError(list(exc.messages))
    return value


class CustomUserAdminSerializer(serializers.ModelSerializer):
    roles = serializers.SerializerMethodField(read_only=True)
    permissions = serializers.SerializerMethodField(read_only=True)
    assigned_roles = serializers.ListField(
        child=serializers.CharField(),
        write_only=True,
        required=False
    )
    # Credenciales: se escriben pero nunca se devuelven.
    password = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        style={'input_type': 'password'},
    )

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'phone', 'avatar', 'location', 'bio', 'status',
            'is_staff', 'is_superuser', 'created_at',
            'roles', 'assigned_roles', 'permissions', 'password',
        ]
        read_only_fields = ['id', 'full_name', 'created_at', 'is_staff', 'is_superuser']

    def get_roles(self, obj):
        # Return list of role names associated with the user
        return list(obj.user_roles.values_list('role__name', flat=True))

    def get_permissions(self, obj):
        """Permisos efectivos, para que el panel sepa qué mostrarle."""
        return sorted(get_user_permissions(obj))

    def validate_password(self, value):
        if not value:
            return value
        return _validate_password_strength(value)

    def validate_assigned_roles(self, value):
        """Sólo un superadministrador puede conceder o retirar el rol SUPERADMIN."""
        request = self.context.get('request')
        actor = getattr(request, 'user', None)

        if SUPERADMIN_ROLE in value and not is_superadmin(actor):
            raise serializers.ValidationError(
                'Sólo un superadministrador puede asignar el rol de superadministrador.'
            )

        if self.instance is not None:
            had_superadmin = self.instance.user_roles.filter(
                role__name=SUPERADMIN_ROLE
            ).exists()
            if had_superadmin and SUPERADMIN_ROLE not in value and not is_superadmin(actor):
                raise serializers.ValidationError(
                    'Sólo un superadministrador puede retirar el rol de superadministrador.'
                )

        return value

    def create(self, validated_data):
        assigned_roles = validated_data.pop('assigned_roles', [])
        password = validated_data.pop('password', '') or ''

        # Antes se asignaba una contraseña fija ('genesis_default_123') a toda
        # cuenta creada desde el panel, lo que la dejaba accesible a cualquiera
        # que conociera el correo. Ahora es obligatorio definirla.
        if not password:
            raise serializers.ValidationError(
                {'password': 'Debes definir una contraseña para la nueva cuenta.'}
            )

        user = User.objects.create_user(password=password, **validated_data)
        self._sync_roles(user, assigned_roles)
        return user

    def update(self, instance, validated_data):
        assigned_roles = validated_data.pop('assigned_roles', None)
        password = validated_data.pop('password', '') or ''

        instance = super().update(instance, validated_data)

        if password:
            instance.set_password(password)
            instance.save(update_fields=['password'])

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

        # 3. El rol SUPERADMIN debe implicar control total real: se sincroniza
        #    con las marcas de Django para que ambas vías signifiquen lo mismo.
        should_be_superadmin = SUPERADMIN_ROLE in role_names
        if user.is_superuser != should_be_superadmin:
            user.is_superuser = should_be_superadmin
            user.is_staff = should_be_superadmin or user.is_staff
            user.save(update_fields=['is_superuser', 'is_staff'])


class SetPasswordSerializer(serializers.Serializer):
    """Restablecimiento de la contraseña de una cuenta por un administrador."""

    password = serializers.CharField(style={'input_type': 'password'})

    def validate_password(self, value):
        return _validate_password_strength(value)
