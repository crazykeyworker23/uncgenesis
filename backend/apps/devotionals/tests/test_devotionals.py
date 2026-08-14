import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.devotionals.models import Devotional, DevotionalStatus
from apps.audit.models import AuditLog

User = get_user_model()


@pytest.fixture
def admin_user(superuser):
    return superuser


@pytest.fixture
def staff_client(api_client, superuser):
    from rest_framework_simplejwt.tokens import RefreshToken
    refresh = RefreshToken.for_user(superuser)
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return api_client


@pytest.fixture
def devotional(db, admin_user):
    return Devotional.objects.create(
        title="Buscando la Presencia de Dios",
        date=timezone.localdate(),
        bible_passage="Salmos 27:8",
        bible_text="Tu rostro buscaré, oh Jehová.",
        content="Reflexión diaria sobre la oración...",
        audio_url="https://spotify.com/mockaudio",
        author=admin_user,
        status=DevotionalStatus.DRAFT,
    )


@pytest.mark.django_db
def test_anonymous_read_devotionals(api_client, devotional):
    """
    Cualquiera (anónimo) debe poder ver los devocionales publicados, nunca los
    borradores.
    """
    url = reverse('devotional-list')
    detail_url = reverse('devotional-detail', kwargs={'pk': devotional.id})

    # En borrador no debe ser visible públicamente
    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] == 0
    assert api_client.get(detail_url).status_code == status.HTTP_404_NOT_FOUND

    # Una vez publicado sí
    devotional.status = DevotionalStatus.PUBLISHED
    devotional.save()

    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['count'] == 1

    response = api_client.get(detail_url)
    assert response.status_code == status.HTTP_200_OK

    devotional.refresh_from_db()
    assert devotional.views_count == 1


@pytest.mark.django_db
def test_create_devotional_with_permission(api_client, staff_client):
    """
    Un usuario con permisos DEVOTIONALS_CREATE puede registrar devocionales.
    """
    url = reverse('devotional-list')
    # Sumar un día para evitar choque de fecha única si ya hay uno hoy
    tomorrow = timezone.localdate() + timezone.timedelta(days=1)
    
    data = {
        "title": "Caminando en Amor",
        "date": str(tomorrow),
        "bible_passage": "Efesios 5:2",
        "bible_text": "Y andad en amor...",
        "content": "Estudio diario...",
        "status": "DRAFT"
    }
    
    # Anónimo bloqueado
    from rest_framework.test import APIClient
    anon_client = APIClient()
    response = anon_client.post(url, data, format='json')
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

    # Staff exitoso
    response = staff_client.post(url, data, format='json')
    assert response.status_code == status.HTTP_201_CREATED
    assert Devotional.objects.filter(title="Caminando en Amor").exists()
    
    # Audit log
    assert AuditLog.objects.filter(action="CREATE", module="DEVOTIONALS").exists()


@pytest.mark.django_db
def test_publish_and_archive_actions(staff_client, devotional):
    """
    Acciones de publicar y archivar devocionales.
    """
    publish_url = reverse('devotional-publish', kwargs={'pk': devotional.id})
    archive_url = reverse('devotional-archive', kwargs={'pk': devotional.id})

    # Publicar
    response = staff_client.post(publish_url)
    assert response.status_code == status.HTTP_200_OK
    devotional.refresh_from_db()
    assert devotional.status == DevotionalStatus.PUBLISHED

    # Archivar
    response = staff_client.post(archive_url)
    assert response.status_code == status.HTTP_200_OK
    devotional.refresh_from_db()
    assert devotional.status == DevotionalStatus.ARCHIVED


@pytest.mark.django_db
def test_today_devotional_endpoint(api_client, devotional):
    """
    Verifica el endpoint de devocional de hoy y fallback.
    """
    url = reverse('devotional-today')
    
    # 1. No hay devocionales publicados -> 404
    response = api_client.get(url)
    assert response.status_code == status.HTTP_404_NOT_FOUND

    # 2. Publicamos el devocional
    devotional.status = DevotionalStatus.PUBLISHED
    devotional.save()

    response = api_client.get(url)
    assert response.status_code == status.HTTP_200_OK
    assert response.data['title'] == devotional.title
    
    # Visita incrementada
    devotional.refresh_from_db()
    assert devotional.views_count == 1


@pytest.mark.django_db
def test_duplicate_devotional(staff_client, devotional):
    """
    Duplicación de devocionales calculando fecha disponible automáticamente.
    """
    url = reverse('devotional-duplicate', kwargs={'pk': devotional.id})
    response = staff_client.post(url)
    assert response.status_code == status.HTTP_201_CREATED
    
    cloned_id = response.data['id']
    cloned = Devotional.objects.get(id=cloned_id)
    assert cloned.title == f"Copia de {devotional.title}"
    assert cloned.status == DevotionalStatus.DRAFT
    assert cloned.date != devotional.date


WEEKLY_PLAN_URL = reverse('devotional-weekly-plan')
PUBLISH_WEEK_URL = reverse('devotional-publish-week')


def _plan(start='2026-08-10'):
    """Un plan como el que reparte la iglesia: un pasaje por día."""
    pasajes = [
        'Hebreos 13', '1 Samuel 16', '2 Samuel 6', 'Daniel 1',
        'Daniel 6', 'Lucas 1', 'Job 1',
    ]
    return {
        'start_date': start,
        'days': [{'bible_passage': p, 'content': f'Lee {p} y anota lo que te hable.'}
                 for p in pasajes],
    }


@pytest.mark.django_db
class TestPlanSemanal:
    """
    Cargar la semana de una vez.

    Antes eran siete formularios, cada uno pidiendo título, pasaje, el texto
    bíblico completo y una reflexión: inviable para un plan de lecturas que
    cambia cada semana.
    """

    def test_carga_los_siete_dias_como_borrador(self, staff_client):
        res = staff_client.post(WEEKLY_PLAN_URL, _plan(), format='json')

        assert res.status_code == status.HTTP_201_CREATED
        assert Devotional.objects.count() == 7
        # Ninguno sale a la calle hasta publicarlo: un error de dedo no manda
        # siete notificaciones equivocadas.
        assert Devotional.objects.filter(status=DevotionalStatus.DRAFT).count() == 7

    def test_cada_dia_cae_en_su_fecha(self, staff_client):
        staff_client.post(WEEKLY_PLAN_URL, _plan(), format='json')

        lunes = Devotional.objects.get(date='2026-08-10')
        domingo = Devotional.objects.get(date='2026-08-16')
        assert lunes.bible_passage == 'Hebreos 13'
        assert domingo.bible_passage == 'Job 1'

    def test_el_texto_biblico_ya_no_es_obligatorio(self, staff_client):
        """Se indica el pasaje a leer, no se transcribe el capítulo entero."""
        staff_client.post(WEEKLY_PLAN_URL, _plan(), format='json')

        assert Devotional.objects.get(date='2026-08-10').bible_text == ''

    def test_volver_a_cargar_la_semana_corrige_en_lugar_de_duplicar(self, staff_client):
        staff_client.post(WEEKLY_PLAN_URL, _plan(), format='json')

        corregido = _plan()
        corregido['days'][0]['bible_passage'] = 'Hebreos 12'
        staff_client.post(WEEKLY_PLAN_URL, corregido, format='json')

        assert Devotional.objects.count() == 7
        assert Devotional.objects.get(date='2026-08-10').bible_passage == 'Hebreos 12'

    def test_no_pisa_lo_que_ya_se_publico(self, staff_client, superuser):
        """Sobrescribir en silencio algo que la gente ya recibió seria peor."""
        Devotional.objects.create(
            title='Ya salió', date='2026-08-12', bible_passage='Salmo 23',
            content='x', author=superuser, status=DevotionalStatus.PUBLISHED,
        )

        res = staff_client.post(WEEKLY_PLAN_URL, _plan(), format='json')

        assert res.status_code == status.HTTP_400_BAD_REQUEST
        assert '2026-08-12' in res.data['error']
        assert Devotional.objects.get(date='2026-08-12').bible_passage == 'Salmo 23'

    def test_exige_los_siete_dias(self, staff_client):
        incompleto = _plan()
        incompleto['days'] = incompleto['days'][:3]

        res = staff_client.post(WEEKLY_PLAN_URL, incompleto, format='json')
        assert res.status_code == status.HTTP_400_BAD_REQUEST

    def test_se_puede_releer_para_corregirlo(self, staff_client):
        staff_client.post(WEEKLY_PLAN_URL, _plan(), format='json')

        res = staff_client.get(WEEKLY_PLAN_URL, {'start_date': '2026-08-10'})

        assert res.status_code == status.HTTP_200_OK
        assert len(res.data['days']) == 7
        assert res.data['days'][0]['weekday'] == 'Lunes'
        assert res.data['days'][0]['bible_passage'] == 'Hebreos 13'
        assert res.data['days'][6]['weekday'] == 'Domingo'

    def test_una_semana_vacia_se_devuelve_igual_para_poder_llenarla(self, staff_client):
        res = staff_client.get(WEEKLY_PLAN_URL, {'start_date': '2026-09-07'})

        assert res.status_code == status.HTTP_200_OK
        assert len(res.data['days']) == 7
        assert all(dia['id'] is None for dia in res.data['days'])


@pytest.mark.django_db
class TestPublicarPlanSemanal:
    def test_publica_los_siete_y_programa_sus_avisos(self, staff_client):
        from apps.notifications.models import Notification

        staff_client.post(WEEKLY_PLAN_URL, _plan(), format='json')
        res = staff_client.post(PUBLISH_WEEK_URL, {'start_date': '2026-08-10'}, format='json')

        assert res.status_code == status.HTTP_200_OK
        assert Devotional.objects.filter(status=DevotionalStatus.PUBLISHED).count() == 7
        # Un aviso por día, cada uno para las 7:00 de esa mañana.
        assert Notification.objects.count() == 7

    def test_sin_borradores_lo_dice_en_lugar_de_callar(self, staff_client):
        res = staff_client.post(PUBLISH_WEEK_URL, {'start_date': '2026-10-05'}, format='json')

        assert res.status_code == status.HTTP_400_BAD_REQUEST
        assert 'borrador' in res.data['error']

    def test_sin_fecha_avisa(self, staff_client):
        res = staff_client.post(PUBLISH_WEEK_URL, {}, format='json')
        assert res.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestFechasImposibles:
    """
    Una fecha que no existe se rechaza; no tumba el servidor.

    Un 31 de febrero está bien escrito pero no es un día: el lector de fechas
    de Django lanza en ese caso, y la petición se caía con un 500 en lugar de
    contestar que la fecha no vale.
    """

    @pytest.mark.parametrize('fecha', ['2026-02-31', '2026-13-01', 'cualquier-cosa'])
    def test_al_leer_la_semana(self, staff_client, fecha):
        res = staff_client.get(WEEKLY_PLAN_URL, {'start_date': fecha})

        assert res.status_code == status.HTTP_400_BAD_REQUEST, res.status_code

    @pytest.mark.parametrize('fecha', ['2026-02-31', '2026-13-01', 'cualquier-cosa'])
    def test_al_publicar_la_semana(self, staff_client, fecha):
        res = staff_client.post(PUBLISH_WEEK_URL, {'start_date': fecha}, format='json')

        assert res.status_code == status.HTTP_400_BAD_REQUEST, res.status_code
