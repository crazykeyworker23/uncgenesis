import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.users.models import UserStatus

User = get_user_model()


@pytest.mark.django_db
class TestAuthentication:

    def test_user_registration_success(self, api_client, user_data):
        url = reverse('auth_register')
        response = api_client.post(url, user_data)
        
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data['email'] == user_data['email']
        assert 'password' not in response.data
        
        # Verify user was created in DB
        user = User.objects.get(email=user_data['email'])
        assert user.first_name == user_data['first_name']
        assert user.last_name == user_data['last_name']
        assert user.status == UserStatus.ACTIVE

    def test_user_registration_mismatched_password(self, api_client, user_data):
        user_data['password_confirm'] = 'different_password'
        url = reverse('auth_register')
        response = api_client.post(url, user_data)
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'password' in response.data

    def test_user_login_success(self, api_client, create_user, test_password):
        email = "loginuser@genesisapp.org"
        create_user(email=email)
        
        url = reverse('auth_login')
        response = api_client.post(url, {
            "email": email,
            "password": test_password
        })
        
        assert response.status_code == status.HTTP_200_OK
        assert 'access' in response.data
        assert 'refresh' in response.data
        assert response.data['user']['email'] == email

    def test_user_login_invalid_credentials(self, api_client, create_user):
        email = "loginuser@genesisapp.org"
        create_user(email=email)
        
        url = reverse('auth_login')
        response = api_client.post(url, {
            "email": email,
            "password": "wrong_password"
        })
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_user_login_blocked_status(self, api_client, create_user, test_password):
        email = "blocked@genesisapp.org"
        create_user(email=email, status=UserStatus.BLOCKED)
        
        url = reverse('auth_login')
        response = api_client.post(url, {
            "email": email,
            "password": test_password
        })
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_token_refresh(self, api_client, create_user, test_password):
        email = "refresh@genesisapp.org"
        create_user(email=email)
        
        # 1. Login to get refresh token
        login_url = reverse('auth_login')
        login_response = api_client.post(login_url, {
            "email": email,
            "password": test_password
        })
        refresh_token = login_response.data['refresh']
        
        # 2. Call token refresh endpoint
        refresh_url = reverse('auth_token_refresh')
        response = api_client.post(refresh_url, {
            "refresh": refresh_token
        })
        
        assert response.status_code == status.HTTP_200_OK
        assert 'access' in response.data

    def test_google_auth_success(self, api_client):
        url = reverse('auth_google')
        response = api_client.post(url, {
            "id_token": "mock-google-token"
        })
        
        assert response.status_code == status.HTTP_200_OK
        assert 'access' in response.data
        assert 'refresh' in response.data
        assert response.data['user']['email'] == "testgoogle@genesisapp.org"
        
        # Verify user was automatically registered in DB
        assert User.objects.filter(email="testgoogle@genesisapp.org").exists()

    def test_logout_success(self, api_client, create_user, test_password):
        email = "logout@genesisapp.org"
        create_user(email=email)
        
        # 1. Login to get refresh token
        login_url = reverse('auth_login')
        login_response = api_client.post(login_url, {
            "email": email,
            "password": test_password
        })
        access_token = login_response.data['access']
        refresh_token = login_response.data['refresh']
        
        # 2. Call logout with auth header and refresh token
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
        logout_url = reverse('auth_logout')
        response = api_client.post(logout_url, {
            "refresh": refresh_token
        })
        
        assert response.status_code == status.HTTP_205_RESET_CONTENT

    def test_get_profile_authenticated(self, api_client, create_user, test_password):
        email = "profile@genesisapp.org"
        create_user(email=email)
        
        # Login
        login_url = reverse('auth_login')
        login_response = api_client.post(login_url, {
            "email": email,
            "password": test_password
        })
        access_token = login_response.data['access']
        
        # Get profile
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
        profile_url = reverse('auth_me')
        response = api_client.get(profile_url)
        
        assert response.status_code == status.HTTP_200_OK
        assert response.data['email'] == email

    def test_get_profile_unauthenticated(self, api_client):
        profile_url = reverse('auth_me')
        response = api_client.get(profile_url)
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
