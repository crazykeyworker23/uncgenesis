"""
Jerarquía de acceso sobre células.

    Superadministrador → toda la plataforma
    Pastor            → toda la iglesia
    Coordinador       → las células que tiene asignadas
    Líder             → la célula que lidera
    Miembro           → su propia información

Se verifica que el aislamiento se cumpla también por petición directa al API:
escribir el identificador de una célula ajena no debe devolver sus datos.
"""

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.cells.models import (
    Attendance,
    AttendanceStatus,
    CellGroup,
    CellMeeting,
    MeetingDay,
    MemberFollowUp,
)
from apps.roles.models import AccessScope, Role, RoleType, UserRole
from apps.roles.scope import (
    can_manage_cell,
    can_reach_cell,
    get_accessible_cell_ids,
    get_user_scope,
)

User = get_user_model()

MEETINGS_URL = reverse('cell-meetings-list')
FOLLOWUPS_URL = reverse('cell-follow-ups-list')
MY_CELLS_URL = reverse('cells-my-cells')


def _client(user):
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


def cell_url(name, pk):
    return reverse(f'cells-{name}', args=[pk])


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
    def _make(name, leader=None, coordinator=None):
        return CellGroup.objects.create(
            name=name,
            leader=leader,
            coordinator=coordinator,
            meeting_day=MeetingDay.WEDNESDAY,
            meeting_time='19:30',
            address='Av. Central 100',
        )
    return _make


@pytest.fixture
def church(make_user, make_cell):
    """Dos células con líderes distintos bajo un mismo coordinador, y una ajena."""
    pastor = make_user('pastor@genesisapp.org', RoleType.ADMIN)
    coordinator = make_user('coordinador@genesisapp.org', RoleType.COORDINATOR)
    leader_a = make_user('lider.a@genesisapp.org', RoleType.CELL_LEADER)
    leader_b = make_user('lider.b@genesisapp.org', RoleType.CELL_LEADER)
    outsider_leader = make_user('lider.z@genesisapp.org', RoleType.CELL_LEADER)

    cell_a = make_cell('Célula A', leader=leader_a, coordinator=coordinator)
    cell_b = make_cell('Célula B', leader=leader_b, coordinator=coordinator)
    cell_z = make_cell('Célula Z', leader=outsider_leader)

    member_a = make_user('miembro.a@genesisapp.org', RoleType.MEMBER)
    member_a.assigned_cell = cell_a
    member_a.save()

    member_z = make_user('miembro.z@genesisapp.org', RoleType.MEMBER)
    member_z.assigned_cell = cell_z
    member_z.save()

    return {
        'pastor': pastor,
        'coordinator': coordinator,
        'leader_a': leader_a,
        'leader_b': leader_b,
        'outsider_leader': outsider_leader,
        'cell_a': cell_a,
        'cell_b': cell_b,
        'cell_z': cell_z,
        'member_a': member_a,
        'member_z': member_z,
    }


@pytest.mark.django_db
class TestScopeResolution:
    def test_each_role_gets_its_scope(self, church, make_user):
        superadmin = make_user('jefe@genesisapp.org', RoleType.SUPERADMIN)

        assert get_user_scope(superadmin) == AccessScope.PLATFORM
        assert get_user_scope(church['pastor']) == AccessScope.CHURCH
        assert get_user_scope(church['coordinator']) == AccessScope.ASSIGNED_CELLS
        assert get_user_scope(church['leader_a']) == AccessScope.OWN_CELL
        assert get_user_scope(church['member_a']) == AccessScope.SELF

    def test_accessible_cells_per_role(self, church, make_user):
        superadmin = make_user('jefe2@genesisapp.org', RoleType.SUPERADMIN)

        # None significa "sin filtro": toda la iglesia
        assert get_accessible_cell_ids(superadmin) is None
        assert get_accessible_cell_ids(church['pastor']) is None

        assert get_accessible_cell_ids(church['coordinator']) == {
            church['cell_a'].id,
            church['cell_b'].id,
        }
        assert get_accessible_cell_ids(church['leader_a']) == {church['cell_a'].id}
        assert get_accessible_cell_ids(church['member_a']) == {church['cell_a'].id}

    def test_reach_versus_manage(self, church):
        """Consultar y gestionar no son lo mismo."""
        member, coordinator, leader = (
            church['member_a'], church['coordinator'], church['leader_a']
        )
        cell_a, cell_z = church['cell_a'], church['cell_z']

        # El miembro ve su célula pero no registra nada en ella
        assert can_reach_cell(member, cell_a.id)
        assert not can_manage_cell(member, cell_a.id)

        # El coordinador supervisa y puede gestionar las asignadas
        assert can_reach_cell(coordinator, cell_a.id)
        assert can_manage_cell(coordinator, cell_b_id := church['cell_b'].id)
        assert not can_reach_cell(coordinator, cell_z.id)

        # El líder, sólo la suya
        assert can_manage_cell(leader, cell_a.id)
        assert not can_reach_cell(leader, church['cell_b'].id)
        assert not can_reach_cell(leader, cell_z.id)


@pytest.mark.django_db
class TestLeaderIsolation:
    def test_leader_only_sees_own_cell_in_my_cells(self, church):
        res = _client(church['leader_a']).get(MY_CELLS_URL)
        assert res.status_code == status.HTTP_200_OK
        assert [c['id'] for c in res.data['results']] == [church['cell_a'].id]
        assert res.data['scope']['scope'] == AccessScope.OWN_CELL

    def test_leader_cannot_read_members_of_another_cell(self, church):
        client = _client(church['leader_a'])
        assert client.get(cell_url('members', church['cell_a'].id)).status_code == status.HTTP_200_OK
        assert client.get(cell_url('members', church['cell_b'].id)).status_code == status.HTTP_403_FORBIDDEN

    def test_leader_cannot_register_meeting_in_another_cell(self, church):
        res = _client(church['leader_a']).post(
            MEETINGS_URL,
            {'cell': church['cell_b'].id, 'date': '2026-08-05', 'topic': 'Intruso'},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN
        assert not CellMeeting.objects.filter(cell=church['cell_b']).exists()

    def test_leader_meeting_list_is_filtered(self, church):
        CellMeeting.objects.create(cell=church['cell_a'], date='2026-08-01', topic='Propia')
        CellMeeting.objects.create(cell=church['cell_b'], date='2026-08-01', topic='Ajena')

        res = _client(church['leader_a']).get(MEETINGS_URL)
        assert res.status_code == status.HTTP_200_OK
        topics = [m['topic'] for m in res.data['results']]
        assert topics == ['Propia']

    def test_leader_cannot_open_foreign_meeting_by_url(self, church):
        """La peticion directa al identificador ajeno no debe devolver datos."""
        foreign = CellMeeting.objects.create(cell=church['cell_b'], date='2026-08-02', topic='Ajena')

        res = _client(church['leader_a']).get(f'{MEETINGS_URL}{foreign.id}/')
        assert res.status_code == status.HTTP_404_NOT_FOUND

    def test_leader_cannot_see_statistics_of_another_cell(self, church):
        client = _client(church['leader_a'])
        assert client.get(cell_url('statistics', church['cell_a'].id)).status_code == status.HTTP_200_OK
        assert client.get(cell_url('statistics', church['cell_b'].id)).status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestLeaderDailyWork:
    def test_leader_registers_meeting_and_attendance(self, church):
        client = _client(church['leader_a'])
        cell = church['cell_a']

        created = client.post(
            MEETINGS_URL,
            {
                'cell': cell.id,
                'date': '2026-08-05',
                'time': '19:30',
                'topic': 'La fe que obra',
                'notes': 'Buena participación',
                'guests_count': 2,
            },
            format='json',
        )
        assert created.status_code == status.HTTP_201_CREATED
        meeting_id = created.data['id']

        # Los cuatro estados que exige el sistema
        marked = client.post(
            f'{MEETINGS_URL}{meeting_id}/attendance/',
            {'attendances': [
                {'member_id': church['member_a'].id, 'status': AttendanceStatus.LATE, 'notes': 'Llegó 19:45'},
            ]},
            format='json',
        )
        assert marked.status_code == status.HTTP_200_OK
        assert marked.data['saved'][0]['status'] == AttendanceStatus.LATE
        # Dos visitantes + quien llegó tarde
        assert marked.data['attendees_count'] == 3

    def test_attendance_rejects_people_from_another_cell(self, church):
        cell = church['cell_a']
        meeting = CellMeeting.objects.create(cell=cell, date='2026-08-06')

        res = _client(church['leader_a']).post(
            f'{MEETINGS_URL}{meeting.id}/attendance/',
            {'attendances': [
                {'member_id': church['member_z'].id, 'status': AttendanceStatus.PRESENT},
            ]},
            format='json',
        )
        assert res.status_code == status.HTTP_200_OK
        assert res.data['rejected'] == [church['member_z'].id]
        assert not Attendance.objects.filter(member=church['member_z']).exists()

    def test_duplicate_meeting_is_rejected_with_a_clear_message(self, church):
        """
        Dos reuniones de la misma célula el mismo día.

        La restricción de la base de datos ya lo impedía, pero salía como error
        500: el líder veía un fallo del servidor en vez de saber qué corregir.
        """
        cell = church['cell_a']
        CellMeeting.objects.create(cell=cell, date='2026-08-12', topic='Primera')

        res = _client(church['leader_a']).post(
            MEETINGS_URL,
            {'cell': cell.id, 'date': '2026-08-12', 'topic': 'Duplicada'},
            format='json',
        )
        assert res.status_code == status.HTTP_400_BAD_REQUEST
        assert 'date' in res.data
        assert CellMeeting.objects.filter(cell=cell, date='2026-08-12').count() == 1

    def test_leader_registers_follow_up(self, church):
        res = _client(church['leader_a']).post(
            FOLLOWUPS_URL,
            {
                'cell': church['cell_a'].id,
                'member_id': church['member_a'].id,
                'type': 'VISIT',
                'date': '2026-08-04',
                'summary': 'Visita en su casa, va bien.',
                'needs_attention': True,
            },
            format='json',
        )
        assert res.status_code == status.HTTP_201_CREATED
        assert MemberFollowUp.objects.filter(cell=church['cell_a']).count() == 1

    def test_leader_registers_a_new_member(self, church):
        res = _client(church['leader_a']).post(
            cell_url('register-member', church['cell_a'].id),
            {'first_name': 'Nuevo', 'last_name': 'Visitante', 'phone': '+51999888777'},
            format='json',
        )
        assert res.status_code == status.HTTP_201_CREATED

        person = User.objects.get(id=res.data['id'])
        assert person.assigned_cell_id == church['cell_a'].id
        # Alta sin privilegios administrativos
        assert not person.is_superuser
        assert list(person.user_roles.values_list('role__name', flat=True)) == [RoleType.MEMBER]

    def test_leader_cannot_register_member_in_another_cell(self, church):
        res = _client(church['leader_a']).post(
            cell_url('register-member', church['cell_b'].id),
            {'first_name': 'Colado'},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_statistics_reflect_the_cell(self, church):
        cell = church['cell_a']
        meeting = CellMeeting.objects.create(cell=cell, date='2026-08-01', topic='Primera')
        Attendance.objects.create(meeting=meeting, member=church['member_a'], status=AttendanceStatus.PRESENT)

        res = _client(church['leader_a']).get(cell_url('statistics', cell.id))
        assert res.status_code == status.HTTP_200_OK
        assert res.data['members_total'] == 1
        assert res.data['members_active'] == 1
        assert res.data['meetings_total'] == 1
        assert res.data['attendance_by_status'][AttendanceStatus.PRESENT] == 1
        assert len(res.data['attendance_trend']) == 1


@pytest.mark.django_db
class TestCoordinatorScope:
    def test_coordinator_sees_assigned_cells_only(self, church):
        res = _client(church['coordinator']).get(MY_CELLS_URL)
        assert res.status_code == status.HTTP_200_OK

        ids = sorted(c['id'] for c in res.data['results'])
        assert ids == sorted([church['cell_a'].id, church['cell_b'].id])
        assert church['cell_z'].id not in ids

    def test_coordinator_supervises_both_leaders(self, church):
        client = _client(church['coordinator'])
        assert client.get(cell_url('members', church['cell_a'].id)).status_code == status.HTTP_200_OK
        assert client.get(cell_url('members', church['cell_b'].id)).status_code == status.HTTP_200_OK
        assert client.get(cell_url('members', church['cell_z'].id)).status_code == status.HTTP_403_FORBIDDEN

    def test_coordinator_reads_meetings_of_assigned_cells(self, church):
        CellMeeting.objects.create(cell=church['cell_a'], date='2026-08-01', topic='A')
        CellMeeting.objects.create(cell=church['cell_b'], date='2026-08-01', topic='B')
        CellMeeting.objects.create(cell=church['cell_z'], date='2026-08-01', topic='Z')

        res = _client(church['coordinator']).get(MEETINGS_URL)
        topics = sorted(m['topic'] for m in res.data['results'])
        assert topics == ['A', 'B']

    def test_coordinator_cannot_reach_administration(self, church):
        client = _client(church['coordinator'])
        assert client.get(reverse('users-list')).status_code == status.HTTP_403_FORBIDDEN
        assert client.get(reverse('roles-list')).status_code == status.HTTP_403_FORBIDDEN
        assert client.post(
            reverse('publication-list'), {'title': 'x', 'content': 'y'}, format='json'
        ).status_code == status.HTTP_403_FORBIDDEN

    def test_coordinator_cannot_broadcast_to_the_whole_church(self, church):
        """
        Su función es comunicar a sus líderes, no difundir a toda la iglesia.

        El comunicado a su célula va por /cells/<id>/send-reminder/, que se
        autoriza por asignación y no necesita el permiso global.
        """
        res = _client(church['coordinator']).post(
            reverse('notifications-list'),
            {'title': 'A todos', 'body': 'x', 'target_audience': 'ALL'},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_coordinator_cannot_read_church_wide_reports(self, church):
        """Los indicadores que le tocan son los de sus células."""
        client = _client(church['coordinator'])
        assert client.get(reverse('reports-summary')).status_code == status.HTTP_403_FORBIDDEN
        assert client.get(reverse('reports-dashboard')).status_code == status.HTTP_403_FORBIDDEN

        # Los de su célula sí, por alcance.
        assert client.get(
            cell_url('statistics', church['cell_a'].id)
        ).status_code == status.HTTP_200_OK

    def test_coordinator_does_not_administer_cells_of_the_church(self, church):
        """Supervisa las asignadas; crear o eliminar células es del pastorado."""
        client = _client(church['coordinator'])
        assert client.post(
            reverse('cells-list'), {'name': 'Nueva'}, format='json'
        ).status_code == status.HTTP_403_FORBIDDEN
        assert client.delete(
            reverse('cells-detail', args=[church['cell_a'].id])
        ).status_code == status.HTTP_403_FORBIDDEN

    def test_coordinator_can_notify_its_leaders(self, church):
        member = church['member_a']
        assert member.assigned_cell_id == church['cell_a'].id

        res = _client(church['coordinator']).post(
            cell_url('send-reminder', church['cell_a'].id),
            {'body': 'Reunión de líderes el sábado.'},
            format='json',
        )
        assert res.status_code == status.HTTP_201_CREATED

    def test_coordinator_cannot_notify_a_foreign_cell(self, church):
        res = _client(church['coordinator']).post(
            cell_url('send-reminder', church['cell_z'].id),
            {'body': 'Fuera de mi alcance'},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestPastorScope:
    def test_pastor_reaches_every_cell(self, church):
        client = _client(church['pastor'])

        for cell in [church['cell_a'], church['cell_b'], church['cell_z']]:
            assert client.get(cell_url('members', cell.id)).status_code == status.HTTP_200_OK
            assert client.get(cell_url('statistics', cell.id)).status_code == status.HTTP_200_OK

    def test_pastor_sees_all_meetings(self, church):
        for cell in [church['cell_a'], church['cell_b'], church['cell_z']]:
            CellMeeting.objects.create(cell=cell, date='2026-08-01', topic=cell.name)

        res = _client(church['pastor']).get(MEETINGS_URL)
        assert len(res.data['results']) == 3

    def test_pastor_does_not_administer_roles(self, church):
        """Gestionar roles y permisos es del superadministrador."""
        client = _client(church['pastor'])
        assert client.get(reverse('users-list')).status_code == status.HTTP_200_OK
        assert client.post(reverse('roles-list'), {'name': RoleType.SUPPORT}, format='json') \
            .status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestChurchWideIsNotCellWide:
    """
    Abarcar la iglesia no da acceso a la vida interna de las células.

    El editor de contenido y el consejero tienen alcance de iglesia en su
    materia, pero no gestionan grupos: no deben leer miembros, reuniones ni
    seguimientos de una célula que no les corresponde.
    """

    def test_content_editor_does_not_reach_cells(self, church, make_user):
        editor = make_user('editor.contenido@genesisapp.org', RoleType.CONTENT_EDITOR)

        assert get_accessible_cell_ids(editor) == set()
        assert not can_reach_cell(editor, church['cell_a'].id)
        assert not can_manage_cell(editor, church['cell_a'].id)

        client = _client(editor)
        assert client.get(
            cell_url('members', church['cell_a'].id)
        ).status_code == status.HTTP_403_FORBIDDEN

        # Consultar reuniones se autoriza por alcance: el editor no alcanza
        # ninguna célula, así que el listado le sale vacío.
        meetings = client.get(MEETINGS_URL)
        assert meetings.status_code == status.HTTP_200_OK
        assert meetings.data['results'] == []

    def test_support_does_not_reach_cells(self, church, make_user):
        support = make_user('consejeria@genesisapp.org', RoleType.SUPPORT)

        assert get_accessible_cell_ids(support) == set()
        assert not can_reach_cell(support, church['cell_a'].id)

        res = _client(support).get(MY_CELLS_URL)
        assert res.status_code == status.HTTP_200_OK
        assert res.data['results'] == []

    def test_pastor_still_reaches_every_cell(self, church):
        """Quien sí supervisa grupos conserva el alcance completo."""
        assert get_accessible_cell_ids(church['pastor']) is None
        assert can_manage_cell(church['pastor'], church['cell_z'].id)


@pytest.mark.django_db
class TestNotificationManagementScope:
    def test_pastor_manages_the_communications_list(self, church):
        """
        El pastor gestiona comunicados, no sólo recibe los suyos.

        Antes el listado administrativo estaba limitado al superadministrador,
        así que veía la sección con su feed personal y nada que gestionar.
        """
        from apps.notifications.models import (
            Notification,
            NotificationStatus,
            TargetAudience,
        )

        Notification.objects.create(
            title='Programada', body='x',
            target_audience=TargetAudience.ALL,
            status=NotificationStatus.PENDING,
        )

        res = _client(church['pastor']).get(
            reverse('notifications-list'), {'admin_view': 'true'}
        )
        assert res.status_code == status.HTTP_200_OK
        assert any(n['title'] == 'Programada' for n in res.data['results'])

    def test_leader_only_receives_its_own_feed(self, church):
        """Pedir admin_view sin el permiso no amplía nada."""
        from apps.notifications.models import (
            Notification,
            NotificationStatus,
            TargetAudience,
        )

        Notification.objects.create(
            title='Interna del pastorado', body='x',
            target_audience=TargetAudience.ALL,
            status=NotificationStatus.PENDING,
        )

        res = _client(church['leader_a']).get(
            reverse('notifications-list'), {'admin_view': 'true'}
        )
        assert res.status_code == status.HTTP_200_OK
        # Sólo las enviadas y dirigidas a él: nunca las pendientes de gestión.
        assert all(n['title'] != 'Interna del pastorado' for n in res.data['results'])


@pytest.mark.django_db
class TestMemberScope:
    def test_member_cannot_use_management_endpoints(self, church):
        """
        Consulta la vida de su célula, pero no la administra.

        El seguimiento pastoral son notas sobre la persona: las escribe y las
        lee quien la acompaña, no ella misma.
        """
        client = _client(church['member_a'])

        assert client.get(FOLLOWUPS_URL).status_code == status.HTTP_403_FORBIDDEN
        assert client.post(
            MEETINGS_URL, {'cell': church['cell_a'].id, 'date': '2026-08-09'}, format='json'
        ).status_code == status.HTTP_403_FORBIDDEN
        assert client.post(
            REPORTS_URL,
            {'cell': church['cell_a'].id, 'period_start': '2026-08-01',
             'period_end': '2026-08-31', 'summary': 'x'},
            format='json',
        ).status_code == status.HTTP_403_FORBIDDEN

    def test_member_cannot_register_people(self, church):
        res = _client(church['member_a']).post(
            cell_url('register-member', church['cell_a'].id),
            {'first_name': 'Colado'},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_member_scope_is_reported_in_me(self, church):
        res = _client(church['member_a']).get(reverse('auth_me'))
        assert res.status_code == status.HTTP_200_OK
        assert res.data['scope']['scope'] == AccessScope.SELF
        assert res.data['scope']['church_wide'] is False
        assert res.data['can_access_admin'] is False


REPORTS_URL = reverse('cell-reports-list')


@pytest.mark.django_db
class TestMemberRemoval:
    """Retirar de la célula no es eliminar del sistema."""

    def test_leader_removes_member_without_deleting_the_person(self, church):
        member = church['member_a']
        cell = church['cell_a']

        res = _client(church['leader_a']).post(
            cell_url('remove-member', cell.id),
            {'member_id': member.id},
            format='json',
        )
        assert res.status_code == status.HTTP_200_OK

        member.refresh_from_db()
        assert member.assigned_cell_id is None
        # La cuenta sigue existiendo: sólo dejó de pertenecer al grupo.
        assert User.objects.filter(id=member.id).exists()

    def test_removal_keeps_the_attendance_history(self, church):
        cell, member = church['cell_a'], church['member_a']
        meeting = CellMeeting.objects.create(cell=cell, date='2026-08-20')
        Attendance.objects.create(meeting=meeting, member=member, status=AttendanceStatus.PRESENT)

        _client(church['leader_a']).post(
            cell_url('remove-member', cell.id), {'member_id': member.id}, format='json'
        )

        assert Attendance.objects.filter(member=member).count() == 1

    def test_leader_cannot_remove_from_another_cell(self, church):
        outsider = church['member_z']

        res = _client(church['leader_a']).post(
            cell_url('remove-member', church['cell_z'].id),
            {'member_id': outsider.id},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN

        outsider.refresh_from_db()
        assert outsider.assigned_cell_id == church['cell_z'].id

    def test_coordinator_does_not_compose_the_cell(self, church):
        """Supervisa; componer el grupo es del líder."""
        res = _client(church['coordinator']).post(
            cell_url('remove-member', church['cell_a'].id),
            {'member_id': church['member_a'].id},
            format='json',
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.django_db
class TestCellReports:
    """El líder informa de su célula y la supervisión responde."""

    def _draft(self, church, leader=None):
        return _client(leader or church['leader_a']).post(
            REPORTS_URL,
            {
                'cell': church['cell_a'].id,
                'period_start': '2026-08-01',
                'period_end': '2026-08-31',
                'summary': 'Buen mes, creció la asistencia.',
                'highlights': 'Dos personas nuevas.',
                'challenges': 'Cuesta la puntualidad.',
                'prayer_needs': 'Por la salud de una hermana.',
            },
            format='json',
        )

    def test_leader_writes_and_sends_a_report(self, church):
        created = self._draft(church)
        assert created.status_code == status.HTTP_201_CREATED
        assert created.data['status'] == 'DRAFT'

        report_id = created.data['id']
        sent = _client(church['leader_a']).post(f'{REPORTS_URL}{report_id}/send/')
        assert sent.status_code == status.HTTP_200_OK
        assert sent.data['status'] == 'SENT'
        assert sent.data['sent_at'] is not None

    def test_sending_does_not_attach_figures_to_the_report(self, church):
        """
        El informe entrega lo que el líder escribe, no cifras calculadas.

        Antes se congelaban tres —reuniones, asistencia media y altas— sobre el
        periodo. No las leía nadie, y desde que el informe es de un solo día
        salían casi siempre en cero: la fecha que elige el líder es la del día
        que escribe, no la de una reunión registrada. Los indicadores de verdad
        se piden a /cells/<id>/statistics/, que los calcula al momento.
        """
        cell = church['cell_a']
        meeting = CellMeeting.objects.create(cell=cell, date='2026-08-10')
        Attendance.objects.create(
            meeting=meeting, member=church['member_a'], status=AttendanceStatus.PRESENT
        )

        report_id = self._draft(church).data['id']
        sent = _client(church['leader_a']).post(f'{REPORTS_URL}{report_id}/send/')

        assert sent.status_code == status.HTTP_200_OK
        assert sent.data['meetings_held'] == 0
        assert sent.data['average_attendance'] == 0
        assert sent.data['new_members'] == 0
        # Lo que sí entrega es el texto y la marca de envío.
        assert sent.data['summary']
        assert sent.data['sent_at'] is not None

    def test_a_sent_report_can_no_longer_be_edited(self, church):
        report_id = self._draft(church).data['id']
        _client(church['leader_a']).post(f'{REPORTS_URL}{report_id}/send/')

        res = _client(church['leader_a']).patch(
            f'{REPORTS_URL}{report_id}/', {'summary': 'Cambiado'}, format='json'
        )
        assert res.status_code == status.HTTP_400_BAD_REQUEST

    def test_coordinator_reads_and_answers_the_report(self, church):
        report_id = self._draft(church).data['id']
        _client(church['leader_a']).post(f'{REPORTS_URL}{report_id}/send/')

        listing = _client(church['coordinator']).get(REPORTS_URL)
        assert listing.status_code == status.HTTP_200_OK
        assert len(listing.data['results']) == 1

        reviewed = _client(church['coordinator']).post(
            f'{REPORTS_URL}{report_id}/review/',
            {'review_notes': 'Bien hecho, seguimos orando por esa hermana.'},
            format='json',
        )
        assert reviewed.status_code == status.HTTP_200_OK
        assert reviewed.data['status'] == 'REVIEWED'
        assert reviewed.data['reviewed_by']['email'] == church['coordinator'].email

    def test_leader_does_not_review_its_own_report(self, church):
        report_id = self._draft(church).data['id']
        _client(church['leader_a']).post(f'{REPORTS_URL}{report_id}/send/')

        res = _client(church['leader_a']).post(
            f'{REPORTS_URL}{report_id}/review/', {'review_notes': 'Me apruebo'}, format='json'
        )
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_a_foreign_leader_never_sees_the_report(self, church):
        report_id = self._draft(church).data['id']
        _client(church['leader_a']).post(f'{REPORTS_URL}{report_id}/send/')

        listing = _client(church['outsider_leader']).get(REPORTS_URL)
        assert listing.data['results'] == []
        assert _client(church['outsider_leader']).get(
            f'{REPORTS_URL}{report_id}/'
        ).status_code == status.HTTP_404_NOT_FOUND

    def test_report_period_must_be_coherent(self, church):
        res = _client(church['leader_a']).post(
            REPORTS_URL,
            {
                'cell': church['cell_a'].id,
                'period_start': '2026-08-31',
                'period_end': '2026-08-01',
                'summary': 'x',
            },
            format='json',
        )
        assert res.status_code == status.HTTP_400_BAD_REQUEST
        assert 'period_end' in res.data


@pytest.mark.django_db
class TestCellReportPhoto:
    """La foto de la actividad acompaña al informe hasta quien lo revisa."""

    @staticmethod
    def _image():
        """Un PNG mínimo válido, suficiente para ejercitar la subida."""
        import io

        from django.core.files.uploadedfile import SimpleUploadedFile
        from PIL import Image

        buffer = io.BytesIO()
        Image.new('RGB', (8, 8), color=(212, 175, 55)).save(buffer, format='PNG')
        buffer.seek(0)
        return SimpleUploadedFile('reunion.png', buffer.read(), content_type='image/png')

    def test_leader_attaches_a_photo_and_the_reviewer_sees_it(self, church):
        created = _client(church['leader_a']).post(
            REPORTS_URL,
            {
                'cell': church['cell_a'].id,
                'period_start': '2026-09-01',
                'period_end': '2026-09-30',
                'summary': 'Buen mes.',
                'photo': self._image(),
                'photo_caption': 'La reunión del jueves',
            },
            format='multipart',
        )
        assert created.status_code == status.HTTP_201_CREATED
        assert created.data['photo_url'], 'el informe debe devolver la dirección de la foto'
        assert created.data['photo_caption'] == 'La reunión del jueves'

        report_id = created.data['id']
        _client(church['leader_a']).post(f'{REPORTS_URL}{report_id}/send/')

        # Quien revisa recibe la imagen junto al texto
        seen = _client(church['coordinator']).get(f'{REPORTS_URL}{report_id}/')
        assert seen.status_code == status.HTTP_200_OK
        assert seen.data['photo_url']
        assert seen.data['photo_url'].startswith('http')
        assert seen.data['photo_caption'] == 'La reunión del jueves'

    def test_report_without_photo_is_still_valid(self, church):
        """La imagen es opcional: un informe sólo de texto sigue sirviendo."""
        created = _client(church['leader_a']).post(
            REPORTS_URL,
            {
                'cell': church['cell_a'].id,
                'period_start': '2026-10-01',
                'period_end': '2026-10-31',
                'summary': 'Sin fotos este mes.',
            },
            format='json',
        )
        assert created.status_code == status.HTTP_201_CREATED
        assert created.data['photo_url'] is None

    def test_a_foreign_leader_cannot_see_the_photo(self, church):
        created = _client(church['leader_a']).post(
            REPORTS_URL,
            {
                'cell': church['cell_a'].id,
                'period_start': '2026-11-01',
                'period_end': '2026-11-30',
                'summary': 'Con foto.',
                'photo': self._image(),
            },
            format='multipart',
        )
        report_id = created.data['id']
        _client(church['leader_a']).post(f'{REPORTS_URL}{report_id}/send/')

        res = _client(church['outsider_leader']).get(f'{REPORTS_URL}{report_id}/')
        assert res.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.django_db
class TestMemberCanFollowItsOwnCell:
    """
    El miembro consulta la vida de su célula desde la app.

    Su especificación le permite consultar reuniones y actividades; consultar
    se autoriza por alcance, no por permiso del catálogo.
    """

    def test_member_sees_the_meetings_of_its_own_cell(self, church):
        CellMeeting.objects.create(cell=church['cell_a'], date='2026-09-07', topic='Propia')
        CellMeeting.objects.create(cell=church['cell_b'], date='2026-09-07', topic='Ajena')

        res = _client(church['member_a']).get(MEETINGS_URL)
        assert res.status_code == status.HTTP_200_OK

        topics = [m['topic'] for m in res.data['results']]
        assert topics == ['Propia'], 'sólo debe ver las de su célula'

    def test_member_cannot_open_a_meeting_of_another_cell(self, church):
        foreign = CellMeeting.objects.create(cell=church['cell_b'], date='2026-09-08')

        res = _client(church['member_a']).get(f'{MEETINGS_URL}{foreign.id}/')
        assert res.status_code == status.HTTP_404_NOT_FOUND

    def test_member_still_cannot_register_or_modify_meetings(self, church):
        """Consultar sí; registrar y borrar siguen siendo del líder."""
        client = _client(church['member_a'])
        meeting = CellMeeting.objects.create(cell=church['cell_a'], date='2026-09-09')

        assert client.post(
            MEETINGS_URL, {'cell': church['cell_a'].id, 'date': '2026-09-10'}, format='json'
        ).status_code == status.HTTP_403_FORBIDDEN
        assert client.patch(
            f'{MEETINGS_URL}{meeting.id}/', {'topic': 'Cambiado'}, format='json'
        ).status_code == status.HTTP_403_FORBIDDEN
        assert client.delete(
            f'{MEETINGS_URL}{meeting.id}/'
        ).status_code == status.HTTP_403_FORBIDDEN
        assert client.post(
            f'{MEETINGS_URL}{meeting.id}/attendance/',
            {'attendances': [{'member_id': church['member_a'].id, 'status': 'PRESENT'}]},
            format='json',
        ).status_code == status.HTTP_403_FORBIDDEN

    def test_a_person_without_cell_sees_nothing(self, church, make_user):
        stray = make_user('sin.celula@genesisapp.org', RoleType.MEMBER)
        CellMeeting.objects.create(cell=church['cell_a'], date='2026-09-11')

        res = _client(stray).get(MEETINGS_URL)
        assert res.status_code == status.HTTP_200_OK
        assert res.data['results'] == []

    def test_member_still_has_no_admin_panel(self, church):
        """Abrir las reuniones no le abre el panel."""
        res = _client(church['member_a']).get(reverse('auth_me'))
        assert res.data['can_access_admin'] is False
