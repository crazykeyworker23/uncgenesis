from django.db import models
from django.conf import settings


class RoleType(models.TextChoices):
    SUPERADMIN = 'SUPERADMIN', 'Super Administrador'
    ADMIN = 'ADMIN', 'Administrador'
    CONTENT_EDITOR = 'CONTENT_EDITOR', 'Editor de Contenido'
    CELL_LEADER = 'CELL_LEADER', 'Líder de Célula'
    SUPPORT = 'SUPPORT', 'Soporte y Consejería'
    MEMBER = 'MEMBER', 'Miembro de la Comunidad'
    VIEWER = 'VIEWER', 'Visitante/Espectador'


class Role(models.Model):
    name = models.CharField(
        max_length=50,
        choices=RoleType.choices,
        unique=True,
        db_index=True
    )
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'rol'
        verbose_name_plural = 'roles'

    def __str__(self):
        return self.get_name_display()


class Permission(models.Model):
    codename = models.CharField(max_length=100, unique=True, db_index=True)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'permiso'
        verbose_name_plural = 'permisos'

    def __str__(self):
        return f"{self.name} ({self.codename})"


class RolePermission(models.Model):
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='role_permissions')
    permission = models.ForeignKey(Permission, on_delete=models.CASCADE, related_name='permission_roles')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'permiso de rol'
        verbose_name_plural = 'permisos de roles'
        constraints = [
            models.UniqueConstraint(fields=['role', 'permission'], name='unique_role_permission')
        ]

    def __str__(self):
        return f"{self.role.name} - {self.permission.codename}"


class UserRole(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='user_roles')
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='role_users')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'rol de usuario'
        verbose_name_plural = 'roles de usuarios'
        constraints = [
            models.UniqueConstraint(fields=['user', 'role'], name='unique_user_role')
        ]

    def __str__(self):
        return f"{self.user.email} - {self.role.name}"
