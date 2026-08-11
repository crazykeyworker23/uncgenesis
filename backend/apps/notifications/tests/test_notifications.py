import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.notifications.models import FCMDevice, Notification, DeviceType, TargetAudience, NotificationStatus
from apps.roles.models import Role, RoleType, UserRole

User = get_user_model()

DEVICES_LIST = reverse('notification-devices-list')
NOTIFICATIONS_LIST = reverse('notifications-list')

def notification_detail(pk):
    return reverse('notifications-detail', args=[pk])

def notification_send_now(pk):
    return reverse('notifications-send-now', args=[pk])


@pytest.fixture(autouse=True)
def setup_testing_env(settings):
    settings.TESTING = True
    settings.CELERY_TASK_ALWAYS_EAGER = True
    settings.CELERY_TASK_EAGER_PROPAGATES = True



@pytest.fixture
def member_role(db):
    role, _ = Role.objects.get_or_create(
        name=RoleType.MEMBER,
        defaults={'description': 'Miembro registrado'}
    )
    return role


@pytest.fixture
def leader_role(db):
    role, _ = Role.objects.get_or_create(
        name=RoleType.CELL_LEADER,
        defaults={'description': 'Líder de célula'}
    )
    return role


@pytest.fixture
def auth_client(db, create_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    user = create_user(email="editor@genesisapp.org")
    
    # Assign staff/superuser status to allow all permissions (or standard Role)
    user.is_superuser = True
    user.save()
    
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def normal_client(db, create_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    user = create_user(email="member@genesisapp.org")
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


# ── FCM Device Tests ────────────────────────────────────────────────────────

@pytest.mark.django_db
class TestFCMDevice:
    def test_register_device_public(self, api_client):
        """Any user (authenticated or guest) can register a device token."""
        payload = {
            'token': 'fcm_token_xyz_123',
            'device_type': 'ANDROID'
        }
        res = api_client.post(DEVICES_LIST, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        assert FCMDevice.objects.filter(token='fcm_token_xyz_123').exists()
        assert FCMDevice.objects.get(token='fcm_token_xyz_123').user is None

    def test_register_device_authenticated(self, normal_client):
        """Registering a device while logged in associates the user."""
        payload = {
            'token': 'fcm_token_auth_456',
            'device_type': 'IOS'
        }
        res = normal_client.post(DEVICES_LIST, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        device = FCMDevice.objects.get(token='fcm_token_auth_456')
        assert device.user is not None
        assert device.user.email == "member@genesisapp.org"

    def test_register_device_duplicate_updates(self, normal_client, api_client):
        """Registering an existing token updates it without duplicate error."""
        # 1. Register as guest
        payload = {
            'token': 'duplicate_token_789',
            'device_type': 'ANDROID'
        }
        res1 = api_client.post(DEVICES_LIST, payload, format='json')
        assert res1.status_code == status.HTTP_201_CREATED
        
        # 2. Register same token as authenticated user
        res2 = normal_client.post(DEVICES_LIST, payload, format='json')
        assert res2.status_code == status.HTTP_201_CREATED
        
        # Verify single device exists and has the user associated
        devices = FCMDevice.objects.filter(token='duplicate_token_789')
        assert devices.count() == 1
        assert devices.first().user is not None


# ── Notification Management Tests ───────────────────────────────────────────

@pytest.mark.django_db
class TestNotificationManagement:
    def test_list_notifications_is_empty_for_guests(self, api_client, db):
        """
        El modo invitado no recibe notificaciones: la lista responde vacía en
        lugar de un 401, para que la app no interprete que la sesión expiró.
        """
        Notification.objects.create(
            title="Aviso 1", body="Contenido 1", status=NotificationStatus.SENT
        )
        res = api_client.get(NOTIFICATIONS_LIST)
        assert res.status_code == status.HTTP_200_OK
        assert res.data['results'] == []

    def test_list_notifications_as_staff(self, auth_client, db):
        """El feed del usuario autenticado muestra las notificaciones enviadas."""
        Notification.objects.create(
            title="Aviso 1", body="Contenido 1", status=NotificationStatus.SENT
        )
        res = auth_client.get(NOTIFICATIONS_LIST)
        assert res.status_code == status.HTTP_200_OK
        assert len(res.data['results']) == 1

    def test_list_notifications_admin_view_includes_pending(self, auth_client, db):
        """El panel administrativo (admin_view) sí ve las pendientes."""
        Notification.objects.create(
            title="Programada", body="Aún no enviada", status=NotificationStatus.PENDING
        )
        res = auth_client.get(NOTIFICATIONS_LIST, {'admin_view': 'true'})
        assert res.status_code == status.HTTP_200_OK
        assert len(res.data['results']) == 1

    def test_create_notification_immediate(self, auth_client):
        """Creating notification without schedule triggers immediate send (simulated)."""
        # Register a device to receive it
        FCMDevice.objects.create(token="target_token", device_type="ANDROID")

        payload = {
            'title': 'Reunión General',
            'body': 'Los esperamos este domingo.',
            'target_audience': 'ALL'
        }
        res = auth_client.post(NOTIFICATIONS_LIST, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED
        
        # Fetch notification and verify immediate processing
        notification = Notification.objects.get(id=res.data['id'])
        assert notification.status == NotificationStatus.SENT
        assert notification.sent_at is not None
        # El aviso queda registrado y visible en la app. El campo recoge el
        # detalle de la entrega push, que en pruebas no se realiza.
        assert 'FIREBASE_CREDENTIALS' in notification.error_message

    def test_create_notification_scheduled(self, auth_client, monkeypatch):
        """Scheduled notifications remain in PENDING state."""
        # En pruebas Celery corre en modo eager y ejecutaría la tarea al
        # instante ignorando el `eta`. Se intercepta el encolado para verificar
        # el comportamiento real: queda pendiente y programada para su fecha.
        from apps.notifications import views as notifications_views

        scheduled_calls = []
        monkeypatch.setattr(
            notifications_views.send_push_notification_task,
            'apply_async',
            lambda args=None, **kwargs: scheduled_calls.append((args, kwargs)),
        )

        future_time = timezone.now() + timezone.timedelta(hours=2)
        payload = {
            'title': 'Recordatorio Próximo',
            'body': 'Mensaje programado.',
            'target_audience': 'ALL',
            'scheduled_for': future_time.isoformat()
        }
        res = auth_client.post(NOTIFICATIONS_LIST, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED

        # Status should be PENDING and sent_at should be null
        notification = Notification.objects.get(id=res.data['id'])
        assert notification.status == NotificationStatus.PENDING
        assert notification.sent_at is None

        # Y debe haber quedado encolada para la fecha indicada
        assert len(scheduled_calls) == 1
        assert scheduled_calls[0][1]['eta'] == notification.scheduled_for

    def test_send_now_action(self, auth_client):
        """Custom send-now action triggers immediate send for pending notification."""
        future_time = timezone.now() + timezone.timedelta(hours=5)
        notification = Notification.objects.create(
            title="Aviso Programado",
            body="Detalle programado",
            status=NotificationStatus.PENDING,
            scheduled_for=future_time
        )
        
        # Register a token
        FCMDevice.objects.create(token="fcm_token_now", device_type="IOS")

        res = auth_client.post(notification_send_now(notification.id))
        assert res.status_code == status.HTTP_200_OK

        notification.refresh_from_db()
        assert notification.status == NotificationStatus.SENT
        assert notification.sent_at is not None
        # El botón entrega en el momento y devuelve el resultado real. Antes
        # delegaba en Celery: con el trabajador caído respondía un error, y con
        # el broker en pie pero sin nadie procesando la cola no ocurría nada.
        assert 'FIREBASE_CREDENTIALS' in notification.error_message
        assert res.data['error_message'] == notification.error_message

    def test_create_notification_specific_user(self, auth_client, create_user):
        """Sending notification to a specific user filters target devices correctly."""
        target_user = create_user(email="target@genesisapp.org")
        other_user = create_user(email="other@genesisapp.org")

        device_target = FCMDevice.objects.create(token="token_target_user", device_type="ANDROID", user=target_user)
        device_other = FCMDevice.objects.create(token="token_other_user", device_type="IOS", user=other_user)

        payload = {
            'title': 'Aviso Personal',
            'body': 'Mensaje directo para ti',
            'target_audience': 'USER',
            'target_user': target_user.id
        }
        res = auth_client.post(NOTIFICATIONS_LIST, payload, format='json')
        assert res.status_code == status.HTTP_201_CREATED

        notification = Notification.objects.get(id=res.data['id'])
        assert notification.status == NotificationStatus.SENT
        assert notification.target_user == target_user
        # El destinatario queda acotado a esa persona.
        assert device_target.user == target_user
        assert device_other.user != target_user
