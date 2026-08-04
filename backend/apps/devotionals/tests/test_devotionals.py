import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.devotionals.models import Devotional, DevotionalStatus
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
def devotional(db, admin_user):
    return Devotional.objects.create(
        title="Buscando la Presencia de Dios",
        date=timezone.localdate(),
        bible_passage="Salmos 27:8",
        bible_text="Tu rostro buscaré, oh Jehová.",
        content="Reflexión diaria sobre la oración...",
        audio_url="https://spotify.com/mockaudio",
        author=admin_user,
        status=DevotionalStatus.DRAFT,
    )


@pytest.mark.django_db
def test_anonymous_read_devotionals(api_client, devotional):
    """
    Cualquiera (anónimo) debe poder ver los devocionales publicados, nunca los
    borradores.
    """
    url = reverse('devotional-list')
    detail_url = reverse('devotional-detail', kwargs={'pk': devotional.id})

    # En borrador no debe ser visible públicamente
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] == 0
    assert api_client.get(detail_url).status_code == status.HTTP_404_NOT_FOUND

    # Una vez publicado sí
    devotional.status = DevotionalStatus.PUBLISHED
    devotional.save()

    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] == 1

    response = api_client.get(detail_url)
    assert response.status_code == status.HTTP_200_OK

    devotional.refresh_from_db()
    assert devotional.views_count == 1


@pytest.mark.django_db
def test_create_devotional_with_permission(api_client, staff_client):
    """
    Un usuario con permisos DEVOTIONALS_CREATE puede registrar devocionales.
    """
    url = reverse('devotional-list')
    # Sumar un día para evitar choque de fecha única si ya hay uno hoy
    tomorrow = timezone.localdate() + timezone.timedelta(days=1)
    
    data = {
        "title": "Caminando en Amor",
        "date": str(tomorrow),
        "bible_passage": "Efesios 5:2",
        "bible_text": "Y andad en amor...",
        "content": "Estudio diario...",
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
    assert Devotional.objects.filter(title="Caminando en Amor").exists()
    
    # Audit log
    assert AuditLog.objects.filter(action="CREATE", module="DEVOTIONALS").exists()


@pytest.mark.django_db
def test_publish_and_archive_actions(staff_client, devotional):
    """
    Acciones de publicar y archivar devocionales.
    """
    publish_url = reverse('devotional-publish', kwargs={'pk': devotional.id})
    archive_url = reverse('devotional-archive', kwargs={'pk': devotional.id})

    # Publicar
    response = staff_client.post(publish_url)
    assert response.status_code == status.HTTP_200_OK
    devotional.refresh_from_db()
    assert devotional.status == DevotionalStatus.PUBLISHED

    # Archivar
    response = staff_client.post(archive_url)
    assert response.status_code == status.HTTP_200_OK
    devotional.refresh_from_db()
    assert devotional.status == DevotionalStatus.ARCHIVED


@pytest.mark.django_db
def test_today_devotional_endpoint(api_client, devotional):
    """
    Verifica el endpoint de devocional de hoy y fallback.
    """
    url = reverse('devotional-today')
    
    # 1. No hay devocionales publicados -> 404
    response = api_client.get(url)
    assert response.status_code == status.HTTP_404_NOT_FOUND

    # 2. Publicamos el devocional
    devotional.status = DevotionalStatus.PUBLISHED
    devotional.save()

    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['title'] == devotional.title
    
    # Visita incrementada
    devotional.refresh_from_db()
    assert devotional.views_count == 1


@pytest.mark.django_db
def test_duplicate_devotional(staff_client, devotional):
    """
    Duplicación de devocionales calculando fecha disponible automáticamente.
    """
    url = reverse('devotional-duplicate', kwargs={'pk': devotional.id})
    response = staff_client.post(url)
    assert response.status_code == status.HTTP_201_CREATED
    
    cloned_id = response.data['id']
    cloned = Devotional.objects.get(id=cloned_id)
    assert cloned.title == f"Copia de {devotional.title}"
    assert cloned.status == DevotionalStatus.DRAFT
    assert cloned.date != devotional.date
