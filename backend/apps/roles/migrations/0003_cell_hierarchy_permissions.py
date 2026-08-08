from django.db import migrations


# Permisos nuevos que exige la gestión de células por jerarquía.
NEW_PERMISSIONS = {
    'MEETINGS': ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
    'ATTENDANCE': ['VIEW', 'EDIT'],
    'FOLLOWUPS': ['VIEW', 'CREATE', 'EDIT'],
    # Alta de integrantes y visitantes desde la célula, sin abrir la
    # administración de cuentas del sistema.
    'MEMBERS': ['REGISTER'],
}

MODULE_LABELS = {
    'MEETINGS': 'reuniones de célula',
    'ATTENDANCE': 'asistencias',
    'FOLLOWUPS': 'seguimientos de miembros',
    'MEMBERS': 'integrantes de célula',
}

ACTION_LABELS = {
    'VIEW': 'consultar',
    'CREATE': 'registrar',
    'EDIT': 'modificar',
    'DELETE': 'eliminar',
    'REGISTER': 'dar de alta',
}

# Alcance de cada rol según el diseño acordado. El permiso dice qué acción se
# puede ejecutar; el módulo apps/roles/scope.py decide sobre qué células.
ROLE_PERMISSIONS = {
    # Pastor / Administrador General: toda la iglesia. No administra roles ni
    # permisos —eso es del superadministrador— pero sí ve a todo el personal.
    'ADMIN': [
        'PUBLICATIONS_VIEW', 'PUBLICATIONS_CREATE', 'PUBLICATIONS_EDIT',
        'PUBLICATIONS_PUBLISH', 'PUBLICATIONS_DELETE', 'PUBLICATIONS_EXPORT',
        'SERVICES_VIEW', 'SERVICES_CREATE', 'SERVICES_EDIT',
        'SERVICES_PUBLISH', 'SERVICES_DELETE', 'SERVICES_EXPORT',
        'DEVOTIONALS_VIEW', 'DEVOTIONALS_CREATE', 'DEVOTIONALS_EDIT',
        'DEVOTIONALS_PUBLISH', 'DEVOTIONALS_DELETE', 'DEVOTIONALS_EXPORT',
        'EVENTS_VIEW', 'EVENTS_CREATE', 'EVENTS_EDIT',
        'EVENTS_PUBLISH', 'EVENTS_DELETE', 'EVENTS_EXPORT',
        'CELLS_VIEW', 'CELLS_CREATE', 'CELLS_EDIT', 'CELLS_DELETE',
        'MEETINGS_VIEW', 'MEETINGS_CREATE', 'MEETINGS_EDIT', 'MEETINGS_DELETE',
        'ATTENDANCE_VIEW', 'ATTENDANCE_EDIT',
        'FOLLOWUPS_VIEW', 'FOLLOWUPS_CREATE', 'FOLLOWUPS_EDIT',
        'MEMBERS_REGISTER',
        'REQUESTS_VIEW', 'REQUESTS_ASSIGN', 'REQUESTS_RESPOND', 'REQUESTS_DELETE',
        'NOTIFICATIONS_VIEW', 'NOTIFICATIONS_CREATE', 'NOTIFICATIONS_SEND', 'NOTIFICATIONS_DELETE',
        'USERS_VIEW',
        'MEDIA_VIEW', 'MEDIA_CREATE', 'MEDIA_DELETE',
        'REPORTS_VIEW', 'REPORTS_EXPORT',
        'SETTINGS_VIEW',
    ],
    # Coordinador: supervisa las células que tiene asignadas. Consulta y da
    # seguimiento, y comunica a sus líderes. Sin configuración administrativa.
    'COORDINATOR': [
        'CELLS_VIEW',
        'MEETINGS_VIEW',
        'ATTENDANCE_VIEW',
        'FOLLOWUPS_VIEW', 'FOLLOWUPS_CREATE',
        'NOTIFICATIONS_VIEW', 'NOTIFICATIONS_CREATE',
        'REPORTS_VIEW',
        'EVENTS_VIEW',
    ],
    # Nota: el coordinador NO recibe USERS_VIEW. Ese permiso abre el directorio
    # completo de la iglesia, y su alcance son sólo sus células. A sus líderes y
    # miembros los consulta por /cells/my-cells/ y /cells/<id>/members/, que ya
    # filtran por asignación.
    # Líder: administra su propia célula de principio a fin.
    'CELL_LEADER': [
        'CELLS_VIEW', 'CELLS_EDIT',
        'MEETINGS_VIEW', 'MEETINGS_CREATE', 'MEETINGS_EDIT', 'MEETINGS_DELETE',
        'ATTENDANCE_VIEW', 'ATTENDANCE_EDIT',
        'FOLLOWUPS_VIEW', 'FOLLOWUPS_CREATE', 'FOLLOWUPS_EDIT',
        'MEMBERS_REGISTER',
        'NOTIFICATIONS_VIEW',
        'EVENTS_VIEW',
    ],
    # Miembro: sin permisos administrativos. Su información propia se sirve por
    # /auth/me/ y por los endpoints de alcance SELF.
    'MEMBER': [],
    'VIEWER': [],
}


def apply_hierarchy(apps, schema_editor):
    Role = apps.get_model('roles', 'Role')
    Permission = apps.get_model('roles', 'Permission')
    RolePermission = apps.get_model('roles', 'RolePermission')

    # 1. Crear los permisos nuevos
    for module, actions in NEW_PERMISSIONS.items():
        for action in actions:
            codename = f'{module}_{action}'
            label = f'Permite {ACTION_LABELS[action]} {MODULE_LABELS[module]}'
            Permission.objects.get_or_create(
                codename=codename,
                defaults={'name': label, 'description': label},
            )

    # 2. Crear el rol de coordinador
    Role.objects.get_or_create(
        name='COORDINATOR',
        defaults={'description': 'Coordinador de Células - Supervisa las células que tiene asignadas'},
    )
    Role.objects.filter(name='ADMIN').update(
        description='Pastor / Administrador General - Acceso a toda la iglesia'
    )

    # 3. Reasignar los permisos de cada rol según el diseño
    for role_name, codenames in ROLE_PERMISSIONS.items():
        role = Role.objects.filter(name=role_name).first()
        if role is None:
            continue
        RolePermission.objects.filter(role=role).delete()
        for codename in codenames:
            permission = Permission.objects.filter(codename=codename).first()
            if permission:
                RolePermission.objects.create(role=role, permission=permission)

    # 4. El superadministrador conserva el catálogo completo
    superadmin = Role.objects.filter(name='SUPERADMIN').first()
    if superadmin:
        RolePermission.objects.filter(role=superadmin).delete()
        for permission in Permission.objects.all():
            RolePermission.objects.create(role=superadmin, permission=permission)


def undo(apps, schema_editor):
    Permission = apps.get_model('roles', 'Permission')
    Role = apps.get_model('roles', 'Role')

    codenames = [
        f'{module}_{action}'
        for module, actions in NEW_PERMISSIONS.items()
        for action in actions
    ]
    Permission.objects.filter(codename__in=codenames).delete()
    Role.objects.filter(name='COORDINATOR').delete()


class Migration(migrations.Migration):

    dependencies = [
        ('roles', '0002_initial_roles_permissions'),
    ]

    operations = [
        migrations.RunPython(apply_hierarchy, undo),
    ]
