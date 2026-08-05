"""
Alcance del líder de célula.

El líder gestiona únicamente el grupo que tiene a su cargo: ve a los suyos,
les envía recordatorios y edita su propia célula, sin tocar las ajenas.
"""

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.cells.models import CellGroup, MeetingDay
from apps.notifications.models import Notification, NotificationStatus, TargetAudience
from apps.roles.models import Role, RoleType, UserRole
from apps.roles.utils import can_access_admin_panel

User = get_user_model()

MY_CELLS_URL = reverse('cells-my-cells')


def cell_members_url(pk):
    return reverse('cells-members', args=[pk])


def cell_reminder_url(pk):
    return reverse('cells-send-reminder', args=[pk])


def cell_detail_url(pk):
    return reverse('cells-detail', args=[pk])


def _client_for(user):
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.fixture
def make_user(db):
    def _make(email, role_name=None):
        user = User.objects.create_user(email=email, password='Clave.Solida.2026')
        if role_name:
            role, _ = Role.objects.get_or_create(name=role_name, defaults={'description': role_name})
            UserRole.objects.create(user=user, role=role)
        return user
    return _make


@pytest.fixture
def make_cell(db):
    def _make(name, leader=None):
        return CellGroup.objects.create(
            name=name,
            leader=leader,
            meeting_day=MeetingDay.WEDNESDAY,
            meeting_time='19:30',
            address='Av. Central 123',
        )
    return _make


@pytest.mark.django_db
class TestLeaderSeesOwnFlock:
    def test_my_cells_returns_only_the_ones_led(self, make_user, make_cell):
        leader = make_user('lider@genesisapp.org', RoleType.CELL_LEADER)
        other_leader = make_user('otro.lider@genesisapp.org', RoleType.CELL_LEADER)

        mine = make_cell('Célula Norte', leader=leader)
        make_cell('Célula Sur', leader=other_leader)

        res = _client_for(leader).get(MY_CELLS_URL)
        assert res.status_code == status.HTTP_200_OK
        assert [c['id'] for c in res.data] == [mine.id]

    def test_leader_lists_the_people_in_charge(self, make_user, make_cell):
        leader = make_user('lider2@genesisapp.org', RoleType.CELL_LEADER)
        cell = make_cell('Célula Este', leader=leader)

        first = make_user('miembro1@genesisapp.org', RoleType.MEMBER)
        second = make_user('miembro2@genesisapp.org', RoleType.MEMBER)
        outsider = make_user('ajeno@genesisapp.org', RoleType.MEMBER)

        first.assigned_cell = cell
        first.save()
        second.assigned_cell = cell
        second.save()

        res = _client_for(leader).get(cell_members_url(cell.id))
        assert res.status_code == status.HTTP_200_OK
        assert res.data['count'] == 2

        emails = {m['email'] for m in res.data['results']}
        assert emails == {first.email, second.email}
        assert outsider.email not in emails

    def test_leader_cannot_see_members_of_another_cell(self, make_user, make_cell):
        leader = make_user('lider3@genesisapp.org', RoleType.CELL_LEADER)
        other_leader = make_user('otro.lider2@genesisapp.org', RoleType.CELL_LEADER)
        make_cell('Célula Propia', leader=leader)
        foreign = make_cell('Célula Ajena', leader=other_leader)

        res = _client_for(leader).get(cell_members_url(foreign.id))
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_leader_edits_own_cell_but_not_others(self, make_user, make_cell):
        leader = make_user('lider4@genesisapp.org', RoleType.CELL_LEADER)
        other_leader = make_user('otro.lider3@genesisapp.org', RoleType.CELL_LEADER)
        mine = make_cell('Mi Célula', leader=leader)
        foreign = make_cell('Célula Ajena 2', leader=other_leader)

        client = _client_for(leader)

        ok = client.patch(cell_detail_url(mine.id), {'description': 'Nos reunimos en casa'}, format='json')
        assert ok.status_code == status.HTTP_200_OK
        mine.refresh_from_db()
        assert mine.description == 'Nos reunimos en casa'

        denied = client.patch(cell_detail_url(foreign.id), {'description': 'Intruso'}, format='json')
        assert denied.status_code == status.HTTP_403_FORBIDDEN
        foreign.refresh_from_db()
        assert foreign.description != 'Intruso'


@pytest.mark.django_db
class TestLeaderReminders:
    def test_leader_sends_reminder_to_the_cell(self, make_user, make_cell):
        leader = make_user('lider5@genesisapp.org', RoleType.CELL_LEADER)
        cell = make_cell('Célula Oeste', leader=leader)

        member = make_user('miembro3@genesisapp.org', RoleType.MEMBER)
        member.assigned_cell = cell
        member.save()

        res = _client_for(leader).post(
            cell_reminder_url(cell.id),
            {'body': 'Recuerden la reunión de mañana a las 19:30.'},
            format='json',
        )
        assert res.status_code == status.HTTP_201_CREATED
        assert res.data['recipients'] == 1

        notification = Notification.objects.get(id=res.data['id'])
        assert notification.target_audience == TargetAudience.CELL
        assert notification.target_cell == cell
        assert notification.status == NotificationStatus.SENT
        assert notification.sender == leader

    def test_reminder_reaches_only_that_cell(self, make_user, make_cell):
        """El recordatorio llega al feed de su célula y no al de otra."""
        leader = make_user('lider6@genesisapp.org', RoleType.CELL_LEADER)
        cell = make_cell('Célula Centro', leader=leader)
        other_cell = make_cell('Célula Lejana')

        mine = make_user('miembro4@genesisapp.org', RoleType.MEMBER)
        mine.assigned_cell = cell
        mine.save()

        theirs = make_user('miembro5@genesisapp.org', RoleType.MEMBER)
        theirs.assigned_cell = other_cell
        theirs.save()

        _client_for(leader).post(
            cell_reminder_url(cell.id),
            {'body': 'Traigan su Biblia.'},
            format='json',
        )

        feed_url = reverse('notifications-list')

        mine_feed = _client_for(mine).get(feed_url)
        assert mine_feed.status_code == status.HTTP_200_OK
        assert len(mine_feed.data['results']) == 1
        assert mine_feed.data['results'][0]['body'] == 'Traigan su Biblia.'

        theirs_feed = _client_for(theirs).get(feed_url)
        assert theirs_feed.data['results'] == []

    def test_leader_cannot_notify_a_foreign_cell(self, make_user, make_cell):
        leader = make_user('lider7@genesisapp.org', RoleType.CELL_LEADER)
        other_leader = make_user('otro.lider4@genesisapp.org', RoleType.CELL_LEADER)
        make_cell('Célula Propia 2', leader=leader)
        foreign = make_cell('Célula Ajena 3', leader=other_leader)

        member = make_user('miembro6@genesisapp.org', RoleType.MEMBER)
        member.assigned_cell = foreign
        member.save()

        res = _client_for(leader).post(
            cell_reminder_url(foreign.id),
            {'body': 'Mensaje no autorizado'},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN
        assert Notification.objects.count() == 0

    def test_reminder_without_members_is_rejected(self, make_user, make_cell):
        leader = make_user('lider8@genesisapp.org', RoleType.CELL_LEADER)
        cell = make_cell('Célula Vacía', leader=leader)

        res = _client_for(leader).post(
            cell_reminder_url(cell.id),
            {'body': 'Hola'},
            format='json',
        )
        assert res.status_code == status.HTTP_400_BAD_REQUEST

    def test_scheduled_reminder_stays_pending(self, make_user, make_cell, monkeypatch):
        leader = make_user('lider9@genesisapp.org', RoleType.CELL_LEADER)
        cell = make_cell('Célula Programada', leader=leader)
        member = make_user('miembro7@genesisapp.org', RoleType.MEMBER)
        member.assigned_cell = cell
        member.save()

        # Se intercepta el encolado: en pruebas Celery corre en modo eager e
        # ignoraria el `eta`, marcando la notificacion como enviada al instante.
        from apps.notifications import tasks as notification_tasks

        monkeypatch.setattr(
            notification_tasks.send_push_notification_task,
            'apply_async',
            lambda *args, **kwargs: None,
        )

        future = timezone.now() + timezone.timedelta(hours=3)
        res = _client_for(leader).post(
            cell_reminder_url(cell.id),
            {'body': 'Reunión especial', 'scheduled_for': future.isoformat()},
            format='json',
        )
        assert res.status_code == status.HTTP_201_CREATED

        notification = Notification.objects.get(id=res.data['id'])
        assert notification.status == NotificationStatus.PENDING
        assert notification.sent_at is None


@pytest.mark.django_db
class TestLeaderPanelAccess:
    def test_leading_a_cell_grants_panel_access(self, make_user, make_cell):
        """Tener una célula a cargo basta para entrar al panel."""
        plain = make_user('sin_permisos@genesisapp.org')
        assert not can_access_admin_panel(plain)

        make_cell('Célula Asignada', leader=plain)
        plain.refresh_from_db()
        assert can_access_admin_panel(plain)

    def test_me_reports_led_cells(self, make_user, make_cell):
        leader = make_user('lider10@genesisapp.org', RoleType.CELL_LEADER)
        make_cell('Célula A', leader=leader)
        make_cell('Célula B', leader=leader)

        res = _client_for(leader).get(reverse('auth_me'))
        assert res.status_code == status.HTTP_200_OK
        assert res.data['leads_cells'] == 2
        assert res.data['can_access_admin'] is True
        assert res.data['is_superadmin'] is False
