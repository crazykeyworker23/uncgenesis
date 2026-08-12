"""
Entrega push: a quién llega cada aviso.

Antes la "notificación" sólo se marcaba como enviada en la base de datos y la
app la descubría sondeando mientras estaba abierta: con la aplicación cerrada
no llegaba nada. Estas pruebas fijan a qué dispositivos sale cada tipo de aviso
y qué ocurre cuando no hay credenciales.
"""

import pytest
from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.cells.models import CellGroup, MeetingDay
from apps.notifications.models import (
    FCMDevice,
    Notification,
    NotificationStatus,
    TargetAudience,
)
from apps.notifications.push import resolve_target_tokens, send_notification
from apps.roles.models import Role, RoleType, UserRole

User = get_user_model()


@pytest.fixture
def con_dispositivo(db):
    def _make(email, role_name=None, token=None):
        user = User.objects.create_user(email=email, password='Clave.Solida.2026')
        if role_name:
            role, _ = Role.objects.get_or_create(name=role_name, defaults={'description': role_name})
            UserRole.objects.create(user=user, role=role)
        FCMDevice.objects.create(user=user, token=token or f'token-{email}', device_type='ANDROID')
        return user
    return _make


@pytest.mark.django_db
class TestAQuienLlega:
    def test_aviso_a_una_persona_solo_llega_a_sus_dispositivos(self, con_dispositivo):
        destinatario = con_dispositivo('destino@push.org', RoleType.MEMBER)
        con_dispositivo('otro@push.org', RoleType.MEMBER)

        aviso = Notification.objects.create(
            title='Personal', body='x',
            target_audience=TargetAudience.USER,
            target_user=destinatario,
        )

        assert resolve_target_tokens(aviso) == ['token-destino@push.org']

    def test_recordatorio_de_celula_llega_a_sus_miembros_y_al_lider(self, con_dispositivo):
        lider = con_dispositivo('lider@push.org', RoleType.CELL_LEADER)
        celula = CellGroup.objects.create(
            name='Norte', leader=lider,
            meeting_day=MeetingDay.MONDAY, meeting_time='19:00', address='x',
        )

        miembro = con_dispositivo('miembro@push.org', RoleType.MEMBER)
        miembro.assigned_cell = celula
        miembro.save()

        ajeno = con_dispositivo('ajeno@push.org', RoleType.MEMBER)

        aviso = Notification.objects.create(
            title='Reunión', body='x',
            target_audience=TargetAudience.CELL,
            target_cell=celula,
        )

        tokens = set(resolve_target_tokens(aviso))
        assert tokens == {'token-lider@push.org', 'token-miembro@push.org'}
        assert f'token-{ajeno.email}' not in tokens

    def test_aviso_a_lideres_no_alcanza_a_los_miembros(self, con_dispositivo):
        con_dispositivo('l1@push.org', RoleType.CELL_LEADER)
        con_dispositivo('m1@push.org', RoleType.MEMBER)

        aviso = Notification.objects.create(
            title='Sólo líderes', body='x', target_audience=TargetAudience.LEADERS
        )

        assert resolve_target_tokens(aviso) == ['token-l1@push.org']

    def test_aviso_general_alcanza_incluso_al_invitado(self, con_dispositivo, db):
        con_dispositivo('con.cuenta@push.org', RoleType.MEMBER)
        # Un teléfono sin sesión iniciada también queda registrado.
        FCMDevice.objects.create(user=None, token='token-invitado', device_type='ANDROID')

        aviso = Notification.objects.create(
            title='Para todos', body='x', target_audience=TargetAudience.ALL
        )

        tokens = set(resolve_target_tokens(aviso))
        assert 'token-invitado' in tokens
        assert 'token-con.cuenta@push.org' in tokens


@pytest.mark.django_db
class TestSinCredenciales:
    def test_el_aviso_se_registra_aunque_no_haya_credenciales(self, settings, con_dispositivo):
        """
        Sin Firebase configurado el sistema no debe romperse: la notificación
        se guarda y se ve dentro de la app, y queda anotado el motivo.
        """
        settings.FIREBASE_CREDENTIALS = None
        con_dispositivo('alguien@push.org', RoleType.MEMBER)

        aviso = Notification.objects.create(
            title='Sin credenciales', body='x', target_audience=TargetAudience.ALL
        )

        resultado = send_notification(aviso)
        assert resultado['sent'] == 0
        assert 'FIREBASE_CREDENTIALS' in resultado['detail']

    def test_la_tarea_marca_el_aviso_como_enviado(self, settings, con_dispositivo):
        from apps.notifications.tasks import send_push_notification_task

        settings.FIREBASE_CREDENTIALS = None
        aviso = Notification.objects.create(
            title='Registrado', body='x',
            target_audience=TargetAudience.ALL,
            status=NotificationStatus.PENDING,
        )

        send_push_notification_task(aviso.id)

        aviso.refresh_from_db()
        assert aviso.status == NotificationStatus.SENT
        assert aviso.sent_at is not None
        # El motivo queda registrado para poder diagnosticarlo.
        assert 'FIREBASE_CREDENTIALS' in aviso.error_message


@pytest.mark.django_db
class TestEnvioReal:
    def test_se_envia_a_cada_dispositivo_y_se_da_de_baja_el_token_muerto(
        self, settings, con_dispositivo, monkeypatch
    ):
        """
        Un teléfono que desinstaló la app deja un token inservible; conservarlo
        haría fallar una parte de cada envío futuro.
        """
        from firebase_admin import exceptions as fb_exceptions
        from firebase_admin import messaging

        from apps.notifications import push

        con_dispositivo('vivo@push.org', RoleType.MEMBER, token='token-vivo')
        con_dispositivo('muerto@push.org', RoleType.MEMBER, token='token-muerto')

        monkeypatch.setattr(push, 'get_firebase_app', lambda: object())

        class Respuesta:
            def __init__(self, success, exception=None):
                self.success = success
                self.exception = exception

        class Resultado:
            def __init__(self, responses):
                self.responses = responses
                self.success_count = sum(1 for r in responses if r.success)
                self.failure_count = sum(1 for r in responses if not r.success)

        enviados = {}

        def falso_envio(mensajes, app=None):
            enviados['tokens'] = [m.token for m in mensajes]
            return Resultado([
                Respuesta(True) if m.token == 'token-vivo'
                else Respuesta(False, fb_exceptions.NotFoundError('not-found', 'registro no existe'))
                for m in mensajes
            ])

        monkeypatch.setattr(messaging, 'send_each', falso_envio)

        aviso = Notification.objects.create(
            title='Real', body='x', target_audience=TargetAudience.ALL
        )
        resultado = send_notification(aviso)

        assert set(enviados['tokens']) == {'token-vivo', 'token-muerto'}
        assert resultado['sent'] == 1
        assert resultado['failed'] == 1
        # El token inservible desaparece; el bueno se conserva.
        assert not FCMDevice.objects.filter(token='token-muerto').exists()
        assert FCMDevice.objects.filter(token='token-vivo').exists()

    def test_el_mensaje_lleva_la_vista_que_debe_abrirse(self, con_dispositivo, monkeypatch):
        """
        Con la app cerrada, tocar el aviso es la única interacción posible: el
        destino tiene que viajar dentro del mensaje.
        """
        from firebase_admin import messaging

        from apps.notifications import push

        con_dispositivo('lector@push.org', RoleType.MEMBER, token='token-lector')
        monkeypatch.setattr(push, 'get_firebase_app', lambda: object())

        capturado = {}

        class Resultado:
            responses = []
            success_count = 1
            failure_count = 0

        def falso_envio(mensajes, app=None):
            capturado['data'] = mensajes[0].data
            return Resultado()

        monkeypatch.setattr(messaging, 'send_each', falso_envio)

        aviso = Notification.objects.create(
            title='Devocional', body='x',
            target_audience=TargetAudience.ALL,
            deep_link='/devotionals/pan-de-vida',
        )
        send_notification(aviso)

        assert capturado['data']['deep_link'] == '/devotionals/pan-de-vida'
        assert capturado['data']['click_action'] == 'FLUTTER_NOTIFICATION_CLICK'

    def test_el_resultado_del_envio_queda_anotado_en_el_aviso(self, settings, con_dispositivo):
        """
        Antes el envío se encolaba en Celery: si el trabajador estaba caído la
        tarea se quedaba en la cola sin ejecutarse y el panel seguía mostrando
        «enviado». El fallo era indistinguible de un envío correcto.
        """
        from apps.notifications.push import dispatch

        settings.FIREBASE_CREDENTIALS = None
        con_dispositivo('alguien@push.org', RoleType.MEMBER)

        aviso = Notification.objects.create(
            title='Comunicado', body='x',
            target_audience=TargetAudience.ALL,
            status=NotificationStatus.PENDING,
        )

        dispatch(aviso)

        aviso.refresh_from_db()
        assert aviso.status == NotificationStatus.SENT
        assert aviso.sent_at is not None
        # El motivo por el que no salió al teléfono queda a la vista.
        assert 'FIREBASE_CREDENTIALS' in aviso.error_message

    def test_un_envio_correcto_no_deja_motivo_de_error(self, con_dispositivo, monkeypatch):
        from firebase_admin import messaging

        from apps.notifications import push
        from apps.notifications.push import dispatch

        con_dispositivo('recibe@push.org', RoleType.MEMBER, token='token-ok')
        monkeypatch.setattr(push, 'get_firebase_app', lambda: object())

        class Resultado:
            responses = []
            success_count = 1
            failure_count = 0

        monkeypatch.setattr(messaging, 'send_each', lambda mensajes, app=None: Resultado())

        aviso = Notification.objects.create(
            title='Va bien', body='x', target_audience=TargetAudience.ALL
        )
        dispatch(aviso)

        aviso.refresh_from_db()
        assert aviso.error_message == ''
        assert aviso.status == NotificationStatus.SENT

    def test_sin_dispositivos_no_falla(self, settings, monkeypatch, db):
        from apps.notifications import push

        monkeypatch.setattr(push, 'get_firebase_app', lambda: object())

        aviso = Notification.objects.create(
            title='Nadie', body='x', target_audience=TargetAudience.ALL
        )
        resultado = send_notification(aviso)

        assert resultado['sent'] == 0
        assert 'dispositivos' in resultado['detail']


@pytest.mark.django_db
class TestQuienEnviaNoSeRecibe:
    """
    El aviso sale para los demás, no para quien lo escribe.

    Recibir en el propio teléfono el mensaje que uno acaba de mandar no informa
    de nada, y encima hace dudar de si salió de verdad o volvió por un fallo.
    """

    @pytest.fixture
    def celula_con_lider(self, con_dispositivo):
        def _make():
            lider = con_dispositivo('lider.envia@push.org', RoleType.CELL_LEADER)
            celula = CellGroup.objects.create(
                name='Norte', leader=lider,
                meeting_day=MeetingDay.MONDAY, meeting_time='19:00', address='x',
            )
            miembro = con_dispositivo('miembro.recibe@push.org', RoleType.MEMBER)
            miembro.assigned_cell = celula
            miembro.save()
            return lider, celula, miembro
        return _make

    def test_el_lider_no_recibe_el_recordatorio_que_el_mismo_manda(self, celula_con_lider):
        lider, celula, _ = celula_con_lider()

        aviso = Notification.objects.create(
            title='Nos vemos el jueves', body='x',
            target_audience=TargetAudience.CELL,
            target_cell=celula,
            sender=lider,
        )

        assert resolve_target_tokens(aviso) == ['token-miembro.recibe@push.org']

    def test_el_lider_si_lo_recibe_cuando_se_lo_manda_su_coordinador(
        self, celula_con_lider, con_dispositivo
    ):
        """Del recordatorio de arriba tiene que enterarse como el que más."""
        lider, celula, _ = celula_con_lider()
        coordinador = con_dispositivo('coord.envia@push.org', RoleType.COORDINATOR)

        aviso = Notification.objects.create(
            title='Aviso de tu coordinador', body='x',
            target_audience=TargetAudience.CELL,
            target_cell=celula,
            sender=coordinador,
        )

        tokens = resolve_target_tokens(aviso)
        assert 'token-lider.envia@push.org' in tokens
        assert 'token-miembro.recibe@push.org' in tokens
        # Y el coordinador tampoco se recibe a sí mismo.
        assert 'token-coord.envia@push.org' not in tokens

    def test_el_pastor_no_recibe_su_propia_difusion(self, con_dispositivo):
        pastor = con_dispositivo('pastor@push.org', RoleType.ADMIN)
        con_dispositivo('feligres@push.org', RoleType.MEMBER)

        aviso = Notification.objects.create(
            title='Culto del domingo', body='x',
            target_audience=TargetAudience.ALL,
            sender=pastor,
        )

        tokens = resolve_target_tokens(aviso)
        assert 'token-feligres@push.org' in tokens
        assert 'token-pastor@push.org' not in tokens

    def test_el_invitado_sigue_recibiendo_la_difusion(self, con_dispositivo, db):
        """
        Apartar a quien envía no puede llevarse por delante a los invitados.

        Sus dispositivos no tienen cuenta asociada, y en SQL comparar un nulo
        no da ni verdadero ni falso: un `exclude` a secas los habría descartado
        en silencio, dejando sin avisos a toda la gente que usa la app sin
        registrarse.
        """
        pastor = con_dispositivo('pastor2@push.org', RoleType.ADMIN)
        FCMDevice.objects.create(token='token-invitado', device_type='ANDROID')

        aviso = Notification.objects.create(
            title='Abierto a todos', body='x',
            target_audience=TargetAudience.ALL,
            sender=pastor,
        )

        tokens = resolve_target_tokens(aviso)
        assert 'token-invitado' in tokens
        assert 'token-pastor2@push.org' not in tokens

    def test_un_aviso_sin_remitente_llega_a_todos(self, con_dispositivo):
        """El remitente puede haberse dado de baja; el aviso sigue saliendo."""
        con_dispositivo('alguien@push.org', RoleType.MEMBER)

        aviso = Notification.objects.create(
            title='Automático', body='x',
            target_audience=TargetAudience.ALL,
            sender=None,
        )

        assert 'token-alguien@push.org' in resolve_target_tokens(aviso)

    def test_escribirse_a_uno_mismo_si_llega(self, con_dispositivo):
        """Dirigir un aviso a una persona concreta es una decisión expresa."""
        alguien = con_dispositivo('yo@push.org', RoleType.MEMBER)

        aviso = Notification.objects.create(
            title='Nota para mí', body='x',
            target_audience=TargetAudience.USER,
            target_user=alguien,
            sender=alguien,
        )

        assert resolve_target_tokens(aviso) == ['token-yo@push.org']


@pytest.mark.django_db
class TestAvisosProgramados:
    """
    La ronda de repesca recoge lo que quedó pendiente, sin repetir envíos.

    Dos caminos pueden pedir el mismo envío: la tarea que se programó para la
    hora del aviso y esta ronda periódica. Que ninguno de los dos duplique el
    aviso en el teléfono de la gente es lo que se fija aquí.
    """

    @pytest.fixture
    def envios(self, monkeypatch):
        """Cuenta los envíos sin llegar a contactar con Firebase."""
        from apps.notifications import tasks

        realizados = []

        def _falso_envio(notification):
            realizados.append(notification.id)
            return {'sent': 1, 'failed': 0, 'detail': 'Entregada a 1 dispositivo(s).'}

        monkeypatch.setattr(tasks, 'send_notification', _falso_envio)
        return realizados

    def test_un_aviso_ya_entregado_no_sale_dos_veces(self, envios):
        from apps.notifications.tasks import send_push_notification_task

        aviso = Notification.objects.create(
            title='Una sola vez', body='x',
            target_audience=TargetAudience.ALL,
            status=NotificationStatus.PENDING,
            scheduled_for=timezone.now(),
        )

        send_push_notification_task(aviso.id)
        send_push_notification_task(aviso.id)

        assert envios == [aviso.id]

    def test_la_ronda_entrega_lo_vencido_y_respeta_lo_que_falta(self, envios):
        from apps.notifications.tasks import deliver_pending_notifications

        vencido = Notification.objects.create(
            title='Se pasó la hora', body='x',
            target_audience=TargetAudience.ALL,
            status=NotificationStatus.PENDING,
            scheduled_for=timezone.now() - timezone.timedelta(minutes=10),
        )
        Notification.objects.create(
            title='Todavía no toca', body='x',
            target_audience=TargetAudience.ALL,
            status=NotificationStatus.PENDING,
            scheduled_for=timezone.now() + timezone.timedelta(hours=3),
        )

        assert deliver_pending_notifications() == 1
        assert envios == [vencido.id]

        vencido.refresh_from_db()
        assert vencido.status == NotificationStatus.SENT
        assert vencido.sent_at is not None

    def test_la_ronda_no_repite_lo_que_ya_salio(self, envios):
        from apps.notifications.tasks import deliver_pending_notifications

        Notification.objects.create(
            title='Reintento', body='x',
            target_audience=TargetAudience.ALL,
            status=NotificationStatus.PENDING,
            scheduled_for=timezone.now() - timezone.timedelta(minutes=10),
        )

        deliver_pending_notifications()
        # La segunda vuelta de Celery Beat ya no encuentra nada pendiente.
        assert deliver_pending_notifications() == 0
        assert len(envios) == 1
