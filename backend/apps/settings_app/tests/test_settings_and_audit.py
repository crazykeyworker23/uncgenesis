import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from django.test import RequestFactory
from apps.settings_app.models import AppSettings, ChurchSettings
from apps.audit.models import AuditLog
from apps.audit.services import log_action
from apps.roles.models import Role, RoleType, UserRole

User = get_user_model()


@pytest.mark.django_db
class TestSettingsAndAudit:

    def test_public_settings_success(self, api_client):
        # ChurchSettings and AppSettings are populated via migration 0002.
        # Since we use SQLite in-memory, migrations are run automatically.
        url = reverse('settings_public')
        response = api_client.get(url)
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['app']['app_name'] == "Génesis App"
        assert response.data['church']['church_name'] == "Iglesia Génesis"
        assert response.data['church']['whatsapp'] == "+51 931 405 531"
        assert len(response.data['schedules']) > 0
        assert len(response.data['social_networks']) > 0

    def test_app_settings_update_unauthenticated(self, api_client):
        url = reverse('settings_app_update')
        response = api_client.patch(url, {"app_name": "Nuevo Nombre"})
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_app_settings_update_forbidden_for_regular_member(self, api_client, create_user):
        user = create_user(email="member@genesisapp.org")
        
        # Authenticate
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer token') # We mock or use standard auth
        # Let's generate a real JWT token for this user
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')

        url = reverse('settings_app_update')
        response = api_client.patch(url, {"app_name": "Nuevo Nombre"})
        
        # Regular member does not have SETTINGS_EDIT permission
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_app_settings_update_success_for_superuser(self, api_client, superuser):
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(superuser)
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')

        url = reverse('settings_app_update')
        response = api_client.patch(url, {"app_name": "Génesis Renovada"})
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['app_name'] == "Génesis Renovada"
        assert AppSettings.get_solo().app_name == "Génesis Renovada"

    def test_log_action_utility(self, create_user):
        user = create_user(email="admin_audit@genesisapp.org")
        
        # Create a mock request using Django's RequestFactory
        factory = RequestFactory()
        request = factory.post('/some-url/', HTTP_USER_AGENT='TestAgent', REMOTE_ADDR='192.168.1.100')
        
        # Log action
        log = log_action(
            user=user,
            action="CREATE",
            module="PUBLICATIONS",
            object_id="42",
            description="Creación de publicación de prueba",
            request=request
        )
        
        # Verify AuditLog DB record
        db_log = AuditLog.objects.get(id=log.id)
        assert db_log.user == user
        assert db_log.action == "CREATE"
        assert db_log.module == "PUBLICATIONS"
        assert db_log.object_id == "42"
        assert db_log.ip_address == "192.168.1.100"
        assert db_log.user_agent == "TestAgent"
        assert "Creación de publicación de prueba" in db_log.description

    def test_schedules_crud_as_superuser(self, api_client, superuser):
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(superuser)
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')

        url = reverse('settings_schedules-list')
        
        # 1. Create
        payload = {
            'day_of_week': 'SUNDAY',
            'start_time': '18:00:00',
            'title': 'Servicio de Jóvenes',
            'description': 'Culto especial enfocado en la juventud'
        }
        res = api_client.post(url, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        schedule_id = res.data['id']

        # 2. List
        res = api_client.get(url)
        assert res.status_code == status.HTTP_200_OK
        assert len(res.data) >= 1

        # 3. Delete
        res = api_client.delete(reverse('settings_schedules-detail', args=[schedule_id]))
        assert res.status_code == status.HTTP_204_NO_CONTENT

    def test_socials_crud_as_superuser(self, api_client, superuser):
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(superuser)
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')

        url = reverse('settings_socials-list')
        
        # 1. Create
        payload = {
            'name': 'Twitter',
            'url': 'https://x.com/iglesiagenesis',
            'icon_name': 'twitter'
        }
        res = api_client.post(url, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        social_id = res.data['id']

        # 2. Delete
        res = api_client.delete(reverse('settings_socials-detail', args=[social_id]))
        assert res.status_code == status.HTTP_204_NO_CONTENT
