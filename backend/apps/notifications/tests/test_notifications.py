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
    def test_list_notifications_requires_auth(self, api_client):
        """Listing notifications requires authentication."""
        res = api_client.get(NOTIFICATIONS_LIST)
        assert res.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_notifications_as_staff(self, auth_client, db):
        """Authorized user can list notifications."""
        Notification.objects.create(title="Aviso 1", body="Contenido 1")
        res = auth_client.get(NOTIFICATIONS_LIST)
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
        assert "Simulation:" in notification.error_message

    def test_create_notification_scheduled(self, auth_client):
        """Scheduled notifications remain in PENDING state."""
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
        assert "sent to 1 dummy tokens" in notification.error_message
