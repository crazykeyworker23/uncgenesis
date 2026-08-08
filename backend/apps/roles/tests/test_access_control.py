"""
Control de acceso por rol.

Verifica las tres reglas de negocio del sistema:
  1. El superadministrador tiene control total.
  2. Cada rol operativo (líder de célula, editor…) entra al panel con su propio
     alcance, sin ver ni tocar lo que no le corresponde.
  3. El miembro de la comunidad usa sólo la app móvil: no accede al panel.
"""

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.roles.models import Role, RoleType, UserRole
from apps.roles.utils import (
    can_access_admin_panel,
    get_user_permissions,
    is_superadmin,
)

User = get_user_model()

ME_URL = reverse('auth_me')
USERS_LIST = reverse('users-list')


def _client_for(user):
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def role(db):
    def _make(name):
        obj, _ = Role.objects.get_or_create(name=name, defaults={'description': name})
        return obj
    return _make


@pytest.fixture
def user_with_role(db, role):
    def _make(email, role_name=None):
        user = User.objects.create_user(email=email, password='Clave.Solida.2026')
        if role_name:
            UserRole.objects.create(user=user, role=role(role_name))
        return user
    return _make


@pytest.mark.django_db
class TestSuperadminAccess:
    def test_superadmin_role_grants_full_control(self, user_with_role, django_assert_num_queries):
        """
        Asignar el rol SUPERADMIN concede control total, igual que la marca de
        Django. Antes el rol era decorativo si no se marcaba is_superuser.
        """
        user = user_with_role('jefe@genesisapp.org', RoleType.SUPERADMIN)

        assert is_superadmin(user)
        assert can_access_admin_panel(user)

        # Recibe el catalogo completo de permisos, no una lista fija
        from apps.roles.models import Permission
        assert get_user_permissions(user) == set(
            Permission.objects.values_list('codename', flat=True)
        )

    def test_superadmin_flag_grants_full_control(self, db):
        """La marca is_superuser sigue siendo suficiente por si sola."""
        user = User.objects.create_superuser(email='root@genesisapp.org', password='Clave.Solida.2026')

        assert is_superadmin(user)
        assert can_access_admin_panel(user)

    def test_superadmin_can_reset_any_password(self, user_with_role):
        boss = user_with_role('jefe2@genesisapp.org', RoleType.SUPERADMIN)
        target = user_with_role('lider@genesisapp.org', RoleType.CELL_LEADER)

        res = _client_for(boss).post(
            f'{USERS_LIST}{target.id}/set-password/',
            {'password': 'Clave.Nueva.2026'},
            format='json',
        )
        assert res.status_code == status.HTTP_200_OK

        target.refresh_from_db()
        assert target.check_password('Clave.Nueva.2026')

    def test_last_superadmin_cannot_be_deleted(self, user_with_role):
        """El sistema nunca debe quedarse sin control total."""
        boss = user_with_role('unico@genesisapp.org', RoleType.SUPERADMIN)
        other = user_with_role('otro@genesisapp.org', RoleType.SUPERADMIN)

        client = _client_for(boss)

        # Con dos superadministradores, borrar a uno es valido
        assert client.delete(f'{USERS_LIST}{other.id}/').status_code == status.HTTP_204_NO_CONTENT

        # El que queda no puede eliminarse a si mismo
        res = client.delete(f'{USERS_LIST}{boss.id}/')
        assert res.status_code == status.HTTP_400_BAD_REQUEST
        assert User.objects.filter(id=boss.id).exists()


@pytest.mark.django_db
class TestRoleScopedAccess:
    def test_cell_leader_enters_panel_with_limited_scope(self, user_with_role):
        """El lider de celula entra al panel, pero con su propio alcance."""
        leader = user_with_role('lider2@genesisapp.org', RoleType.CELL_LEADER)

        assert can_access_admin_panel(leader)
        assert not is_superadmin(leader)

        permissions = get_user_permissions(leader)
        assert 'CELLS_VIEW' in permissions
        # No administra cuentas ni roles del sistema
        assert 'USERS_EDIT' not in permissions
        assert 'ROLES_EDIT' not in permissions

    def test_cell_leader_cannot_manage_users(self, user_with_role):
        leader = user_with_role('lider3@genesisapp.org', RoleType.CELL_LEADER)
        victim = user_with_role('victima@genesisapp.org', RoleType.MEMBER)

        client = _client_for(leader)

        assert client.get(USERS_LIST).status_code == status.HTTP_403_FORBIDDEN
        assert client.post(
            f'{USERS_LIST}{victim.id}/set-password/',
            {'password': 'Intento.Fallido.2026'},
            format='json',
        ).status_code == status.HTTP_403_FORBIDDEN

    def test_content_editor_scope(self, user_with_role):
        editor = user_with_role('editor@genesisapp.org', RoleType.CONTENT_EDITOR)
        permissions = get_user_permissions(editor)

        assert can_access_admin_panel(editor)
        assert 'PUBLICATIONS_EDIT' in permissions
        assert 'DEVOTIONALS_PUBLISH' in permissions
        assert 'USERS_EDIT' not in permissions

    def test_non_superadmin_cannot_touch_a_superadmin(self, user_with_role, role):
        """Un administrador comun no puede intervenir al superadministrador."""
        boss = user_with_role('jefe3@genesisapp.org', RoleType.SUPERADMIN)
        admin = user_with_role('admin_comun@genesisapp.org', RoleType.ADMIN)

        res = _client_for(admin).post(
            f'{USERS_LIST}{boss.id}/set-password/',
            {'password': 'Secuestro.2026'},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN

        boss.refresh_from_db()
        assert not boss.check_password('Secuestro.2026')

    def test_only_superadmin_grants_the_superadmin_role(self, user_with_role):
        admin = user_with_role('admin_comun2@genesisapp.org', RoleType.ADMIN)
        target = user_with_role('aspirante@genesisapp.org', RoleType.MEMBER)

        res = _client_for(admin).patch(
            f'{USERS_LIST}{target.id}/',
            {'assigned_roles': [RoleType.SUPERADMIN]},
            format='json',
        )
        # 403 porque el pastor no administra cuentas (gestionar usuarios, roles
        # y permisos es del superadministrador); 400 si algún rol llegara a
        # tener USERS_EDIT y fuera el serializer quien lo rechazara.
        assert res.status_code in (
            status.HTTP_403_FORBIDDEN,
            status.HTTP_400_BAD_REQUEST,
        )

        target.refresh_from_db()
        assert not is_superadmin(target)

    def test_assigning_superadmin_role_syncs_django_flags(self, user_with_role):
        """El rol y las marcas de Django deben significar lo mismo."""
        boss = user_with_role('jefe4@genesisapp.org', RoleType.SUPERADMIN)
        target = user_with_role('promovido@genesisapp.org', RoleType.MEMBER)

        res = _client_for(boss).patch(
            f'{USERS_LIST}{target.id}/',
            {'assigned_roles': [RoleType.SUPERADMIN]},
            format='json',
        )
        assert res.status_code == status.HTTP_200_OK

        target.refresh_from_db()
        assert target.is_superuser is True
        assert is_superadmin(target)


@pytest.mark.django_db
class TestCommunityMemberIsAppOnly:
    def test_member_cannot_access_admin_panel(self, user_with_role):
        """El miembro de la comunidad usa unicamente el aplicativo movil."""
        member = user_with_role('miembro@genesisapp.org', RoleType.MEMBER)

        assert not can_access_admin_panel(member)
        assert get_user_permissions(member) == set() or 'USERS_VIEW' not in get_user_permissions(member)

    def test_user_without_roles_cannot_access_admin_panel(self, user_with_role):
        anyone = user_with_role('sin_rol@genesisapp.org')
        assert not can_access_admin_panel(anyone)

    def test_me_endpoint_reports_the_scope(self, user_with_role):
        """El panel decide que mostrar a partir de /auth/me/."""
        member = user_with_role('miembro2@genesisapp.org', RoleType.MEMBER)

        res = _client_for(member).get(ME_URL)
        assert res.status_code == status.HTTP_200_OK
        assert res.data['can_access_admin'] is False
        assert res.data['is_superadmin'] is False
        assert res.data['roles'] == [RoleType.MEMBER]

    def test_me_endpoint_for_superadmin(self, user_with_role):
        boss = user_with_role('jefe5@genesisapp.org', RoleType.SUPERADMIN)

        res = _client_for(boss).get(ME_URL)
        assert res.status_code == status.HTTP_200_OK
        assert res.data['can_access_admin'] is True
        assert res.data['is_superadmin'] is True
        assert 'USERS_EDIT' in res.data['permissions']

    def test_blocked_account_loses_panel_access(self, user_with_role):
        from apps.users.models import UserStatus

        editor = user_with_role('editor2@genesisapp.org', RoleType.CONTENT_EDITOR)
        assert can_access_admin_panel(editor)

        editor.status = UserStatus.BLOCKED
        editor.save()
        editor.refresh_from_db()

        assert not can_access_admin_panel(editor)
