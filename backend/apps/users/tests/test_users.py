import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from apps.users.models import UserStatus
from apps.roles.models import Role, RoleType, UserRole

User = get_user_model()

USERS_LIST = reverse('users-list')

def user_detail(pk):
    return reverse('users-detail', args=[pk])

def user_block(pk):
    return reverse('users-block', args=[pk])

def user_unblock(pk):
    return reverse('users-unblock', args=[pk])


@pytest.fixture
def manager_role(db):
    role, _ = Role.objects.get_or_create(
        name=RoleType.ADMIN,
        defaults={'description': 'Administrador'}
    )
    return role


@pytest.fixture
def leader_role(db):
    role, _ = Role.objects.get_or_create(
        name=RoleType.CELL_LEADER,
        defaults={'description': 'Líder de Célula'}
    )
    return role


@pytest.fixture
def admin_client(db, create_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    user = create_user(email="admin_user@genesisapp.org")
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
    user = create_user(email="member_user@genesisapp.org")
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.mark.django_db
class TestUserAdministration:
    def test_list_users_requires_auth(self, api_client):
        """Listing users requires authentication."""
        res = api_client.get(USERS_LIST)
        assert res.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_users_denied_for_regular_member(self, member_client):
        """Regular members cannot view the list of all users."""
        res = member_client.get(USERS_LIST)
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_list_users_allowed_for_admin(self, admin_client, create_user):
        """Admins can view and filter user accounts."""
        create_user(email="another_user@genesisapp.org")
        res = admin_client.get(USERS_LIST)
        assert res.status_code == status.HTTP_200_OK
        # Res should contain at least the admin and the created user
        assert len(res.data['results']) >= 2

    def test_create_user_by_admin(self, admin_client, manager_role):
        """Admins can create new users and pre-assign roles."""
        payload = {
            'email': 'new_leader@genesisapp.org',
            'first_name': 'Roberto',
            'last_name': 'Gomez',
            'phone': '+51987654321',
            'password': 'Genesis.2026.Segura',
            'assigned_roles': [RoleType.ADMIN]
        }
        res = admin_client.post(USERS_LIST, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED

        user = User.objects.get(email='new_leader@genesisapp.org')
        assert user.first_name == 'Roberto'
        # Verify role relation exists
        assert UserRole.objects.filter(user=user, role__name=RoleType.ADMIN).exists()
        # La credencial definida debe quedar activa y nunca devolverse
        assert user.check_password('Genesis.2026.Segura')
        assert 'password' not in res.data

    def test_create_user_requires_explicit_password(self, admin_client, manager_role):
        """
        Crear una cuenta sin contraseña debe fallar.

        Antes se asignaba en silencio una contraseña fija e identica para todas
        las cuentas creadas desde el panel.
        """
        payload = {
            'email': 'sin_clave@genesisapp.org',
            'first_name': 'Sin',
            'last_name': 'Clave',
        }
        res = admin_client.post(USERS_LIST, payload, format='json')
        assert res.status_code == status.HTTP_400_BAD_REQUEST
        assert not User.objects.filter(email='sin_clave@genesisapp.org').exists()

    def test_create_user_rejects_weak_password(self, admin_client):
        """Las contraseñas pasan por los validadores de Django."""
        payload = {
            'email': 'debil@genesisapp.org',
            'password': '123',
        }
        res = admin_client.post(USERS_LIST, payload, format='json')
        assert res.status_code == status.HTTP_400_BAD_REQUEST
        assert 'password' in res.data

    def test_admin_can_change_the_login_email(self, admin_client, create_user):
        """El correo es la identidad de acceso y debe poder corregirse."""
        target = create_user(email="antiguo@genesisapp.org")

        res = admin_client.patch(
            user_detail(target.id), {'email': 'nuevo@genesisapp.org'}, format='json'
        )
        assert res.status_code == status.HTTP_200_OK

        target.refresh_from_db()
        assert target.email == 'nuevo@genesisapp.org'

    def test_email_is_normalised_to_lowercase(self, admin_client, create_user):
        """
        Guardarlo tal cual dejaría fuera a quien escriba su correo en
        minúsculas, porque el inicio de sesión compara el texto exacto.
        """
        target = create_user(email="normal@genesisapp.org")

        res = admin_client.patch(
            user_detail(target.id), {'email': '  Maria@Iglesia.ORG '}, format='json'
        )
        assert res.status_code == status.HTTP_200_OK

        target.refresh_from_db()
        assert target.email == 'maria@iglesia.org'

    def test_email_already_taken_is_rejected(self, admin_client, create_user):
        create_user(email="ocupado@genesisapp.org")
        target = create_user(email="libre@genesisapp.org")

        res = admin_client.patch(
            user_detail(target.id), {'email': 'ocupado@genesisapp.org'}, format='json'
        )
        assert res.status_code == status.HTTP_400_BAD_REQUEST
        assert 'email' in res.data

        target.refresh_from_db()
        assert target.email == 'libre@genesisapp.org'

    def test_email_clash_ignoring_case_is_rejected(self, admin_client, create_user):
        """Dos cuentas no pueden diferenciarse sólo por las mayúsculas."""
        create_user(email="pastor@genesisapp.org")
        target = create_user(email="otro@genesisapp.org")

        res = admin_client.patch(
            user_detail(target.id), {'email': 'PASTOR@genesisapp.org'}, format='json'
        )
        assert res.status_code == status.HTTP_400_BAD_REQUEST

    def test_keeping_its_own_email_is_not_a_clash(self, admin_client, create_user):
        """Guardar sin tocar el correo no debe chocar consigo mismo."""
        target = create_user(email="mismo@genesisapp.org")

        res = admin_client.patch(
            user_detail(target.id),
            {'email': 'mismo@genesisapp.org', 'first_name': 'Actualizado'},
            format='json',
        )
        assert res.status_code == status.HTTP_200_OK

        target.refresh_from_db()
        assert target.first_name == 'Actualizado'

    def test_changing_the_email_keeps_the_password(self, admin_client, create_user):
        target = create_user(email="conserva@genesisapp.org")
        target.set_password('Clave.Solida.2026')
        target.save()

        admin_client.patch(
            user_detail(target.id), {'email': 'conserva.nuevo@genesisapp.org'}, format='json'
        )

        target.refresh_from_db()
        assert target.check_password('Clave.Solida.2026')

    def test_admin_can_reset_user_password(self, admin_client, create_user):
        """El administrador actualiza credenciales sin conocer la anterior."""
        target = create_user(email="olvidadizo@genesisapp.org")

        res = admin_client.post(
            f"{USERS_LIST}{target.id}/set-password/",
            {'password': 'Nueva.Clave.2026'},
            format='json'
        )
        assert res.status_code == status.HTTP_200_OK

        target.refresh_from_db()
        assert target.check_password('Nueva.Clave.2026')

    def test_update_user_roles(self, admin_client, create_user, manager_role, leader_role):
        """Admins can update user profile and modify their assigned roles."""
        target_user = create_user(email="to_update@genesisapp.org")
        
        # Add initial role
        UserRole.objects.create(user=target_user, role=manager_role)
        
        # Update roles to just CELL_LEADER
        payload = {
            'first_name': 'UpdatedName',
            'assigned_roles': [RoleType.CELL_LEADER]
        }
        res = admin_client.patch(user_detail(target_user.id), payload, format='json')
        assert res.status_code == status.HTTP_200_OK
        
        target_user.refresh_from_db()
        assert target_user.first_name == 'UpdatedName'
        assert not UserRole.objects.filter(user=target_user, role=manager_role).exists()
        assert UserRole.objects.filter(user=target_user, role=leader_role).exists()

    def test_block_user_action(self, admin_client, create_user):
        """Admins can block user accounts to prevent log-ins."""
        target_user = create_user(email="to_block@genesisapp.org")
        assert target_user.status == UserStatus.ACTIVE

        res = admin_client.post(user_block(target_user.id))
        assert res.status_code == status.HTTP_200_OK
        
        target_user.refresh_from_db()
        assert target_user.status == UserStatus.BLOCKED
        assert target_user.is_active is False

    def test_unblock_user_action(self, admin_client, create_user):
        """Admins can unblock accounts to restore access."""
        target_user = create_user(email="blocked@genesisapp.org", status=UserStatus.BLOCKED)
        assert target_user.status == UserStatus.BLOCKED

        res = admin_client.post(user_unblock(target_user.id))
        assert res.status_code == status.HTTP_200_OK
        
        target_user.refresh_from_db()
        assert target_user.status == UserStatus.ACTIVE
        assert target_user.is_active is True
