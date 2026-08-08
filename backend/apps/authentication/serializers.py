from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from drf_spectacular.utils import extend_schema_field
from django.contrib.auth.password_validation import validate_password

User = get_user_model()


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = getattr(user, 'email', '')
        token['full_name'] = getattr(user, 'full_name', '') or ''
        token['status'] = getattr(user, 'status', 'ACTIVE')
        return token

    def validate(self, attrs):
        username_val = attrs.get('username') or attrs.get('email')
        if username_val:
            attrs['username'] = username_val
            attrs['email'] = username_val

        data = super().validate(attrs)
        user = self.user
        
        if getattr(user, 'status', 'ACTIVE') != 'ACTIVE':
            raise serializers.ValidationError(
                "Este usuario no se encuentra activo.",
                code='authorization'
            )

        avatar_url = None
        try:
            if getattr(user, 'avatar', None):
                avatar_url = user.avatar.url
        except Exception:
            avatar_url = None

        # El alcance de la sesión viaja con el login para que el panel web sepa
        # de inmediato qué módulos habilitar y si la cuenta puede entrar
        # siquiera (los miembros de la comunidad usan sólo la app móvil).
        from apps.roles.utils import (
            can_access_admin_panel,
            get_user_permissions,
            get_user_role_names,
            is_superadmin,
        )

        data['user'] = {
            'id': user.id,
            'email': getattr(user, 'email', ''),
            'full_name': getattr(user, 'full_name', '') or '',
            'first_name': getattr(user, 'first_name', '') or '',
            'last_name': getattr(user, 'last_name', '') or '',
            'phone': getattr(user, 'phone', '') or '',
            'location': getattr(user, 'location', '') or '',
            'bio': getattr(user, 'bio', '') or '',
            'status': getattr(user, 'status', 'ACTIVE'),
            'avatar': avatar_url,
            'roles': sorted(get_user_role_names(user)),
            'permissions': sorted(get_user_permissions(user)),
            'is_superadmin': is_superadmin(user),
            'can_access_admin': can_access_admin_panel(user),
            'leads_cells': user.led_cells.count(),
        }
        return data


class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('email', 'first_name', 'last_name', 'phone', 'password', 'password_confirm')

    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({"password": "Las contraseñas no coinciden"})
        return data

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        return User.objects.create_user(password=password, **validated_data)


class GoogleAuthSerializer(serializers.Serializer):
    id_token = serializers.CharField(required=True)


class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)


class ResetPasswordSerializer(serializers.Serializer):
    token = serializers.CharField(required=True)
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({"password": "Las contraseñas no coinciden"})
        return data


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(write_only=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(write_only=True)

    def validate(self, data):
        if data['new_password'] != data['new_password_confirm']:
            raise serializers.ValidationError({"new_password": "Las contraseñas nuevas no coinciden"})
        return data


class UserMeSerializer(serializers.ModelSerializer):
    # El panel administrativo necesita conocer el alcance de la sesión para
    # mostrar sólo los módulos que el rol puede gestionar. Antes no se exponía
    # nada de esto y la web enseñaba el menú completo a cualquiera.
    roles = serializers.SerializerMethodField(read_only=True)
    permissions = serializers.SerializerMethodField(read_only=True)
    is_superadmin = serializers.SerializerMethodField(read_only=True)
    can_access_admin = serializers.SerializerMethodField(read_only=True)
    leads_cells = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = User
        fields = (
            'id', 'email', 'first_name', 'last_name', 'full_name', 'phone',
            'avatar', 'location', 'bio', 'status', 'created_at',
            'roles', 'permissions', 'is_superadmin', 'can_access_admin',
            'leads_cells',
        )
        read_only_fields = (
            'id', 'email', 'full_name', 'status', 'created_at',
            'roles', 'permissions', 'is_superadmin', 'can_access_admin',
            'leads_cells',
        )

    # Los tipos se declaran para que la documentación OpenAPI publique el tipo
    # real de cada campo en lugar de asumir texto.
    @extend_schema_field(serializers.IntegerField())
    def get_leads_cells(self, obj):
        """Cuántas células tiene a su cargo: habilita la sección "Mi Célula"."""
        return obj.led_cells.count()

    @extend_schema_field(serializers.ListSerializer(child=serializers.CharField()))
    def get_roles(self, obj):
        from apps.roles.utils import get_user_role_names

        return sorted(get_user_role_names(obj))

    @extend_schema_field(serializers.ListSerializer(child=serializers.CharField()))
    def get_permissions(self, obj):
        from apps.roles.utils import get_user_permissions

        return sorted(get_user_permissions(obj))

    @extend_schema_field(serializers.BooleanField())
    def get_is_superadmin(self, obj):
        from apps.roles.utils import is_superadmin

        return is_superadmin(obj)

    @extend_schema_field(serializers.BooleanField())
    def get_can_access_admin(self, obj):
        from apps.roles.utils import can_access_admin_panel

        return can_access_admin_panel(obj)
