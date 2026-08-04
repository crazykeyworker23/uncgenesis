def has_any_permission(user, codenames):
    """
    Indica si el usuario tiene alguno de los permisos RBAC indicados.

    Se usa para distinguir a quien gestiona contenido (panel administrativo) de
    quien sólo lo consume desde la app, de modo que los borradores y archivados
    no se expongan públicamente.
    """
    if not user or not getattr(user, 'is_authenticated', False):
        return False

    if getattr(user, 'is_superuser', False):
        return True

    if not codenames:
        return False

    from apps.roles.models import UserRole

    return UserRole.objects.filter(
        user=user,
        role__role_permissions__permission__codename__in=list(codenames),
    ).exists()
