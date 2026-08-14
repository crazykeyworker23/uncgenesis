import pytest
from django.urls import reverse
from rest_framework import status
from django.core.files.uploadedfile import SimpleUploadedFile
from django.contrib.auth import get_user_model
from apps.multimedia.models import Multimedia, MediaType

User = get_user_model()

MULTIMEDIA_LIST = reverse('multimedia-list')

def multimedia_detail(pk):
    return reverse('multimedia-detail', args=[pk])


@pytest.fixture
def admin_client(db, create_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    user = create_user(email="media_admin@genesisapp.org")
    user.is_superuser = True
    user.save()
    
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def member_client(db, create_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    user = create_user(email="media_member@genesisapp.org")
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.mark.django_db
class TestMultimediaLibrary:
    def test_list_media_requires_auth(self, api_client):
        """Listing media requires authentication."""
        res = api_client.get(MULTIMEDIA_LIST)
        assert res.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_media_denied_for_regular_member(self, member_client):
        """Regular members without permissions cannot view media items."""
        res = member_client.get(MULTIMEDIA_LIST)
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_upload_image_file_auto_detect(self, admin_client):
        """Admins can upload an image file and the system auto-detects properties."""
        test_file = SimpleUploadedFile(
            name="test_image.png",
            content=b"fake_image_bytes_png_data",
            content_type="image/png"
        )
        payload = {
            'title': 'Foto del templo principal',
            'file': test_file
        }
        res = admin_client.post(MULTIMEDIA_LIST, payload, format='multipart')
        assert res.status_code == status.HTTP_201_CREATED
        
        # Verify model database entry
        item = Multimedia.objects.get(title='Foto del templo principal')
        assert item.file_type == MediaType.IMAGE
        assert item.file_size == len(b"fake_image_bytes_png_data")
        assert item.uploaded_by.email == "media_admin@genesisapp.org"

    def test_upload_pdf_file_auto_detect(self, admin_client):
        """Admins can upload a PDF and file_type maps to PDF."""
        test_file = SimpleUploadedFile(
            name="newsletter.pdf",
            content=b"pdf_bytes_data",
            content_type="application/pdf"
        )
        payload = {
            'title': 'Boletín Mensual',
            'file': test_file
        }
        res = admin_client.post(MULTIMEDIA_LIST, payload, format='multipart')
        assert res.status_code == status.HTTP_201_CREATED
        
        item = Multimedia.objects.get(title='Boletín Mensual')
        assert item.file_type == MediaType.PDF

    def test_delete_media_item(self, admin_client):
        """Admins can delete media items from the library."""
        test_file = SimpleUploadedFile(
            name="to_delete.txt",
            content=b"some text",
            content_type="text/plain"
        )
        item = Multimedia.objects.create(
            title='Delete Me',
            file=test_file,
            file_size=9,
            file_type=MediaType.OTHER
        )

        res = admin_client.delete(multimedia_detail(item.id))
        assert res.status_code == status.HTTP_204_NO_CONTENT
        assert not Multimedia.objects.filter(id=item.id).exists()
