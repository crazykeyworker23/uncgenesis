import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.church_requests.models import PrayerRequest, VisitorRequest, RequestStatus

User = get_user_model()

PRAYER_LIST = reverse('prayer-requests-list')
VISITOR_LIST = reverse('visitor-requests-list')


def prayer_detail(pk):
    return reverse('prayer-requests-detail', args=[pk])


def visitor_detail(pk):
    return reverse('visitor-requests-detail', args=[pk])


@pytest.fixture
def staff_client(superuser):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    client = APIClient()
    refresh = RefreshToken.for_user(superuser)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def prayer_payload():
    return {
        'requester_name': 'María López',
        'requester_email': 'maria@example.com',
        'subject': 'Oración por salud',
        'description': 'Pido oración por la recuperación de mi madre.',
        'is_anonymous': False,
    }


@pytest.fixture
def visitor_payload():
    return {
        'full_name': 'Carlos Ríos',
        'email': 'carlos@example.com',
        'phone': '+51999111222',
        'age_range': 'YOUNG_ADULT',
        'how_did_you_find_us': 'SOCIAL_MEDIA',
        'message': 'Deseo conocer más sobre su comunidad.',
        'preferred_contact': 'WHATSAPP',
    }


@pytest.fixture
def test_prayer(db):
    return PrayerRequest.objects.create(
        requester_name='Juan Pérez',
        subject='Oración por trabajo',
        description='Necesito oración urgente.',
    )


@pytest.fixture
def test_visitor(db):
    return VisitorRequest.objects.create(
        full_name='Ana Torres',
        email='ana@example.com',
        how_did_you_find_us='FRIEND_FAMILY',
    )


# ─────────────────────────────────────
# Prayer Request Tests
# ─────────────────────────────────────

@pytest.mark.django_db
class TestPrayerRequest:
    def test_create_prayer_request_public(self, api_client, prayer_payload):
        """Cualquier usuario (sin auth) puede enviar una solicitud de oración."""
        res = api_client.post(PRAYER_LIST, prayer_payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        assert PrayerRequest.objects.filter(subject='Oración por salud').exists()

    def test_create_prayer_anonymous(self, api_client):
        """Solicitud anónima — is_anonymous=True."""
        res = api_client.post(PRAYER_LIST, {
            'requester_name': 'Anónimo',
            'subject': 'Petición privada',
            'description': 'No quiero revelar mi identidad.',
            'is_anonymous': True,
        }, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        obj = PrayerRequest.objects.get(subject='Petición privada')
        assert obj.is_anonymous is True

    def test_list_prayer_requires_auth(self, api_client, test_prayer):
        """Listar solicitudes requiere autenticación."""
        res = api_client.get(PRAYER_LIST)
        assert res.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_prayer_as_staff(self, staff_client, test_prayer):
        """Superusuario puede listar solicitudes."""
        res = staff_client.get(PRAYER_LIST)
        assert res.status_code == status.HTTP_200_OK
        assert res.data['count'] >= 1

    def test_assign_prayer_request(self, staff_client, test_prayer, superuser):
        """Asignar responsable a una solicitud de oración."""
        url = reverse('prayer-requests-assign', args=[test_prayer.pk])
        res = staff_client.post(url, {'assigned_to_id': superuser.id}, format='json')
        assert res.status_code == status.HTTP_200_OK
        test_prayer.refresh_from_db()
        assert test_prayer.assigned_to == superuser

    def test_change_status_prayer_request(self, staff_client, test_prayer):
        """Cambiar estado de solicitud e incluir notas internas."""
        url = reverse('prayer-requests-change-status', args=[test_prayer.pk])
        res = staff_client.post(url, {
            'status': 'IN_PROGRESS',
            'notes': 'Pastor González tomará esta solicitud.',
        }, format='json')
        assert res.status_code == status.HTTP_200_OK
        test_prayer.refresh_from_db()
        assert test_prayer.status == RequestStatus.IN_PROGRESS
        assert 'González' in test_prayer.notes

    def test_filter_prayer_by_status(self, staff_client, test_prayer):
        """Filtrar solicitudes por estado PENDING."""
        res = staff_client.get(PRAYER_LIST, {'status': 'PENDING'})
        assert res.status_code == status.HTTP_200_OK
        assert all(r['status'] == 'PENDING' for r in res.data['results'])

    def test_delete_prayer_request(self, staff_client, test_prayer):
        """Eliminar solicitud como superusuario."""
        res = staff_client.delete(prayer_detail(test_prayer.pk))
        assert res.status_code == status.HTTP_204_NO_CONTENT


# ─────────────────────────────────────
# Visitor Request Tests
# ─────────────────────────────────────

@pytest.mark.django_db
class TestVisitorRequest:
    def test_create_visitor_request_public(self, api_client, visitor_payload):
        """Cualquier usuario (sin auth) puede enviar formulario de visita."""
        res = api_client.post(VISITOR_LIST, visitor_payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        assert VisitorRequest.objects.filter(full_name='Carlos Ríos').exists()

    def test_list_visitor_requires_auth(self, api_client, test_visitor):
        """Listar visitantes requiere autenticación."""
        res = api_client.get(VISITOR_LIST)
        assert res.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_visitor_as_staff(self, staff_client, test_visitor):
        """Superusuario puede listar visitantes."""
        res = staff_client.get(VISITOR_LIST)
        assert res.status_code == status.HTTP_200_OK
        assert res.data['count'] >= 1

    def test_assign_visitor_request(self, staff_client, test_visitor, superuser):
        """Asignar responsable a una solicitud de visita."""
        url = reverse('visitor-requests-assign', args=[test_visitor.pk])
        res = staff_client.post(url, {'assigned_to_id': superuser.id}, format='json')
        assert res.status_code == status.HTTP_200_OK
        test_visitor.refresh_from_db()
        assert test_visitor.assigned_to == superuser

    def test_change_status_visitor_request(self, staff_client, test_visitor):
        """Cambiar estado de solicitud de visita."""
        url = reverse('visitor-requests-change-status', args=[test_visitor.pk])
        res = staff_client.post(url, {'status': 'RESOLVED', 'notes': 'Visitante integrado al grupo.'}, format='json')
        assert res.status_code == status.HTTP_200_OK
        test_visitor.refresh_from_db()
        assert test_visitor.status == RequestStatus.RESOLVED

    def test_search_visitor_by_name(self, staff_client, test_visitor):
        """Búsqueda de visitante por nombre."""
        res = staff_client.get(VISITOR_LIST, {'search': 'Ana'})
        assert res.status_code == status.HTTP_200_OK
        assert any('Ana' in r['full_name'] for r in res.data['results'])
