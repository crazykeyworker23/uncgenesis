import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.cells.models import CellGroup, CellStatus, MeetingDay

User = get_user_model()

LIST_URL = reverse('cells-list')


def detail_url(pk):
    return reverse('cells-detail', args=[pk])


@pytest.fixture
def staff_client(superuser):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    client = APIClient()
    refresh = RefreshToken.for_user(superuser)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def normal_user(create_user):
    return create_user(email='cell_member@genesisapp.org')


@pytest.fixture
def user_client(normal_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    client = APIClient()
    refresh = RefreshToken.for_user(normal_user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def leader_user(create_user):
    return create_user(email='cell_leader@genesisapp.org')


@pytest.fixture
def test_cell(db, leader_user):
    return CellGroup.objects.create(
        name='Células del Norte',
        leader=leader_user,
        meeting_day=MeetingDay.WEDNESDAY,
        meeting_time='19:00:00',
        address='Av. Lima 123, Lima',
        status=CellStatus.ACTIVE,
    )


# --- CRUD Tests ---

class TestCellGroupCRUD:
    def test_list_cells_as_anonymous_succeeds(self, api_client, test_cell):
        """Un usuario anónimo puede listar células."""
        res = api_client.get(LIST_URL)
        assert res.status_code == status.HTTP_200_OK

    def test_list_cells_as_staff(self, staff_client, test_cell):
        """Superusuario puede listar células."""
        res = staff_client.get(LIST_URL)
        assert res.status_code == status.HTTP_200_OK
        assert res.data['count'] >= 1

    def test_create_cell_as_staff(self, staff_client, leader_user):
        """Superusuario puede crear una célula."""
        payload = {
            'name': 'Nueva Célula Sur',
            'leader_id': leader_user.id,
            'meeting_day': MeetingDay.FRIDAY,
            'meeting_time': '18:00:00',
            'address': 'Jr. Miraflores 456, Lima',
            'status': CellStatus.ACTIVE,
        }
        res = staff_client.post(LIST_URL, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        assert CellGroup.objects.filter(name='Nueva Célula Sur').exists()

    def test_create_cell_slug_is_auto_generated(self, staff_client, leader_user):
        """El slug se genera automáticamente desde el nombre."""
        payload = {
            'name': 'Célula Auto Slug',
            'leader_id': leader_user.id,
            'meeting_day': MeetingDay.MONDAY,
            'meeting_time': '20:00:00',
            'address': 'Calle Falsa 123',
        }
        res = staff_client.post(LIST_URL, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        cell = CellGroup.objects.get(id=res.data['id'])
        assert cell.slug == 'celula-auto-slug'

    def test_retrieve_cell(self, staff_client, test_cell):
        """Recuperar detalle de una célula con líder anidado."""
        res = staff_client.get(detail_url(test_cell.pk))
        assert res.status_code == status.HTTP_200_OK
        assert res.data['name'] == test_cell.name
        assert 'leader' in res.data
        assert res.data['leader']['email'] == test_cell.leader.email

    def test_update_cell(self, staff_client, test_cell):
        """Actualizar una célula como superusuario."""
        res = staff_client.patch(detail_url(test_cell.pk), {'address': 'Nueva Dirección 789'}, format='json')
        assert res.status_code == status.HTTP_200_OK
        test_cell.refresh_from_db()
        assert test_cell.address == 'Nueva Dirección 789'

    def test_delete_cell(self, staff_client, test_cell):
        """Eliminar una célula como superusuario."""
        res = staff_client.delete(detail_url(test_cell.pk))
        assert res.status_code == status.HTTP_204_NO_CONTENT
        assert not CellGroup.objects.filter(pk=test_cell.pk).exists()

    def test_list_cells_as_normal_user_succeeds(self, user_client, test_cell):
        """Un usuario sin permiso CELLS_VIEW puede listar células."""
        res = user_client.get(LIST_URL)
        assert res.status_code == status.HTTP_200_OK

    def test_slug_uniqueness_collision_handling(self, staff_client, leader_user):
        """Crear dos células con el mismo nombre genera slugs únicos."""
        for _ in range(2):
            CellGroup.objects.create(
                name='Grupo Fe',
                leader=leader_user,
                meeting_day=MeetingDay.TUESDAY,
                meeting_time='17:00:00',
                address='Calle Test',
            )
        slugs = list(CellGroup.objects.values_list('slug', flat=True))
        assert len(set(slugs)) == len(slugs)

    def test_filter_by_status(self, staff_client, test_cell):
        """Filtrar células por estado ACTIVE."""
        res = staff_client.get(LIST_URL, {'status': 'ACTIVE'})
        assert res.status_code == status.HTTP_200_OK
        results = res.data['results']
        assert all(r['status'] == 'ACTIVE' for r in results)

    def test_search_by_name(self, staff_client, test_cell):
        """Búsqueda por nombre de célula."""
        res = staff_client.get(LIST_URL, {'search': 'Norte'})
        assert res.status_code == status.HTTP_200_OK
        assert any('Norte' in r['name'] for r in res.data['results'])
