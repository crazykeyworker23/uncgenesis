from django.db import migrations


def populate_roles_and_permissions(apps, schema_editor):
    Role = apps.get_model('roles', 'Role')
    Permission = apps.get_model('roles', 'Permission')
    RolePermission = apps.get_model('roles', 'RolePermission')

    # 1. Definición de permisos por módulo y acción
    permissions_data = []
    
    modules = {
        'PUBLICATIONS': ['VIEW', 'CREATE', 'EDIT', 'PUBLISH', 'DELETE', 'EXPORT'],
        'SERVICES': ['VIEW', 'CREATE', 'EDIT', 'PUBLISH', 'DELETE', 'EXPORT'],
        'DEVOTIONALS': ['VIEW', 'CREATE', 'EDIT', 'PUBLISH', 'DELETE', 'EXPORT'],
        'EVENTS': ['VIEW', 'CREATE', 'EDIT', 'PUBLISH', 'DELETE', 'EXPORT'],
        'CELLS': ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
        'REQUESTS': ['VIEW', 'CREATE', 'ASSIGN', 'RESPOND', 'DELETE'],
        'NOTIFICATIONS': ['VIEW', 'CREATE', 'SEND', 'DELETE'],
        'USERS': ['VIEW', 'EDIT', 'BLOCK'],
        'ROLES': ['VIEW', 'EDIT'],
        'MEDIA': ['VIEW', 'CREATE', 'DELETE'],
        'REPORTS': ['VIEW', 'EXPORT'],
        'SETTINGS': ['VIEW', 'EDIT'],
    }

    # Crear permisos
    created_permissions = {}
    for module, actions in modules.items():
        for action in actions:
            codename = f"{module}_{action}"
            name = f"Permite {action.lower()} en {module.lower()}"
            perm = Permission.objects.create(codename=codename, name=name, description=name)
            created_permissions[codename] = perm

    # 2. Definición de Roles
    roles_definition = {
        'SUPERADMIN': {
            'desc': 'Super Administrador - Acceso y control total',
            'perms': list(created_permissions.keys()) # Todos los permisos
        },
        'ADMIN': {
            'desc': 'Administrador - Gestión operativa y de contenido',
            'perms': list(created_permissions.keys()) # Todos los permisos por defecto
        },
        'CONTENT_EDITOR': {
            'desc': 'Editor de Contenidos - Redacción de publicaciones, devocionales y servicios',
            'perms': [
                'PUBLICATIONS_VIEW', 'PUBLICATIONS_CREATE', 'PUBLICATIONS_EDIT', 'PUBLICATIONS_PUBLISH', 'PUBLICATIONS_DELETE',
                'SERVICES_VIEW', 'SERVICES_CREATE', 'SERVICES_EDIT', 'SERVICES_PUBLISH', 'SERVICES_DELETE',
                'DEVOTIONALS_VIEW', 'DEVOTIONALS_CREATE', 'DEVOTIONALS_EDIT', 'DEVOTIONALS_PUBLISH', 'DEVOTIONALS_DELETE',
                'EVENTS_VIEW', 'EVENTS_CREATE', 'EVENTS_EDIT', 'EVENTS_PUBLISH', 'EVENTS_DELETE',
                'CELLS_VIEW',
                'MEDIA_VIEW', 'MEDIA_CREATE', 'MEDIA_DELETE'
            ]
        },
        'CELL_LEADER': {
            'desc': 'Líder de Célula - Administra su propio grupo celular',
            'perms': [
                'CELLS_VIEW'
            ]
        },
        'SUPPORT': {
            'desc': 'Soporte y Consejería - Atiende solicitudes de consejería y oración',
            'perms': [
                'REQUESTS_VIEW', 'REQUESTS_RESPOND'
            ]
        },
        'MEMBER': {
            'desc': 'Miembro de la comunidad registrado',
            'perms': [] # Sin permisos administrativos
        },
        'VIEWER': {
            'desc': 'Invitado público no registrado',
            'perms': [] # Sin permisos administrativos
        }
    }

    # Crear roles y asociar permisos
    for role_name, role_info in roles_definition.items():
        role = Role.objects.create(name=role_name, description=role_info['desc'])
        for codename in role_info['perms']:
            permission = created_permissions[codename]
            RolePermission.objects.create(role=role, permission=permission)


def rollback_roles_and_permissions(apps, schema_editor):
    Role = apps.get_model('roles', 'Role')
    Permission = apps.get_model('roles', 'Permission')
    RolePermission = apps.get_model('roles', 'RolePermission')

    RolePermission.objects.all().delete()
    Role.objects.all().delete()
    Permission.objects.all().delete()


class Migration(migrations.Migration):

    dependencies = [
        ('roles', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(populate_roles_and_permissions, rollback_roles_and_permissions),
    ]
