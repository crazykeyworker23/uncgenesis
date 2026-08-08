from django.db import models
from django.conf import settings


class RoleType(models.TextChoices):
    SUPERADMIN = 'SUPERADMIN', 'Super Administrador'
    ADMIN = 'ADMIN', 'Pastor / Administrador General'
    COORDINATOR = 'COORDINATOR', 'Coordinador de Células'
    CONTENT_EDITOR = 'CONTENT_EDITOR', 'Editor de Contenido'
    CELL_LEADER = 'CELL_LEADER', 'Líder de Célula'
    SUPPORT = 'SUPPORT', 'Soporte y Consejería'
    MEMBER = 'MEMBER', 'Miembro de la Comunidad'
    VIEWER = 'VIEWER', 'Visitante/Espectador'


class AccessScope(models.TextChoices):
    """
    Alcance sobre el que un rol puede operar.

    Es la pieza central del modelo de permisos: el permiso dice *qué* acción se
    puede ejecutar y el alcance dice *sobre qué datos*. Un líder y un pastor
    pueden compartir el permiso de registrar asistencia, pero el primero sólo
    la registra en su célula.
    """

    PLATFORM = 'PLATFORM', 'Toda la plataforma'
    CHURCH = 'CHURCH', 'Toda la iglesia'
    ASSIGNED_CELLS = 'ASSIGNED_CELLS', 'Células asignadas'
    OWN_CELL = 'OWN_CELL', 'Su propia célula'
    SELF = 'SELF', 'Su propia información'


# Alcance que otorga cada rol. Si alguien acumula varios roles, se aplica el
# más amplio (ver `apps.roles.scope.get_user_scope`).
ROLE_SCOPES = {
    RoleType.SUPERADMIN: AccessScope.PLATFORM,
    RoleType.ADMIN: AccessScope.CHURCH,
    RoleType.CONTENT_EDITOR: AccessScope.CHURCH,
    RoleType.SUPPORT: AccessScope.CHURCH,
    RoleType.COORDINATOR: AccessScope.ASSIGNED_CELLS,
    RoleType.CELL_LEADER: AccessScope.OWN_CELL,
    RoleType.MEMBER: AccessScope.SELF,
    RoleType.VIEWER: AccessScope.SELF,
}

# De menor a mayor amplitud. Permite comparar y quedarse con el mayor.
SCOPE_RANK = {
    AccessScope.SELF: 0,
    AccessScope.OWN_CELL: 1,
    AccessScope.ASSIGNED_CELLS: 2,
    AccessScope.CHURCH: 3,
    AccessScope.PLATFORM: 4,
}


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
