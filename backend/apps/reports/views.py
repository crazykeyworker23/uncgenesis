import csv
import datetime
from django.utils import timezone
from django.http import HttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import get_user_model

from apps.roles.permissions import HasAppPermission
from apps.cells.models import CellGroup
from apps.events.models import Event, EventRegistration
from apps.church_requests.models import PrayerRequest, VisitorRequest
from apps.notifications.models import FCMDevice, Notification
from apps.publications.models import Publication, PublicationStatus
from apps.services.models import ChurchService
from apps.devotionals.models import Devotional

User = get_user_model()



class ReportsSummaryAPIView(APIView):
    permission_classes = [IsAuthenticated, HasAppPermission]
    required_permission = 'REPORTS_VIEW'

    def get(self, request, *args, **kwargs):
        # 1. Cells
        total_cells = CellGroup.objects.count()
        active_cells = CellGroup.objects.filter(status='ACTIVE').count()

        # 2. Events
        total_events = Event.objects.count()
        total_registrations = EventRegistration.objects.count()

        # 3. Requests
        prayer_pending = PrayerRequest.objects.filter(status='PENDING').count()
        prayer_in_progress = PrayerRequest.objects.filter(status='IN_PROGRESS').count()
        prayer_resolved = PrayerRequest.objects.filter(status='RESOLVED').count()

        visitor_pending = VisitorRequest.objects.filter(status='PENDING').count()
        visitor_in_progress = VisitorRequest.objects.filter(status='IN_PROGRESS').count()
        visitor_resolved = VisitorRequest.objects.filter(status='RESOLVED').count()

        # 4. Users
        users_active = User.objects.filter(status='ACTIVE').count()
        users_blocked = User.objects.filter(status='BLOCKED').count()
        users_inactive = User.objects.filter(status='INACTIVE').count()

        # 5. Notifications
        total_devices = FCMDevice.objects.count()
        total_notifications = Notification.objects.count()

        data = {
            'cells': {
                'total': total_cells,
                'active': active_cells,
                'inactive': total_cells - active_cells
            },
            'events': {
                'total': total_events,
                'registrations': total_registrations
            },
            'requests': {
                'prayer': {
                    'pending': prayer_pending,
                    'in_progress': prayer_in_progress,
                    'resolved': prayer_resolved,
                    'total': prayer_pending + prayer_in_progress + prayer_resolved
                },
                'visitor': {
                    'pending': visitor_pending,
                    'in_progress': visitor_in_progress,
                    'resolved': visitor_resolved,
                    'total': visitor_pending + visitor_in_progress + visitor_resolved
                }
            },
            'users': {
                'active': users_active,
                'blocked': users_blocked,
                'inactive': users_inactive,
                'total': users_active + users_blocked + users_inactive
            },
            'notifications': {
                'devices': total_devices,
                'sent': total_notifications
            }
        }
        return Response(data)


class ReportsExportAPIView(APIView):
    permission_classes = [IsAuthenticated, HasAppPermission]
    required_permission = 'REPORTS_EXPORT'

    def get(self, request, *args, **kwargs):
        export_type = request.query_params.get('type', 'cells')

        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="report_{export_type}.csv"'
        
        writer = csv.writer(response)

        if export_type == 'cells':
            writer.writerow(['ID', 'Nombre', 'Dia de Reunion', 'Hora', 'Estado', 'Lider', 'Direccion'])
            cells = CellGroup.objects.select_related('leader').all()
            for cell in cells:
                writer.writerow([
                    cell.id,
                    cell.name,
                    cell.meeting_day,
                    cell.meeting_time,
                    cell.status,
                    cell.leader.full_name if cell.leader else 'Sin lider',
                    cell.address
                ])

        elif export_type == 'requests':
            writer.writerow(['Tipo', 'ID', 'Nombre Solicitante', 'Telefono', 'Estado', 'Responsable', 'Fecha Creacion'])
            # Prayer Requests
            prayers = PrayerRequest.objects.select_related('assigned_to').all()
            for p in prayers:
                writer.writerow([
                    'Oracion',
                    p.id,
                    p.requester_name,
                    p.requester_phone,
                    p.status,
                    p.assigned_to.full_name if p.assigned_to else 'Sin asignar',
                    p.created_at.strftime('%Y-%m-%d %H:%M') if p.created_at else ''
                ])
            # Visitor Requests
            visitors = VisitorRequest.objects.select_related('assigned_to').all()
            for v in visitors:
                writer.writerow([
                    'Visita',
                    v.id,
                    v.visitor_name,
                    v.visitor_phone,
                    v.status,
                    v.assigned_to.full_name if v.assigned_to else 'Sin asignar',
                    v.created_at.strftime('%Y-%m-%d %H:%M') if v.created_at else ''
                ])

        elif export_type == 'users':
            writer.writerow(['ID', 'Email', 'Nombre Completo', 'Telefono', 'Estado', 'Superusuario', 'Staff', 'Fecha Registro'])
            users = User.objects.all()
            for u in users:
                writer.writerow([
                    u.id,
                    u.email,
                    u.full_name,
                    u.phone,
                    u.status,
                    u.is_superuser,
                    u.is_staff,
                    u.created_at.strftime('%Y-%m-%d %H:%M') if u.created_at else ''
                ])
        else:
            return Response({"error": "Tipo de exportacion invalido."}, status=400)

        return response


class DashboardStatsAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        # 1. KPIs
        active_publications = Publication.objects.filter(status=PublicationStatus.PUBLISHED).count()
        recorded_services = ChurchService.objects.count()
        total_users = User.objects.count()

        prayer_pending = PrayerRequest.objects.filter(status='PENDING').count()
        visitor_pending = VisitorRequest.objects.filter(status='PENDING').count()
        pending_requests = prayer_pending + visitor_pending

        # 2. Content Distribution
        services_count = ChurchService.objects.count()
        devotionals_count = Devotional.objects.count()
        publications_count = Publication.objects.count()
        events_count = Event.objects.count()

        content_distribution = [
            {'name': 'Prédicas', 'count': services_count},
            {'name': 'Devocionales', 'count': devotionals_count},
            {'name': 'Noticias', 'count': publications_count},
            {'name': 'Eventos', 'count': events_count},
        ]

        # 3. Activity Graph (Last 7 months)
        today = timezone.now().date()
        month_names = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
        activity_data = []

        for i in range(6, -1, -1):
            # Calculate month range
            year = today.year
            month = today.month - i
            while month <= 0:
                month += 12
                year -= 1
            
            start_date = datetime.date(year, month, 1)
            if month == 12:
                end_date = datetime.date(year + 1, 1, 1)
            else:
                end_date = datetime.date(year, month + 1, 1)

            reg_count = User.objects.filter(created_at__gte=start_date, created_at__lt=end_date).count()
            req_count = (
                PrayerRequest.objects.filter(created_at__gte=start_date, created_at__lt=end_date).count() +
                VisitorRequest.objects.filter(created_at__gte=start_date, created_at__lt=end_date).count()
            )

            activity_data.append({
                'name': month_names[month - 1],
                'visitas': req_count + (reg_count * 2),
                'registros': reg_count,
            })

        # 4. Recent Requests
        recent_prayers = list(PrayerRequest.objects.order_by('-created_at')[:4])
        recent_visitors = list(VisitorRequest.objects.order_by('-created_at')[:4])

        recent_requests = []
        for p in recent_prayers:
            recent_requests.append({
                'id': f"prayer-{p.id}",
                'type': 'Petición de Oración',
                'description': f"{p.subject} - {p.requester_name if not p.is_anonymous else 'Anónimo'}",
                'status': 'NUEVO' if p.status == 'PENDING' else p.status,
                'created_at': p.created_at.isoformat() if p.created_at else ''
            })

        for v in recent_visitors:
            recent_requests.append({
                'id': f"visitor-{v.id}",
                'type': 'Registro de Visitante',
                'description': f"{v.full_name} ({v.phone or 'Sin tel.'})",
                'status': 'NUEVO' if v.status == 'PENDING' else v.status,
                'created_at': v.created_at.isoformat() if v.created_at else ''
            })


        recent_requests.sort(key=lambda x: x['created_at'], reverse=True)
        recent_requests = recent_requests[:4]

        return Response({
            'kpis': {
                'active_publications': active_publications,
                'recorded_services': recorded_services,
                'total_users': total_users,
                'pending_requests': pending_requests,
                'urgent_requests': prayer_pending
            },
            'content_distribution': content_distribution,
            'activity_data': activity_data,
            'recent_requests': recent_requests
        })

