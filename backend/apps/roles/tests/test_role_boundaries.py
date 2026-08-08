"""
Auditoría de fronteras entre roles.

Recorre los endpoints administrativos con cada rol y comprueba que nadie
alcance lo que no le corresponde. Sirve como red de seguridad: si mañana se
agrega un endpoint sin permiso, estas pruebas lo delatan.
"""

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.cells.models import CellGroup, MeetingDay
from apps.roles.models import Role, RoleType, UserRole

User = get_user_model()


def _client_for(user):
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def make_user(db):
    def _make(email, role_name=None):
        user = User.objects.create_user(email=email, password='Clave.Solida.2026')
        if role_name:
            role, _ = Role.objects.get_or_create(name=role_name, defaults={'description': role_name})
            UserRole.objects.create(user=user, role=role)
        return user
    return _make


@pytest.fixture
def member(make_user):
    """Miembro de la comunidad: usa la app móvil, no administra nada."""
    return make_user('miembro.audit@genesisapp.org', RoleType.MEMBER)


@pytest.fixture
def leader(make_user):
    return make_user('lider.audit@genesisapp.org', RoleType.CELL_LEADER)


@pytest.fixture
def editor(make_user):
    return make_user('editor.audit@genesisapp.org', RoleType.CONTENT_EDITOR)


@pytest.fixture
def support(make_user):
    return make_user('soporte.audit@genesisapp.org', RoleType.SUPPORT)


@pytest.fixture
def cell(db):
    return CellGroup.objects.create(
        name='Célula Auditoría',
        meeting_day=MeetingDay.FRIDAY,
        meeting_time='20:00',
        address='Calle Falsa 123',
    )


# Endpoints de escritura que ningún rol operativo debería alcanzar sin su
# permiso correspondiente. (nombre de ruta, método, cuerpo)
ADMIN_WRITE_ENDPOINTS = [
    ('users-list', 'post', {'email': 'colado@genesisapp.org', 'password': 'Colado.2026.Seguro'}),
    ('roles-list', 'post', {'name': RoleType.ADMIN}),
    ('publication-list', 'post', {'title': 'Colada', 'content': 'x'}),
    ('devotional-list', 'post', {'title': 'Colado', 'content': 'x'}),
    ('event-list', 'post', {'title': 'Colado', 'description': 'x'}),
    ('service-list', 'post', {'title': 'Colado'}),
    ('cells-list', 'post', {'name': 'Colada'}),
    ('notifications-list', 'post', {'title': 'Colada', 'body': 'x'}),
    ('multimedia-list', 'post', {'title': 'Colada'}),
]

# Endpoints de lectura reservados a la administración.
ADMIN_READ_ENDPOINTS = [
    'users-list',
    'roles-list',
    'permissions-list',
    'prayer-requests-list',
    'visitor-requests-list',
    'multimedia-list',
    'audit_log_list',
]


@pytest.mark.django_db
class TestCommunityMemberIsLockedOut:
    """El miembro sólo consume contenido público desde la app."""

    @pytest.mark.parametrize('route,method,payload', ADMIN_WRITE_ENDPOINTS)
    def test_member_cannot_write_anything_administrative(self, member, route, method, payload):
        client = _client_for(member)
        res = getattr(client, method)(reverse(route), payload, format='json')
        assert res.status_code in (
            status.HTTP_401_UNAUTHORIZED,
            status.HTTP_403_FORBIDDEN,
        ), f"{route} quedó accesible para un miembro ({res.status_code})"

    @pytest.mark.parametrize('route', ADMIN_READ_ENDPOINTS)
    def test_member_cannot_read_administrative_lists(self, member, route):
        res = _client_for(member).get(reverse(route))
        assert res.status_code == status.HTTP_403_FORBIDDEN, (
            f"{route} quedó legible para un miembro ({res.status_code})"
        )

    def test_member_cannot_read_dashboard_statistics(self, member):
        """Las cifras de la iglesia son información administrativa."""
        res = _client_for(member).get(reverse('reports-dashboard'))
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_member_keeps_access_to_public_content(self, member):
        """Lo que sí le corresponde sigue funcionando."""
        client = _client_for(member)
        for route in ['publication-list', 'devotional-list', 'event-list', 'cells-list']:
            assert client.get(reverse(route)).status_code == status.HTTP_200_OK


@pytest.mark.django_db
class TestCellLeaderStaysInItsLane:
    """El líder gestiona su célula, no el resto del sistema."""

    @pytest.mark.parametrize('route,method,payload', ADMIN_WRITE_ENDPOINTS)
    def test_leader_cannot_write_outside_its_scope(self, leader, route, method, payload):
        client = _client_for(leader)
        res = getattr(client, method)(reverse(route), payload, format='json')
        assert res.status_code in (
            status.HTTP_401_UNAUTHORIZED,
            status.HTTP_403_FORBIDDEN,
        ), f"{route} quedó accesible para un líder ({res.status_code})"

    def test_leader_cannot_manage_users_or_roles(self, leader):
        client = _client_for(leader)
        assert client.get(reverse('users-list')).status_code == status.HTTP_403_FORBIDDEN
        assert client.get(reverse('roles-list')).status_code == status.HTTP_403_FORBIDDEN

    def test_leader_cannot_read_prayer_requests(self, leader):
        """Las peticiones de oración son de consejería, no del líder."""
        res = _client_for(leader).get(reverse('prayer-requests-list'))
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_leader_cannot_delete_a_cell(self, leader, cell):
        """Puede editar la suya, pero crear o eliminar células es del admin."""
        cell.leader = leader
        cell.save()
        res = _client_for(leader).delete(reverse('cells-detail', args=[cell.id]))
        assert res.status_code == status.HTTP_403_FORBIDDEN
        assert CellGroup.objects.filter(id=cell.id).exists()


@pytest.mark.django_db
class TestContentEditorStaysInContent:
    """El editor publica contenido; no toca personas ni configuración."""

    def test_editor_can_manage_content(self, editor):
        res = _client_for(editor).post(
            reverse('publication-list'),
            {'title': 'Nota del editor', 'content': 'Contenido', 'summary': 'Resumen'},
            format='json',
        )
        assert res.status_code == status.HTTP_201_CREATED

    def test_editor_cannot_manage_users_or_roles(self, editor):
        client = _client_for(editor)
        assert client.get(reverse('users-list')).status_code == status.HTTP_403_FORBIDDEN
        assert client.post(
            reverse('users-list'),
            {'email': 'x@genesisapp.org', 'password': 'Clave.Solida.2026'},
            format='json',
        ).status_code == status.HTTP_403_FORBIDDEN
        assert client.get(reverse('roles-list')).status_code == status.HTTP_403_FORBIDDEN

    def test_editor_cannot_send_notifications(self, editor):
        res = _client_for(editor).post(
            reverse('notifications-list'),
            {'title': 'Aviso', 'body': 'x', 'target_audience': 'ALL'},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_editor_cannot_change_church_settings(self, editor):
        res = _client_for(editor).get(reverse('audit_log_list'))
        assert res.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestSupportStaysInRequests:
    """Soporte atiende solicitudes; no publica ni administra."""

    def test_support_reads_requests(self, support):
        client = _client_for(support)
        assert client.get(reverse('prayer-requests-list')).status_code == status.HTTP_200_OK
        assert client.get(reverse('visitor-requests-list')).status_code == status.HTTP_200_OK

    def test_support_cannot_publish_content(self, support):
        client = _client_for(support)
        assert client.post(
            reverse('publication-list'), {'title': 'x', 'content': 'y'}, format='json'
        ).status_code == status.HTTP_403_FORBIDDEN
        assert client.post(
            reverse('devotional-list'), {'title': 'x', 'content': 'y'}, format='json'
        ).status_code == status.HTTP_403_FORBIDDEN

    def test_support_cannot_manage_users(self, support):
        assert _client_for(support).get(reverse('users-list')).status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestSuperadminReachesEverything:
    def test_superadmin_passes_every_administrative_read(self, make_user):
        boss = make_user('jefe.audit@genesisapp.org', RoleType.SUPERADMIN)
        client = _client_for(boss)

        for route in ADMIN_READ_ENDPOINTS + ['reports-dashboard']:
            res = client.get(reverse(route))
            assert res.status_code == status.HTTP_200_OK, (
                f"El superadministrador fue bloqueado en {route} ({res.status_code})"
            )
