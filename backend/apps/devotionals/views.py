from datetime import timedelta

from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import viewsets, status, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema

from apps.devotionals.models import Devotional, DevotionalStatus
from apps.devotionals.serializers import DevotionalSerializer, WeeklyPlanSerializer
from apps.roles.permissions import HasAppPermission
from apps.roles.utils import has_any_permission
from apps.audit.services import log_action

#: Etiqueta de cada día, en el orden en que se pinta el plan.
WEEKDAYS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']


def schedule_devotional_notification(devotional, sender):
    """
    Crea o actualiza una notificación push programada para las 7:00 AM del día del devocional.
    """
    try:
        from apps.notifications.models import Notification, NotificationStatus, TargetAudience
        from apps.notifications.tasks import send_push_notification_task
        import datetime

        if devotional.status != DevotionalStatus.PUBLISHED:
            return

        target_date = devotional.date
        scheduled_dt = timezone.make_aware(
            datetime.datetime.combine(target_date, datetime.time(7, 0, 0)),
            timezone.get_current_timezone()
        )

        is_future = scheduled_dt > timezone.now()
        status_val = NotificationStatus.PENDING if is_future else NotificationStatus.SENT
        sent_val = None if is_future else timezone.now()

        title = f"📖 Devocional del Día: {devotional.title}"
        clean_content = devotional.content.replace('\n', ' ').strip()
        snippet = (clean_content[:100] + '...') if len(clean_content) > 100 else clean_content
        body = f"{devotional.bible_passage} — {snippet}"

        notif, created = Notification.objects.update_or_create(
            title__startswith=f"📖 Devocional del Día: {devotional.title[:25]}",
            defaults={
                'title': title,
                'body': body,
                'sender': sender,
                'target_audience': TargetAudience.ALL,
                'target_user': None,
                # Al tocar el aviso se abre este devocional, no el listado.
                'deep_link': f'/devotionals/{devotional.slug}',
                'scheduled_for': scheduled_dt,
                'status': status_val,
                'sent_at': sent_val,
            }
        )

        if is_future:
            try:
                send_push_notification_task.apply_async((notif.id,), eta=scheduled_dt)
            except Exception:
                pass
        else:
            from apps.notifications.push import dispatch
            dispatch(notif)
    except Exception:
        pass


class DevotionalViewSet(viewsets.ModelViewSet):
    queryset = Devotional.objects.all()

    MANAGE_PERMISSIONS = [
        'DEVOTIONALS_CREATE', 'DEVOTIONALS_EDIT',
        'DEVOTIONALS_DELETE', 'DEVOTIONALS_PUBLISH',
    ]

    def get_queryset(self):
        queryset = Devotional.objects.all()
        # Sólo los devocionales publicados son visibles sin permisos de gestión.
        if self.action in ['list', 'retrieve', 'today'] and not has_any_permission(
            self.request.user, self.MANAGE_PERMISSIONS
        ):
            queryset = queryset.filter(status=DevotionalStatus.PUBLISHED)
        return queryset
    serializer_class = DevotionalSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'date']
    search_fields = ['title', 'content', 'bible_passage']
    ordering_fields = ['date', 'created_at', 'views_count']

    def get_permissions(self):
        if self.action in ['list', 'retrieve', 'today']:
            return [permissions.AllowAny()]
        return [HasAppPermission()]

    def get_object(self):
        queryset = self.filter_queryset(self.get_queryset())
        lookup_url_kwarg = self.lookup_url_kwarg or self.lookup_field or 'pk'
        lookup_value = self.kwargs[lookup_url_kwarg]
        
        if lookup_value.isdigit():
            try:
                obj = queryset.get(pk=lookup_value)
                self.check_object_permissions(self.request, obj)
                return obj
            except (queryset.model.DoesNotExist, ValueError):
                pass
                
        try:
            obj = queryset.get(slug=lookup_value)
            self.check_object_permissions(self.request, obj)
            return obj
        except queryset.model.DoesNotExist:
            from django.http import Http404
            raise Http404("No se encontró el devocional.")

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.views_count += 1
        instance.save(update_fields=['views_count'])
        return super().retrieve(request, *args, **kwargs)

    @property
    def required_permission(self):
        if self.action in ['create', 'duplicate']:
            return 'DEVOTIONALS_CREATE'
        elif self.action in ['update', 'partial_update']:
            return 'DEVOTIONALS_EDIT'
        elif self.action in ['destroy']:
            return 'DEVOTIONALS_DELETE'
        elif self.action in ['publish', 'archive', 'publish_week']:
            return 'DEVOTIONALS_PUBLISH'
        elif self.action == 'weekly_plan':
            # Leer el plan de una semana no exige nada especial: lo hace quien
            # ya entra a la sección. Cargarlo sí, que crea siete devocionales.
            return None if self.request.method == 'GET' else 'DEVOTIONALS_CREATE'
        return None

    def perform_create(self, serializer):
        devotional = serializer.save()
        schedule_devotional_notification(devotional, self.request.user)
        log_action(
            user=self.request.user,
            action="CREATE",
            module="DEVOTIONALS",
            object_id=devotional.id,
            description=f"Creó el devocional: {devotional.title} para el {devotional.date}",
            request=self.request
        )

    def perform_update(self, serializer):
        devotional = serializer.save()
        schedule_devotional_notification(devotional, self.request.user)
        log_action(
            user=self.request.user,
            action="EDIT",
            module="DEVOTIONALS",
            object_id=devotional.id,
            description=f"Editó el devocional: {devotional.title}",
            request=self.request
        )

    def perform_destroy(self, instance):
        log_action(
            user=self.request.user,
            action="DELETE",
            module="DEVOTIONALS",
            object_id=instance.id,
            description=f"Eliminó el devocional: {instance.title}",
            request=self.request
        )
        instance.delete()

    @extend_schema(request=None, responses={200: DevotionalSerializer})
    @action(detail=False, methods=['get'])
    def today(self, request):
        """
        Obtiene el devocional asignado para el día de hoy (o fallback al más reciente).
        """
        today_date = timezone.localdate()
        
        # Intentar obtener el devocional de hoy publicado
        devotional = Devotional.objects.filter(
            date=today_date,
            status=DevotionalStatus.PUBLISHED
        ).first()

        # Fallback al devocional publicado más reciente si no hay uno exacto para hoy
        if not devotional:
            devotional = Devotional.objects.filter(
                status=DevotionalStatus.PUBLISHED
            ).order_by('-date').first()

        if not devotional:
            return Response(
                {"detail": "No se encontraron devocionales publicados en este momento."},
                status=status.HTTP_404_NOT_FOUND
            )

        # Incrementar visitas de forma atómica
        devotional.views_count += 1
        devotional.save(update_fields=['views_count'])

        serializer = self.get_serializer(devotional)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={200: DevotionalSerializer})
    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """
        Publica un devocional inmediatamente.
        """
        devotional = self.get_object()
        devotional.status = DevotionalStatus.PUBLISHED
        devotional.save()
        
        schedule_devotional_notification(devotional, request.user)
        
        log_action(
            user=request.user,
            action="PUBLISH",
            module="DEVOTIONALS",
            object_id=devotional.id,
            description=f"Publicó el devocional: {devotional.title}",
            request=request
        )
        
        return Response(DevotionalSerializer(devotional).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={200: DevotionalSerializer})
    @action(detail=True, methods=['post'])
    def archive(self, request, pk=None):
        """
        Archiva un devocional.
        """
        devotional = self.get_object()
        devotional.status = DevotionalStatus.ARCHIVED
        devotional.save()
        
        log_action(
            user=request.user,
            action="ARCHIVE",
            module="DEVOTIONALS",
            object_id=devotional.id,
            description=f"Archivó el devocional: {devotional.title}",
            request=request
        )
        
        return Response(DevotionalSerializer(devotional).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={201: DevotionalSerializer})
    @action(detail=True, methods=['post'])
    def duplicate(self, request, pk=None):
        """
        Duplica un devocional existente en borrador (con fecha de hoy o sumando 1 día si ya existe).
        """
        instance = self.get_object()
        
        # Calcular fecha disponible para el clon
        target_date = timezone.localdate()
        while Devotional.objects.filter(date=target_date).exists():
            target_date += timezone.timedelta(days=1)
            
        cloned = Devotional.objects.create(
            title=f"Copia de {instance.title}",
            date=target_date,
            bible_passage=instance.bible_passage,
            bible_text=instance.bible_text,
            content=instance.content,
            audio_url=instance.audio_url,
            author=request.user,
            status=DevotionalStatus.DRAFT,
        )

        log_action(
            user=request.user,
            action="DUPLICATE",
            module="DEVOTIONALS",
            object_id=cloned.id,
            description=f"Duplicó el devocional {instance.id} al nuevo devocional {cloned.id} para la fecha {cloned.date}",
            request=request
        )
        
        return Response(DevotionalSerializer(cloned).data, status=status.HTTP_201_CREATED)

    # ── Plan de lecturas semanal ────────────────────────────────────────────
    #
    # Cargar la semana día por día eran siete formularios largos. Aquí se
    # entra el lunes y los siete pasajes de una vez.

    @staticmethod
    def _monday(value):
        """
        Lee la fecha que abre la semana. Devuelve None si no se entiende.

        `parse_date` devuelve None ante un texto cualquiera, pero lanza
        ValueError si la fecha está bien escrita y no existe —un 31 de
        febrero—, y eso rompía la petición entera.
        """
        try:
            return parse_date(value or '')
        except ValueError:
            return None

    @extend_schema(request=WeeklyPlanSerializer, responses={200: DevotionalSerializer(many=True)})
    @action(detail=False, methods=['get', 'post'], url_path='weekly-plan')
    def weekly_plan(self, request):
        """
        Consulta o carga el plan de una semana.

        En GET devuelve los siete días a partir de `start_date`, estén
        cargados o no, para que el panel pinte la semana completa y se pueda
        corregir lo ya escrito.

        En POST los crea o actualiza como borrador. No toca lo que ya esté
        publicado: sobrescribir en silencio un devocional que la gente ya
        recibió seria peor que avisar.
        """
        if request.method == 'GET':
            start = self._monday(request.query_params.get('start_date'))
            if start is None:
                return Response(
                    {'error': 'Indica el lunes de la semana en start_date (2026-08-10).'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            return Response(self._describe_week(start))

        serializer = WeeklyPlanSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        start = serializer.validated_data['start_date']
        days = serializer.validated_data['days']
        fechas = [start + timedelta(days=i) for i in range(7)]

        publicados = list(
            Devotional.objects.filter(date__in=fechas)
            .exclude(status=DevotionalStatus.DRAFT)
            .values_list('date', flat=True)
        )
        if publicados:
            listado = ', '.join(fecha.isoformat() for fecha in sorted(publicados))
            return Response(
                {'error': f'Ya hay devocionales publicados en estas fechas: {listado}. '
                          f'Edítalos uno a uno o elige otra semana.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        for fecha, dia in zip(fechas, days):
            Devotional.objects.update_or_create(
                date=fecha,
                defaults={
                    # El título es el pasaje: en un plan de lecturas es lo que
                    # identifica el día, y evita pedir un dato más por fila.
                    'title': dia['bible_passage'],
                    'bible_passage': dia['bible_passage'],
                    'content': dia['content'],
                    'author': request.user,
                    'status': DevotionalStatus.DRAFT,
                },
            )

        log_action(
            user=request.user,
            action="CREATE",
            module="DEVOTIONALS",
            object_id=None,
            description=f"Cargó el plan semanal del {start} al {fechas[-1]}",
            request=request,
        )
        return Response(self._describe_week(start), status=status.HTTP_201_CREATED)

    @extend_schema(request=None, responses={200: DevotionalSerializer(many=True)})
    @action(detail=False, methods=['post'], url_path='weekly-plan/publish')
    def publish_week(self, request):
        """
        Publica la semana entera y programa sus avisos.

        Cada día queda con su notificación a las 7:00 de esa mañana, que es lo
        que ya hacía un devocional suelto al publicarse.
        """
        start = self._monday(request.data.get('start_date'))
        if start is None:
            return Response(
                {'error': 'Indica el lunes de la semana en start_date (2026-08-10).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        fechas = [start + timedelta(days=i) for i in range(7)]
        pendientes = Devotional.objects.filter(date__in=fechas, status=DevotionalStatus.DRAFT)
        if not pendientes.exists():
            return Response(
                {'error': 'No hay ningún borrador cargado para esa semana.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        publicados = 0
        for devotional in pendientes:
            devotional.status = DevotionalStatus.PUBLISHED
            devotional.save()
            schedule_devotional_notification(devotional, request.user)
            publicados += 1

        log_action(
            user=request.user,
            action="PUBLISH",
            module="DEVOTIONALS",
            object_id=None,
            description=f"Publicó el plan semanal del {start} al {fechas[-1]}",
            request=request,
        )

        resumen = self._describe_week(start)
        resumen['detail'] = (
            f'Se publicaron {publicados} día(s). Cada uno avisará a las 7:00 de su mañana.'
        )
        return Response(resumen, status=status.HTTP_200_OK)

    def _describe_week(self, start):
        """Los siete días de la semana, cargados o no, en orden."""
        fechas = [start + timedelta(days=i) for i in range(7)]
        cargados = {d.date: d for d in Devotional.objects.filter(date__in=fechas)}

        return {
            'start_date': start,
            'end_date': fechas[-1],
            'days': [
                {
                    'date': fecha,
                    'weekday': WEEKDAYS[index],
                    'id': cargados[fecha].id if fecha in cargados else None,
                    'bible_passage': cargados[fecha].bible_passage if fecha in cargados else '',
                    'content': cargados[fecha].content if fecha in cargados else '',
                    'status': cargados[fecha].status if fecha in cargados else None,
                }
                for index, fecha in enumerate(fechas)
            ],
        }
