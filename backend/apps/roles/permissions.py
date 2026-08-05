from rest_framework.permissions import BasePermission


class HasAppPermission(BasePermission):
    """
    Clase de permiso personalizada que verifica si el usuario autenticado tiene el
    permiso necesario mapeado en su Rol (RBAC).
    
    El View/ViewSet debe definir el atributo `required_permission` (ej. 'PUBLICATIONS_CREATE').
    """

    def has_permission(self, request, view):
        # 1. Verificar si el usuario está autenticado
        if not request.user or not request.user.is_authenticated:
            return False

        # 2. El superadministrador tiene permisos totales automáticamente.
        #    Se reconoce por la marca de Django o por el rol SUPERADMIN, para
        #    que asignar el rol desde el panel conceda realmente control total.
        from apps.roles.utils import is_superadmin

        if is_superadmin(request.user):
            return True

        # 3. Obtener el permiso requerido desde la vista
        required_permission = getattr(view, 'required_permission', None)
        if not required_permission:
            # Si la vista no define un permiso requerido, permitimos el paso por defecto (solo requiere autenticación)
            return True

        # 4. Validar existencia del permiso en los roles asociados al usuario
        from apps.roles.models import UserRole
        return UserRole.objects.filter(
            user=request.user,
            role__role_permissions__permission__codename=required_permission
        ).exists()
