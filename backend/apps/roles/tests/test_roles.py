import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.roles.models import Role, Permission, RolePermission, RoleType

User = get_user_model()

ROLES_LIST = reverse('roles-list')
PERMISSIONS_LIST = reverse('permissions-list')

def role_detail(pk):
    return reverse('roles-detail', args=[pk])


@pytest.fixture
def test_permission(db):
    permission, _ = Permission.objects.get_or_create(
        codename='TEST_PERMISSION',
        defaults={'name': 'Test Permission', 'description': 'Test Permission'}
    )
    return permission


@pytest.fixture
def admin_client(db, create_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    user = create_user(email="role_admin@genesisapp.org")
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
    user = create_user(email="role_member@genesisapp.org")
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.mark.django_db
class TestRoleAndPermissionManagement:
    def test_list_roles_requires_auth(self, api_client):
        """Listing roles requires auth."""
        res = api_client.get(ROLES_LIST)
        assert res.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_roles_denied_for_regular_member(self, member_client):
        """Regular members cannot see all roles."""
        res = member_client.get(ROLES_LIST)
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_list_roles_allowed_for_admin(self, admin_client):
        """Admins can retrieve roles."""
        res = admin_client.get(ROLES_LIST)
        assert res.status_code == status.HTTP_200_OK
        assert len(res.data) >= 1

    def test_create_role_with_permissions(self, admin_client, test_permission):
        """Admins can create a role and map permission codenames to it."""
        # Delete existing role to allow recreate
        Role.objects.filter(name=RoleType.SUPPORT).delete()
        payload = {
            'name': RoleType.SUPPORT,
            'description': 'Soporte y Consejería',
            'assigned_permissions': [test_permission.codename]
        }
        res = admin_client.post(ROLES_LIST, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        
        role = Role.objects.get(name=RoleType.SUPPORT)
        assert RolePermission.objects.filter(role=role, permission=test_permission).exists()

    def test_update_role_permissions(self, admin_client, test_permission):
        """Admins can modify permissions mapped to a role."""
        role = Role.objects.get(name=RoleType.CELL_LEADER)
        
        # Sync to test_permission
        payload = {
            'description': 'Líder de Célula de Conexión',
            'assigned_permissions': [test_permission.codename]
        }
        res = admin_client.patch(role_detail(role.id), payload, format='json')
        assert res.status_code == status.HTTP_200_OK
        
        role.refresh_from_db()
        assert role.description == 'Líder de Célula de Conexión'
        assert RolePermission.objects.filter(role=role, permission=test_permission).exists()

    def test_list_permissions_as_admin(self, admin_client, test_permission):
        """Admins can query the complete list of system permissions."""
        res = admin_client.get(PERMISSIONS_LIST)
        assert res.status_code == status.HTTP_200_OK
        assert len(res.data) >= 1
        # Check codenames exist in response
        codenames = [p['codename'] for p in res.data]
        assert test_permission.codename in codenames

