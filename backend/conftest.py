import pytest
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
from apps.roles.models import Role, RoleType, UserRole

User = get_user_model()


@pytest.fixture(autouse=True)
def sin_envio_push_real(settings):
    """
    Las pruebas no envían notificaciones de verdad.

    Sin esto, cualquier prueba que cree una notificación intentaría contactar
    con Firebase usando las credenciales del `.env` de quien las ejecuta: sería
    lenta, dependería de la red y podría llegar a teléfonos reales.

    Quien necesite probar el envío lo simula explícitamente, como en
    apps/notifications/tests/test_push.py.
    """
    settings.FIREBASE_CREDENTIALS = None


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def test_password():
    return "secure_pass_123"


@pytest.fixture
def user_data(test_password):
    return {
        "email": "testuser@genesisapp.org",
        "password": test_password,
        "password_confirm": test_password,
        "first_name": "Juan",
        "last_name": "Perez",
        "phone": "+51999999999"
    }


@pytest.fixture
def create_user(db, test_password):
    def make_user(email="user@genesisapp.org", status="ACTIVE", **kwargs):
        user = User.objects.create_user(
            email=email,
            password=test_password,
            first_name=kwargs.get("first_name", "Test"),
            last_name=kwargs.get("last_name", "User"),
            phone=kwargs.get("phone", "+51900000000"),
            status=status
        )
        return user
    return make_user


@pytest.fixture
def superuser(db, test_password):
    return User.objects.create_superuser(
        email="superadmin@genesisapp.org",
        password=test_password,
        first_name="Super",
        last_name="Admin"
    )
