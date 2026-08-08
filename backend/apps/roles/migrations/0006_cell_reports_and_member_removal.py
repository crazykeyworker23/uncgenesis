from django.db import migrations


NEW_PERMISSIONS = {
    'CELL_REPORTS_VIEW': 'Permite consultar informes de célula',
    'CELL_REPORTS_CREATE': 'Permite redactar y enviar informes de célula',
    'CELL_REPORTS_REVIEW': 'Permite revisar y responder informes de célula',
    # Retirar a alguien de la célula no es eliminarlo del sistema: conserva su
    # cuenta y su historial. El borrado definitivo sigue en USERS_EDIT.
    'MEMBERS_REMOVE': 'Permite retirar integrantes de la célula',
}

GRANTS = {
    # El líder informa de su célula y gestiona quién la compone.
    'CELL_LEADER': ['CELL_REPORTS_VIEW', 'CELL_REPORTS_CREATE', 'MEMBERS_REMOVE'],
    # El coordinador recibe los informes de sus células y los responde.
    'COORDINATOR': ['CELL_REPORTS_VIEW', 'CELL_REPORTS_REVIEW'],
    # El pastorado ve y responde los de toda la iglesia, y también compone.
    'ADMIN': [
        'CELL_REPORTS_VIEW', 'CELL_REPORTS_CREATE', 'CELL_REPORTS_REVIEW',
        'MEMBERS_REMOVE',
    ],
    'SUPERADMIN': list(NEW_PERMISSIONS.keys()),
}


def grant(apps, schema_editor):
    Role = apps.get_model('roles', 'Role')
    Permission = apps.get_model('roles', 'Permission')
    RolePermission = apps.get_model('roles', 'RolePermission')

    for codename, label in NEW_PERMISSIONS.items():
        Permission.objects.get_or_create(
            codename=codename,
            defaults={'name': label, 'description': label},
        )

    for role_name, codenames in GRANTS.items():
        role = Role.objects.filter(name=role_name).first()
        if role is None:
            continue
        for codename in codenames:
            permission = Permission.objects.filter(codename=codename).first()
            if permission:
                RolePermission.objects.get_or_create(role=role, permission=permission)


def revoke(apps, schema_editor):
    Permission = apps.get_model('roles', 'Permission')
    Permission.objects.filter(codename__in=list(NEW_PERMISSIONS.keys())).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('roles', '0005_tighten_coordinator_and_leader'),
    ]

    operations = [
        migrations.RunPython(grant, revoke),
    ]
