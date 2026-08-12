"""
Utilidades de control de acceso basado en roles (RBAC).

Centraliza las preguntas que el resto del sistema hace sobre un usuario:
si es superadministrador, qué permisos efectivos tiene y si puede entrar al
panel administrativo web.
"""

SUPERADMIN_ROLE = 'SUPERADMIN'

# Rol de quien solo usa la app móvil. No habilita el panel administrativo.
COMMUNITY_ROLE = 'MEMBER'

# Roles que operan el panel administrativo web.
#
# Es una lista de roles, y no «tener algún permiso», que es como se decidía
# antes. Con aquella regla entraba también quien lidera o coordina una célula,
# porque el catálogo le concede permisos para gestionarla; y el panel completo
# no es su sitio. El líder ve exactamente su célula desde la aplicación móvil.
#
# El editor de contenido y el consejero se quedan porque su trabajo
# —publicaciones, devocionales, peticiones de oración— sólo existe en el panel:
# dejarlos fuera equivaldría a que nadie pudiera hacerlo salvo el pastorado.
ADMIN_PANEL_ROLES = frozenset({
    'SUPERADMIN',
    'ADMIN',
    'CONTENT_EDITOR',
    'SUPPORT',
})


def get_user_role_names(user):
    """Nombres de los roles asignados al usuario."""
    if not user or not getattr(user, 'is_authenticated', False):
        return set()

    from apps.roles.models import UserRole

    return set(UserRole.objects.filter(user=user).values_list('role__name', flat=True))


def is_superadmin(user):
    """
    Un superadministrador tiene control total del sistema.

    Se reconoce tanto por la marca `is_superuser` de Django como por tener
    asignado el rol SUPERADMIN, para que ambas vías signifiquen lo mismo y no
    existan cuentas "administrador a medias".
    """
    if not user or not getattr(user, 'is_authenticated', False):
        return False

    if getattr(user, 'is_superuser', False):
        return True

    return SUPERADMIN_ROLE in get_user_role_names(user)


def get_user_permissions(user):
    """
    Conjunto de codenames que el usuario puede ejercer.

    El superadministrador recibe el catálogo completo, de forma que cualquier
    permiso nuevo queda cubierto automáticamente sin tener que reasignarlo.
    """
    if not user or not getattr(user, 'is_authenticated', False):
        return set()

    from apps.roles.models import Permission, UserRole

    if is_superadmin(user):
        return set(Permission.objects.values_list('codename', flat=True))

    return set(
        UserRole.objects.filter(user=user).values_list(
            'role__role_permissions__permission__codename', flat=True
        )
    ) - {None}


def has_any_permission(user, codenames):
    """
    Indica si el usuario tiene alguno de los permisos RBAC indicados.

    Se usa para distinguir a quien gestiona contenido (panel administrativo) de
    quien sólo lo consume desde la app, de modo que los borradores y archivados
    no se expongan públicamente.
    """
    if not user or not getattr(user, 'is_authenticated', False):
        return False

    if is_superadmin(user):
        return True

    if not codenames:
        return False

    from apps.roles.models import UserRole

    return UserRole.objects.filter(
        user=user,
        role__role_permissions__permission__codename__in=list(codenames),
    ).exists()


def can_access_admin_panel(user):
    """
    Determina si la cuenta puede entrar al panel administrativo web.

    El panel es la herramienta del pastorado y de quien produce contenido o
    atiende solicitudes. Todo lo demás se hace desde la aplicación móvil: el
    miembro consulta lo suyo y el líder gestiona su célula, sin ver el resto
    de la iglesia.

    Esto decide qué se le enseña al iniciar sesión en la web, no qué datos
    puede leer: de eso responden los permisos y el alcance de cada endpoint,
    que se comprueban en toda petición venga de donde venga.
    """
    if not user or not getattr(user, 'is_authenticated', False):
        return False

    # Una cuenta bloqueada o inactiva nunca entra, aunque conserve su rol.
    if not getattr(user, 'is_active', False):
        return False

    if is_superadmin(user):
        return True

    return bool(get_user_role_names(user) & ADMIN_PANEL_ROLES)
