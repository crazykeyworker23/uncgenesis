import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.services.models import ChurchService, ServiceVerse, ServiceStatus
from apps.audit.models import AuditLog

User = get_user_model()


@pytest.fixture
def admin_user(superuser):
    return superuser


@pytest.fixture
def staff_client(api_client, superuser):
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(superuser)
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return api_client


@pytest.fixture
def church_service(db):
    return ChurchService.objects.create(
        title="El Poder de la Oración",
        date="2026-07-12",
        video_url="https://youtube.com/watch?v=mockvideo",
        audio_url="https://spotify.com/mockaudio",
        sermon_notes="Puntos clave sobre la fe...",
        status=ServiceStatus.DRAFT,
        is_live=False,
    )


@pytest.fixture
def service_verse(db, church_service):
    return ServiceVerse.objects.create(
        service=church_service,
        book="Santiago",
        chapter=5,
        verses="16",
        text="La oración eficaz del justo puede mucho."
    )


@pytest.mark.django_db
def test_anonymous_read_services(api_client, church_service, service_verse):
    """
    Cualquiera (incluso anónimo) debe poder ver cultos.
    """
    url = reverse('service-list')
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] == 1

    detail_url = reverse('service-detail', kwargs={'pk': church_service.id})
    response = api_client.get(detail_url)
    assert response.status_code == status.HTTP_200_OK
    
    church_service.refresh_from_db()
    assert church_service.views_count == 1


@pytest.mark.django_db
def test_create_service_with_permission(api_client, staff_client):
    """
    Un usuario con permisos SERVICES_CREATE puede registrar cultos.
    """
    url = reverse('service-list')
    data = {
        "title": "Un Nuevo Comienzar",
        "date": "2026-07-19",
        "sermon_notes": "Inicio de serie...",
        "status": "DRAFT",
        "verses": [
            {
                "book": "Génesis",
                "chapter": 1,
                "verses": "1",
                "text": "En el principio creó Dios los cielos y la tierra."
            }
        ]
    }
    
    # Anónimo bloqueado
    from rest_framework.test import APIClient
    anon_client = APIClient()
    response = anon_client.post(url, data, format='json')
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

    # Staff exitoso
    response = staff_client.post(url, data, format='json')
    assert response.status_code == status.HTTP_201_CREATED
    assert ChurchService.objects.filter(title="Un Nuevo Comienzar").exists()
    assert ServiceVerse.objects.filter(book="Génesis").exists()
    
    # Audit log
    assert AuditLog.objects.filter(action="CREATE", module="SERVICES").exists()


@pytest.mark.django_db
def test_publish_and_archive_actions(staff_client, church_service):
    """
    Acciones de publicar y archivar cultos dominicales.
    """
    publish_url = reverse('service-publish', kwargs={'pk': church_service.id})
    archive_url = reverse('service-archive', kwargs={'pk': church_service.id})

    # Publicar
    response = staff_client.post(publish_url)
    assert response.status_code == status.HTTP_200_OK
    church_service.refresh_from_db()
    assert church_service.status == ServiceStatus.PUBLISHED

    # Archivar
    response = staff_client.post(archive_url)
    assert response.status_code == status.HTTP_200_OK
    church_service.refresh_from_db()
    assert church_service.status == ServiceStatus.ARCHIVED


@pytest.mark.django_db
def test_duplicate_service(staff_client, church_service, service_verse):
    """
    Duplicación de cultos y versículos relacionados.
    """
    url = reverse('service-duplicate', kwargs={'pk': church_service.id})
    response = staff_client.post(url)
    assert response.status_code == status.HTTP_201_CREATED
    
    cloned_id = response.data['id']
    cloned = ChurchService.objects.get(id=cloned_id)
    assert cloned.title == f"Copia de {church_service.title}"
    assert cloned.verses.count() == church_service.verses.count()
