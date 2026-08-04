import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.publications.models import Publication, PublicationCategory, PublicationTag, PublicationStatus, PublicationContentType
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
def category(db):
    return PublicationCategory.objects.create(name="Predicaciones", description="Mensajes dominicales")


@pytest.fixture
def tag(db):
    return PublicationTag.objects.create(name="Familia")


@pytest.fixture
def publication(db, admin_user, category, tag):
    pub = Publication.objects.create(
        title="Restaurando el Altar Familiar",
        summary="Breve resumen sobre la restauración del altar",
        content="Contenido detallado de la prédica dominical...",
        category=category,
        content_type=PublicationContentType.SERVICE,
        author=admin_user,
        status=PublicationStatus.DRAFT,
        is_featured=True,
    )
    pub.tags.add(tag)
    return pub


@pytest.mark.django_db
def test_anonymous_read_publications(api_client, publication):
    """
    Cualquiera (incluso anónimo) debe poder ver las publicaciones publicadas,
    pero nunca los borradores.
    """
    url = reverse('publication-list')
    detail_url = reverse('publication-detail', kwargs={'pk': publication.id})

    # En borrador no debe ser visible públicamente
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] == 0
    assert api_client.get(detail_url).status_code == status.HTTP_404_NOT_FOUND

    # Una vez publicada sí
    publication.status = PublicationStatus.PUBLISHED
    publication.save()

    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] == 1

    response = api_client.get(detail_url)
    assert response.status_code == status.HTTP_200_OK
    # Al obtener el detalle se incrementa el contador de visitas
    publication.refresh_from_db()
    assert publication.views_count == 1


@pytest.mark.django_db
def test_create_publication_with_permission(api_client, staff_client, category, tag):
    """
    Un usuario con permiso PUBLICATIONS_CREATE puede crear publicaciones.
    """
    url = reverse('publication-list')
    data = {
        "title": "Nuevo Despertar Espiritual",
        "slug": "nuevo-despertar",
        "summary": "Resumen espiritual",
        "content": "Contenido completo...",
        "category": category.id,
        "content_type": PublicationContentType.GENERAL,
        "status": PublicationStatus.DRAFT
    }
    
    # Anónimo no puede crear
    # Creamos un cliente limpio para simular anónimo ya que staff_client tiene credentials guardadas
    from rest_framework.test import APIClient
    anon_client = APIClient()
    response = anon_client.post(url, data)
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

    # Staff con rol/permisos asignados
    response = staff_client.post(url, data)
    assert response.status_code == status.HTTP_201_CREATED
    assert Publication.objects.filter(title="Nuevo Despertar Espiritual").exists()
    
    # Validar auditoría
    assert AuditLog.objects.filter(action="CREATE", module="PUBLICATIONS").exists()


@pytest.mark.django_db
def test_publish_and_archive_actions(staff_client, publication):
    """
    Acciones personalizadas para publicar y archivar.
    """
    publish_url = reverse('publication-publish', kwargs={'pk': publication.id})
    archive_url = reverse('publication-archive', kwargs={'pk': publication.id})

    # Publicar
    response = staff_client.post(publish_url)
    assert response.status_code == status.HTTP_200_OK
    publication.refresh_from_db()
    assert publication.status == PublicationStatus.PUBLISHED
    assert publication.published_at is not None

    # Archivar
    response = staff_client.post(archive_url)
    assert response.status_code == status.HTTP_200_OK
    publication.refresh_from_db()
    assert publication.status == PublicationStatus.ARCHIVED


@pytest.mark.django_db
def test_duplicate_publication(staff_client, publication):
    """
    Verifica la acción de duplicación de publicaciones.
    """
    url = reverse('publication-duplicate', kwargs={'pk': publication.id})
    response = staff_client.post(url)
    assert response.status_code == status.HTTP_201_CREATED
    
    cloned_id = response.data['id']
    cloned = Publication.objects.get(id=cloned_id)
    assert cloned.title == f"Copia de {publication.title}"
    assert cloned.status == PublicationStatus.DRAFT
    assert cloned.tags.count() == publication.tags.count()
