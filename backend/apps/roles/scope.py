"""
Motor de alcance: qué datos puede tocar cada usuario.

El catálogo de permisos responde *qué acción* puede ejecutar alguien
(`ATTENDANCE_EDIT`); este módulo responde *sobre qué registros* puede
ejecutarla. Los dos juntos forman la regla completa:

    Superadministrador  →  toda la plataforma
    Pastor              →  toda la iglesia
    Coordinador         →  las células que tiene asignadas
    Líder               →  la célula que lidera
    Miembro             →  su propia información

Todo endpoint que exponga datos de células debe filtrar con
`filter_cell_queryset` o comprobar con `can_reach_cell`, de modo que nadie
alcance un registro ajeno escribiendo la URL a mano.
"""

from apps.roles.models import ROLE_SCOPES, SCOPE_RANK, AccessScope, RoleType


def get_user_scope(user):
    """
    Alcance efectivo del usuario.

    Si acumula varios roles se queda con el más amplio; quien lidera una célula
    obtiene al menos OWN_CELL aunque no tenga el rol asignado formalmente.
    """
    if not user or not getattr(user, 'is_authenticated', False):
        return None

    if getattr(user, 'is_superuser', False):
        return AccessScope.PLATFORM

    from apps.roles.utils import get_user_role_names

    scopes = [ROLE_SCOPES[role] for role in get_user_role_names(user) if role in ROLE_SCOPES]

    # La responsabilidad real manda sobre el rol declarado: quien tiene células
    # a cargo puede gestionarlas aunque nadie le haya asignado el rol.
    if user.led_cells.exists():
        scopes.append(AccessScope.OWN_CELL)
    if user.coordinated_cells.exists():
        scopes.append(AccessScope.ASSIGNED_CELLS)

    if not scopes:
        return AccessScope.SELF

    return max(scopes, key=lambda s: SCOPE_RANK[s])


# Tener alcance de iglesia no significa por sí solo poder ver la vida interna
# de todas las células. Un editor de contenido o un consejero abarcan la
# iglesia en lo suyo, pero no tienen nada que hacer en los miembros, las
# asistencias o los seguimientos de un grupo. Hace falta además un permiso de
# célula.
#
# CELLS_VIEW no sirve como señal: lo tiene también el editor de contenido, y
# sólo significa poder consultar el catálogo de células, que además es público.
# Lo que distingue a quien supervisa grupos es acceder a su vida interna.
CELL_RESPONSIBILITY_PERMISSIONS = [
    'MEETINGS_VIEW',
    'ATTENDANCE_VIEW',
    'FOLLOWUPS_VIEW',
]


def has_church_wide_scope(user):
    """`True` para pastor y superadministrador: ven la iglesia completa."""
    scope = get_user_scope(user)
    return scope in (AccessScope.CHURCH, AccessScope.PLATFORM)


def _reaches_every_cell(user):
    """`True` si el usuario supervisa las células de toda la iglesia."""
    from apps.roles.utils import has_any_permission, is_superadmin

    if is_superadmin(user):
        return True

    if get_user_scope(user) not in (AccessScope.CHURCH, AccessScope.PLATFORM):
        return False

    return has_any_permission(user, CELL_RESPONSIBILITY_PERMISSIONS)


def get_accessible_cell_ids(user):
    """
    Identificadores de las células que el usuario puede consultar.

    Devuelve `None` cuando el alcance es toda la iglesia, para que quien llame
    no aplique ningún filtro. Devuelve un conjunto vacío cuando no alcanza
    ninguna, lo que deja los listados en blanco en lugar de exponerlos.
    """
    scope = get_user_scope(user)

    if scope is None:
        return set()

    # Sólo quien supervisa células a nivel de iglesia queda sin filtro. Un
    # editor de contenido o un consejero abarcan la iglesia en su materia, pero
    # no en la vida interna de los grupos.
    if _reaches_every_cell(user):
        return None

    ids = set()

    if scope == AccessScope.ASSIGNED_CELLS:
        ids.update(user.coordinated_cells.values_list('id', flat=True))
        # Un coordinador puede además liderar su propia célula.
        ids.update(user.led_cells.values_list('id', flat=True))
        return ids

    if scope == AccessScope.OWN_CELL:
        ids.update(user.led_cells.values_list('id', flat=True))
        return ids

    # AccessScope.SELF: el miembro sólo alcanza la célula a la que pertenece.
    if getattr(user, 'assigned_cell_id', None):
        ids.add(user.assigned_cell_id)
    return ids


def filter_cell_queryset(queryset, user, field='id'):
    """
    Recorta un queryset a las células accesibles.

    `field` es la ruta hasta la célula desde el modelo consultado: `'id'` para
    CellGroup, `'cell_id'` para una reunión, `'meeting__cell_id'` para una
    asistencia.
    """
    allowed = get_accessible_cell_ids(user)
    if allowed is None:
        return queryset
    if not allowed:
        return queryset.none()
    return queryset.filter(**{f'{field}__in': allowed})


def can_reach_cell(user, cell_id):
    """`True` si el usuario puede consultar esa célula."""
    if cell_id is None:
        return False
    allowed = get_accessible_cell_ids(user)
    return allowed is None or cell_id in allowed


def can_manage_cell(user, cell_id):
    """
    `True` si además puede registrar o modificar datos de esa célula.

    Consultar y gestionar no son lo mismo: el miembro ve su célula pero no
    registra asistencia en ella, y el coordinador supervisa a sus líderes sin
    suplantarlos salvo que también lidere el grupo.
    """
    if cell_id is None:
        return False

    if _reaches_every_cell(user):
        return True

    scope = get_user_scope(user)

    if scope == AccessScope.ASSIGNED_CELLS:
        return (
            user.coordinated_cells.filter(id=cell_id).exists()
            or user.led_cells.filter(id=cell_id).exists()
        )

    if scope == AccessScope.OWN_CELL:
        return user.led_cells.filter(id=cell_id).exists()

    return False


def describe_scope(user):
    """Resumen del alcance, para que el panel sepa qué ofrecer."""
    scope = get_user_scope(user)
    allowed = get_accessible_cell_ids(user)

    return {
        'scope': scope.value if scope else None,
        'scope_label': scope.label if scope else None,
        'church_wide': allowed is None,
        'cell_ids': sorted(allowed) if allowed is not None else None,
        'leads_cell_ids': sorted(user.led_cells.values_list('id', flat=True))
        if user and getattr(user, 'is_authenticated', False)
        else [],
        'coordinates_cell_ids': sorted(user.coordinated_cells.values_list('id', flat=True))
        if user and getattr(user, 'is_authenticated', False)
        else [],
    }


__all__ = [
    'AccessScope',
    'RoleType',
    'can_manage_cell',
    'can_reach_cell',
    'describe_scope',
    'filter_cell_queryset',
    'get_accessible_cell_ids',
    'get_user_scope',
    'has_church_wide_scope',
]
