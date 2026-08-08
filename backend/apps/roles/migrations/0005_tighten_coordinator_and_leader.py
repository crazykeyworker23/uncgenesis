from django.db import migrations


# Permisos que se retiran porque otorgaban alcance de administrador a roles
# cuyo ámbito son sus propias células.
REVOKE = {
    'COORDINATOR': [
        # Permitía crear notificaciones con audiencia ALL, es decir difundir a
        # toda la iglesia. Su función es comunicar a sus líderes, y para eso
        # usa /cells/<id>/send-reminder/, que se autoriza por asignación.
        'NOTIFICATIONS_CREATE',
        # Daba acceso a los reportes generales de la iglesia. Los indicadores
        # que le corresponden son los de sus células, en /cells/<id>/statistics/,
        # también autorizados por asignación.
        'REPORTS_VIEW',
    ],
    'CELL_LEADER': [
        # No hace falta: editar la célula propia se autoriza por
        # responsabilidad en CellGroupViewSet.check_permissions. Conservarlo
        # sólo servía para mostrarle la administración de células de la
        # iglesia, que no le corresponde.
        'CELLS_EDIT',
    ],
}


def tighten(apps, schema_editor):
    Role = apps.get_model('roles', 'Role')
    RolePermission = apps.get_model('roles', 'RolePermission')

    for role_name, codenames in REVOKE.items():
        role = Role.objects.filter(name=role_name).first()
        if role is None:
            continue
        RolePermission.objects.filter(
            role=role, permission__codename__in=codenames
        ).delete()


def restore(apps, schema_editor):
    Role = apps.get_model('roles', 'Role')
    Permission = apps.get_model('roles', 'Permission')
    RolePermission = apps.get_model('roles', 'RolePermission')

    for role_name, codenames in REVOKE.items():
        role = Role.objects.filter(name=role_name).first()
        if role is None:
            continue
        for codename in codenames:
            permission = Permission.objects.filter(codename=codename).first()
            if permission:
                RolePermission.objects.get_or_create(role=role, permission=permission)


class Migration(migrations.Migration):

    dependencies = [
        ('roles', '0004_alter_role_name'),
    ]

    operations = [
        migrations.RunPython(tighten, restore),
    ]
