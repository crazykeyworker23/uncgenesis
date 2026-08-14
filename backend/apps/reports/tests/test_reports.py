import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()

REPORTS_SUMMARY = reverse('reports-summary')
REPORTS_EXPORT = reverse('reports-export')


@pytest.fixture
def admin_client(db, create_user):
    from rest_framework.test import APIClient
    from rest_framework_simplejwt.tokens import RefreshToken
    user = create_user(email="reports_admin@genesisapp.org")
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
    user = create_user(email="reports_member@genesisapp.org")
    client = APIClient()
    refresh = RefreshToken.for_user(user)
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    return client


@pytest.mark.django_db
class TestReportsAndAnalytics:
    def test_summary_requires_auth(self, api_client):
        """Unauthenticated requests are blocked."""
        res = api_client.get(REPORTS_SUMMARY)
        assert res.status_code == status.HTTP_401_UNAUTHORIZED

    def test_summary_denied_for_regular_member(self, member_client):
        """Regular members cannot see consolidated analytics."""
        res = member_client.get(REPORTS_SUMMARY)
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_summary_allowed_for_admin(self, admin_client):
        """Admins can retrieve metrics summary and dashboard aggregations."""
        res = admin_client.get(REPORTS_SUMMARY)
        assert res.status_code == status.HTTP_200_OK
        assert 'cells' in res.data
        assert 'events' in res.data
        assert 'requests' in res.data
        assert 'users' in res.data
        assert 'notifications' in res.data

    def test_export_requires_export_permission(self, member_client):
        """Exporting CSV reports is blocked for users without permissions."""
        res = member_client.get(f"{REPORTS_EXPORT}?type=cells")
        assert res.status_code == status.HTTP_403_FORBIDDEN

    def test_export_cells_csv(self, admin_client):
        """Admins can export cells report as CSV."""
        res = admin_client.get(f"{REPORTS_EXPORT}?type=cells")
        assert res.status_code == status.HTTP_200_OK
        assert res['Content-Type'] == 'text/csv'
        assert 'attachment' in res['Content-Disposition']
        assert 'report_cells.csv' in res['Content-Disposition']
        content = res.content.decode('utf-8')
        assert 'ID,Nombre,' in content

    def test_export_requests_csv(self, admin_client):
        """Admins can export church requests (prayers/visitors) log as CSV."""
        res = admin_client.get(f"{REPORTS_EXPORT}?type=requests")
        assert res.status_code == status.HTTP_200_OK
        content = res.content.decode('utf-8')
        assert 'Tipo,ID,Nombre Solicitante' in content

    def test_export_requests_csv_con_datos(self, admin_client):
        """
        La exportación se probaba con la base vacía.

        Los bucles que arman las filas no llegaban a ejecutarse, así que un
        campo mal escrito pasaba desapercibido: la visita guarda el nombre en
        `full_name` y se leía `visitor_name`, y la descarga reventaba en
        cuanto había una sola visita registrada.
        """
        from apps.church_requests.models import PrayerRequest, VisitorRequest

        PrayerRequest.objects.create(
            requester_name='Ana Quispe',
            requester_phone='999111222',
            subject='Por mi familia',
            description='Oren por nosotros.',
        )
        VisitorRequest.objects.create(full_name='Luis Ramos', phone='999333444')

        res = admin_client.get(f"{REPORTS_EXPORT}?type=requests")

        assert res.status_code == status.HTTP_200_OK
        content = res.content.decode('utf-8')
        assert 'Ana Quispe' in content
        assert 'Luis Ramos' in content
        assert '999333444' in content

    def test_export_users_csv(self, admin_client):
        """Admins can export user directories as CSV."""
        res = admin_client.get(f"{REPORTS_EXPORT}?type=users")
        assert res.status_code == status.HTTP_200_OK
        content = res.content.decode('utf-8')
        assert 'ID,Email,Nombre Completo' in content

    def test_dashboard_stats_endpoint(self, admin_client):
        """Authenticated users can access dashboard stats."""
        url = reverse('reports-dashboard')
        res = admin_client.get(url)
        assert res.status_code == status.HTTP_200_OK
        assert 'kpis' in res.data
        assert 'content_distribution' in res.data
        assert 'activity_data' in res.data
        assert 'recent_requests' in res.data

