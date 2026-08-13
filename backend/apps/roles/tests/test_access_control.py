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
    def test_cell_leader_works_from_the_app_not_the_panel(self, user_with_role):
        """
        El lider de celula no entra al panel: su sitio es la aplicacion movil.

        Conserva los permisos que necesita para gestionar su grupo —y los
        ejerce desde la app, que es donde tiene su seccion—, pero el panel
        completo de la iglesia no le corresponde.
        """
        leader = user_with_role('lider2@genesisapp.org', RoleType.CELL_LEADER)

        assert not can_access_admin_panel(leader)
        assert not is_superadmin(leader)

        permissions = get_user_permissions(leader)
        assert 'CELLS_VIEW' in permissions
        assert 'MEETINGS_CREATE' in permissions
        # No administra cuentas ni roles del sistema
        assert 'USERS_EDIT' not in permissions
        assert 'ROLES_EDIT' not in permissions

    def test_coordinator_also_works_from_the_app(self, user_with_role):
        """El coordinador supervisa sus celulas desde la app, no desde el panel."""
        coordinator = user_with_role('coord@genesisapp.org', RoleType.COORDINATOR)

        assert not can_access_admin_panel(coordinator)

    def test_pastor_and_office_roles_keep_the_panel(self, user_with_role):
        """
        Quien administra la iglesia o produce contenido si entra.

        El editor y el consejero se quedan porque su trabajo no existe en
        ningun otro sitio: sin panel, nadie publicaria un devocional ni
        atenderia una peticion de oracion.
        """
        for email, role in [
            ('pastor@genesisapp.org', RoleType.ADMIN),
            ('editora@genesisapp.org', RoleType.CONTENT_EDITOR),
            ('consejero@genesisapp.org', RoleType.SUPPORT),
        ]:
            assert can_access_admin_panel(user_with_role(email, role)), role

    def test_leading_a_cell_does_not_reopen_the_panel(self, user_with_role):
        """
        Ni el rol ni la responsabilidad sobre un grupo abren el panel.

        Antes bastaba con tener cualquier permiso del catalogo, y el lider los
        tiene: la puerta se le abria sola.
        """
        editor_and_leader = user_with_role('mixta@genesisapp.org', RoleType.CELL_LEADER)
        assert not can_access_admin_panel(editor_and_leader)

        # Acumular el rol de editor si le da acceso, por el editor, no por el
        # liderazgo.
        from apps.roles.models import Role, UserRole

        role, _ = Role.objects.get_or_create(name=RoleType.CONTENT_EDITOR)
        UserRole.objects.get_or_create(user=editor_and_leader, role=role)
        assert can_access_admin_panel(editor_and_leader)

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
class TestPanelDashboardsHaveData:
    """
    Cada rol del panel entra a un tablero con datos suyos.

    Antes todos aterrizaban en el mismo, el de la iglesia, cuyas cifras exigen
    REPORTS_VIEW. El editor de contenidos y el de consejeria veian una
    pantalla de bienvenida y nada mas: hasta el bloque de solicitudes sacaba
    sus datos del informe general que el servidor les niega.

    Aqui se comprueba que lo que cada tablero pide es justo lo que su rol
    puede leer.
    """

    def test_consejeria_lee_las_solicitudes_de_su_tablero(self, user_with_role):
        soporte = user_with_role('consejero.panel@genesisapp.org', RoleType.SUPPORT)
        client = _client_for(soporte)

        for nombre in ['prayer-requests-list', 'visitor-requests-list']:
            res = client.get(reverse(nombre), {'status': 'PENDING'})
            assert res.status_code == status.HTTP_200_OK, nombre
            assert 'count' in res.data, nombre

    def test_consejeria_sigue_sin_los_informes_de_la_iglesia(self, user_with_role):
        """Su tablero no los pide, y aunque los pidiera no los tendria."""
        soporte = user_with_role('consejero.panel2@genesisapp.org', RoleType.SUPPORT)

        res = _client_for(soporte).get(reverse('reports-dashboard'))
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_el_editor_lee_los_borradores_de_su_tablero(self, user_with_role):
        editor = user_with_role('editor.panel@genesisapp.org', RoleType.CONTENT_EDITOR)
        client = _client_for(editor)

        for nombre in ['publication-list', 'devotional-list', 'service-list', 'event-list']:
            res = client.get(reverse(nombre), {'status': 'DRAFT'})
            assert res.status_code == status.HTTP_200_OK, nombre
            assert 'count' in res.data, nombre

    def test_el_editor_ve_los_borradores_y_el_publico_no(self, user_with_role, db):
        """
        El tablero cuenta borradores, asi que el editor tiene que verlos.

        Lo contrario tambien importa: siguen fuera del alcance publico.
        """
        from apps.publications.models import Publication, PublicationStatus

        editor = user_with_role('editor.panel2@genesisapp.org', RoleType.CONTENT_EDITOR)
        Publication.objects.create(
            title='Sin publicar', slug='sin-publicar', content='x',
            status=PublicationStatus.DRAFT, author=editor,
        )

        del_editor = _client_for(editor).get(reverse('publication-list'), {'status': 'DRAFT'})
        assert del_editor.data['count'] == 1

        from rest_framework.test import APIClient
        publico = APIClient().get(reverse('publication-list'), {'status': 'DRAFT'})
        assert publico.data['count'] == 0

    def test_el_pastor_conserva_su_tablero_completo(self, user_with_role):
        pastor = user_with_role('pastor.panel@genesisapp.org', RoleType.ADMIN)

        res = _client_for(pastor).get(reverse('reports-dashboard'))
        assert res.status_code == status.HTTP_200_OK
        assert 'kpis' in res.data


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
