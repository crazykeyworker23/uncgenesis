"""
Revisa por qué un aviso no llega al teléfono.

Cuando una notificación no aparece, la causa puede estar en cuatro sitios
distintos y desde fuera son indistinguibles: falta la clave de Firebase, no hay
ningún teléfono registrado, el trabajador de Celery está caído y las tareas se
quedan encoladas, o Firebase rechaza el envío. Esto los comprueba uno a uno.

    python manage.py diagnostico_push

No envía nada a nadie: la comprobación contra Firebase es en seco.
"""

from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = 'Comprueba por qué las notificaciones push no llegan al teléfono.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--enviar-a',
            dest='enviar_a',
            help=(
                'Correo de una persona a la que mandar un aviso de prueba de verdad. '
                'Sin esta opción no se envía nada.'
            ),
        )

    def handle(self, *args, **options):
        self._titulo('0. Base de datos al día')
        if not self._revisar_migraciones():
            return

        self._titulo('1. Clave de Firebase')
        app = self._revisar_credenciales()

        self._titulo('2. Teléfonos registrados')
        self._revisar_dispositivos()

        self._titulo('3. Trabajador de Celery')
        self._revisar_celery()

        self._titulo('4. Últimos avisos enviados')
        self._revisar_historial()

        if app is not None:
            self._titulo('5. Conexión con Firebase')
            self._revisar_conexion(app)

        destinatario = options.get('enviar_a')
        if destinatario:
            self._titulo('6. Envío de prueba')
            self._enviar_prueba(destinatario)

    # ── comprobaciones ──────────────────────────────────────────────────────

    def _revisar_migraciones(self):
        """
        Sin las migraciones aplicadas no tiene sentido seguir: el código nuevo
        pregunta por columnas que la base todavía no tiene y todo lo demás
        fallaría con un error confuso.
        """
        from django.db import connection
        from django.db.migrations.executor import MigrationExecutor

        try:
            executor = MigrationExecutor(connection)
            pendientes = executor.migration_plan(executor.loader.graph.leaf_nodes())
        except Exception as error:
            self._mal(f'No se pudo comprobar el estado de la base de datos: {error}')
            return False

        if pendientes:
            self._mal(f'Faltan {len(pendientes)} migración(es) por aplicar.')
            for migracion, _ in pendientes[:10]:
                self._info(f'{migracion.app_label}.{migracion.name}')
            self._pista('Aplícalas con:\n    docker compose exec backend python manage.py migrate')
            return False

        self._bien('Todas las migraciones están aplicadas.')
        return True

    def _revisar_credenciales(self):
        from django.conf import settings

        from apps.notifications.push import get_firebase_app

        valor = getattr(settings, 'FIREBASE_CREDENTIALS', None)
        if not valor:
            self._mal(
                'FIREBASE_CREDENTIALS no está configurada. Los avisos se guardan y se '
                'ven dentro de la app, pero no salen al teléfono.'
            )
            self._pista(
                'Pon la clave en backend/secrets/firebase.json y añade al .env:\n'
                '    FIREBASE_CREDENTIALS=/app/secrets/firebase.json\n'
                'Después "docker compose up -d" para recrear los contenedores.'
            )
            return None

        if isinstance(valor, str):
            self._bien(f'Se lee desde el archivo {valor}')
        else:
            self._bien(f'JSON en línea, proyecto {valor.get("project_id")}')

        app = get_firebase_app()
        if app is None:
            self._mal('La clave existe pero Firebase no la acepta (revisa el registro del servidor).')
            return None

        self._bien('Firebase se inicializó correctamente.')
        return app

    def _revisar_dispositivos(self):
        from apps.notifications.models import FCMDevice

        total = FCMDevice.objects.count()
        if total == 0:
            self._mal('No hay ningún teléfono registrado: no hay a quién enviar.')
            self._pista(
                'Abre la app una vez con este servidor configurado y acepta el permiso '
                'de notificaciones. El registro es automático.'
            )
            return

        con_cuenta = FCMDevice.objects.filter(user__isnull=False).count()
        self._bien(f'{total} teléfono(s): {con_cuenta} con sesión, {total - con_cuenta} en modo invitado.')

    def _revisar_celery(self):
        try:
            from config.celery import app as celery_app

            respuesta = celery_app.control.ping(timeout=3)
        except Exception as error:
            self._mal(f'No se pudo consultar a Celery: {error}')
            self._pista('Los avisos inmediatos se envían igualmente, pero los programados no saldrán.')
            return

        if not respuesta:
            self._mal('Ningún trabajador de Celery responde.')
            self._pista(
                'Los avisos quedan encolados y nadie los procesa. Revisa el contenedor:\n'
                '    docker compose ps celery_worker\n'
                '    docker compose logs --tail=50 celery_worker'
            )
            return

        self._bien(f'{len(respuesta)} trabajador(es) respondiendo.')

    def _revisar_historial(self):
        from apps.notifications.models import Notification

        ultimos = Notification.objects.order_by('-created_at')[:5]
        if not ultimos:
            self._info('Todavía no se ha creado ningún aviso.')
            return

        for aviso in ultimos:
            motivo = (aviso.error_message or '').strip()
            marca = '·' if not motivo else '!'
            self.stdout.write(f'  {marca} [{aviso.status}] {aviso.title[:52]}')
            if motivo:
                self.stdout.write(self.style.WARNING(f'      {motivo[:150]}'))

    def _revisar_conexion(self, app):
        from firebase_admin import exceptions, messaging

        mensaje = messaging.Message(
            token='token-de-comprobacion-que-no-existe',
            notification=messaging.Notification(title='x', body='x'),
        )
        try:
            messaging.send(mensaje, dry_run=True, app=app)
            self._bien('Firebase acepta las peticiones.')
        except (messaging.UnregisteredError, exceptions.InvalidArgumentError, exceptions.NotFoundError):
            # Rechaza el token falso, que es exactamente lo que debe hacer: para
            # llegar a rechazarlo ha tenido que autenticar la petición.
            self._bien('Firebase autentica correctamente al servidor.')
        except Exception as error:
            self._mal(f'Firebase rechaza al servidor: {type(error).__name__}: {error}')

    def _enviar_prueba(self, correo):
        from django.contrib.auth import get_user_model

        from apps.notifications.models import (
            FCMDevice,
            Notification,
            NotificationStatus,
            TargetAudience,
        )
        from apps.notifications.push import send_notification

        persona = get_user_model().objects.filter(email__iexact=correo).first()
        if persona is None:
            self._mal(f'No existe ninguna cuenta con el correo {correo}.')
            return

        if not FCMDevice.objects.filter(user=persona).exists():
            self._mal(f'{correo} no tiene ningún teléfono registrado.')
            self._pista('Que abra la app una vez y acepte el permiso de notificaciones.')
            return

        aviso = Notification.objects.create(
            title='Prueba de notificación',
            body='Si ves esto en el teléfono con la app cerrada, todo funciona.',
            target_audience=TargetAudience.USER,
            target_user=persona,
            deep_link='/notifications',
            status=NotificationStatus.SENT,
        )
        resultado = send_notification(aviso)

        if resultado['sent']:
            self._bien(resultado['detail'])
            self._pista('Cierra la app del todo y repite si quieres comprobar el tercer plano.')
        else:
            self._mal(resultado['detail'])

    # ── presentación ────────────────────────────────────────────────────────

    def _titulo(self, texto):
        self.stdout.write('')
        self.stdout.write(self.style.MIGRATE_HEADING(texto))

    def _bien(self, texto):
        self.stdout.write(self.style.SUCCESS(f'  OK  {texto}'))

    def _mal(self, texto):
        self.stdout.write(self.style.ERROR(f'  --> {texto}'))

    def _info(self, texto):
        self.stdout.write(f'  ·   {texto}')

    def _pista(self, texto):
        for linea in texto.split('\n'):
            self.stdout.write(self.style.WARNING(f'      {linea}'))
