import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.events.models import Event, EventRegistration, EventRegistrationStatus, EventStatus
from apps.audit.models import AuditLog

User = get_user_model()


@pytest.fixture
def admin_user(superuser):
    return superuser


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
    return create_user(email="normal_member@genesisapp.org")


@pytest.fixture
def user_client(normal_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    client = APIClient()
    refresh = RefreshToken.for_user(normal_user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def test_event(db):
    return Event.objects.create(
        title="Taller de Matrimonios",
        description="Capacitación integral para parejas.",
        start_date=timezone.now() + timezone.timedelta(days=2),
        end_date=timezone.now() + timezone.timedelta(days=2, hours=3),
        location="Auditorio Central Génesis",
        capacity=2, # Aforo máximo de 2 para probar límites
        requires_registration=True,
        status=EventStatus.DRAFT
    )


@pytest.mark.django_db
def test_anonymous_read_events(api_client, test_event):
    """
    Cualquiera (anónimo) puede listar y ver detalles del evento.
    """
    url = reverse('event-list')
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] == 1

    detail_url = reverse('event-detail', kwargs={'pk': test_event.id})
    response = api_client.get(detail_url)
    assert response.status_code == status.HTTP_200_OK


@pytest.mark.django_db
def test_create_event_with_permission(api_client, staff_client):
    """
    Staff con permisos puede registrar un evento sin slug inicial.
    """
    url = reverse('event-list')
    data = {
        "title": "Conferencia de Liderazgo",
        "description": "Formación de pastores...",
        "start_date": str(timezone.now() + timezone.timedelta(days=5)),
        "end_date": str(timezone.now() + timezone.timedelta(days=5, hours=4)),
        "location": "Plaza Génesis",
        "status": "DRAFT"
    }

    # Anónimo bloqueado
    from rest_framework.test import APIClient
    anon_client = APIClient()
    response = anon_client.post(url, data, format='json')
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

    # Staff exitoso
    response = staff_client.post(url, data, format='json')
    assert response.status_code == status.HTTP_201_CREATED
    assert Event.objects.filter(title="Conferencia de Liderazgo").exists()


@pytest.mark.django_db
def test_event_registration_transaction(user_client, test_event, create_user):
    """
    Inscripción a eventos controlando aforo.
    """
    # Cambiar a publicado para permitir inscripciones
    test_event.status = EventStatus.PUBLISHED
    test_event.save()

    url = reverse('event-register', kwargs={'pk': test_event.id})
    
    # 1. Primera inscripción (exitosa)
    response = user_client.post(url)
    assert response.status_code == status.HTTP_201_CREATED
    
    # 2. Inscribir otra vez al mismo usuario (bloqueado)
    response = user_client.post(url)
    assert response.status_code == status.HTTP_400_BAD_REQUEST

    # 3. Inscribir segundo usuario (aforo = 2, exitoso)
    user2 = create_user(email="user2@genesisapp.org")
    from rest_framework_simplejwt.tokens import RefreshToken
    from rest_framework.test import APIClient
    client2 = APIClient()
    refresh2 = RefreshToken.for_user(user2)
    client2.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh2.access_token}')
    
    response = client2.post(url)
    assert response.status_code == status.HTTP_201_CREATED

    # 4. Inscribir tercer usuario (aforo superado -> bloqueado)
    user3 = create_user(email="user3@genesisapp.org")
    client3 = APIClient()
    refresh3 = RefreshToken.for_user(user3)
    client3.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh3.access_token}')
    
    response = client3.post(url)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "Aforo completo" in response.data['detail']


@pytest.mark.django_db
def test_attendees_list_admin_only(api_client, user_client, staff_client, test_event):
    """
    Sólo administradores/staff pueden consultar la lista de inscriptos.
    """
    url = reverse('event-attendees', kwargs={'pk': test_event.id})

    # Anónimo bloqueado
    response = api_client.get(url)
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

    # Usuario normal bloqueado
    response = user_client.get(url)
    assert response.status_code == status.HTTP_403_FORBIDDEN

    # Staff exitoso
    response = staff_client.get(url)
    assert response.status_code == status.HTTP_200_OK
