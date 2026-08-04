from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import viewsets, status, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema

from apps.events.models import Event, EventRegistration, EventRegistrationStatus, EventStatus
from apps.events.serializers import EventSerializer, EventRegistrationSerializer
from apps.roles.permissions import HasAppPermission
from apps.roles.utils import has_any_permission
from apps.audit.services import log_action


class EventViewSet(viewsets.ModelViewSet):
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'requires_registration']
    search_fields = ['title', 'description', 'location']
    ordering_fields = ['start_date', 'created_at']

    MANAGE_PERMISSIONS = ['EVENTS_CREATE', 'EVENTS_EDIT', 'EVENTS_DELETE', 'EVENTS_PUBLISH']

    def get_queryset(self):
        # Annotate registered_count to optimize queries
        queryset = Event.objects.annotate(
            registered_count=Count(
                'registrations',
                filter=Q(registrations__status=EventRegistrationStatus.CONFIRMED)
            )
        )

        # Los borradores y archivados sólo son visibles para quien gestiona
        # eventos: antes cualquier visitante podía listarlos o abrirlos por slug.
        if self.action in ['list', 'retrieve'] and not has_any_permission(
            self.request.user, self.MANAGE_PERMISSIONS
        ):
            queryset = queryset.filter(status=EventStatus.PUBLISHED)

        return queryset

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
            raise Http404("No se encontró el evento.")

    def get_serializer_class(self):
        return EventSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        elif self.action == 'register':
            return [permissions.IsAuthenticated()]
        return [HasAppPermission()]

    @property
    def required_permission(self):
        if self.action in ['create', 'duplicate']:
            return 'EVENTS_CREATE'
        elif self.action in ['update', 'partial_update']:
            return 'EVENTS_EDIT'
        elif self.action in ['destroy']:
            return 'EVENTS_DELETE'
        elif self.action in ['publish', 'archive', 'cancel', 'attendees']:
            return 'EVENTS_PUBLISH'
        return None

    def perform_create(self, serializer):
        event = serializer.save()
        log_action(
            user=self.request.user,
            action="CREATE",
            module="EVENTS",
            object_id=event.id,
            description=f"Creó el evento: {event.title} ({event.start_date})",
            request=self.request
        )

    def perform_update(self, serializer):
        event = serializer.save()
        log_action(
            user=self.request.user,
            action="EDIT",
            module="EVENTS",
            object_id=event.id,
            description=f"Editó el evento: {event.title}",
            request=self.request
        )

    def perform_destroy(self, instance):
        log_action(
            user=self.request.user,
            action="DELETE",
            module="EVENTS",
            object_id=instance.id,
            description=f"Eliminó el evento: {instance.title}",
            request=self.request
        )
        instance.delete()

    @extend_schema(request=None, responses={200: EventSerializer})
    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """
        Publica un evento inmediatamente.
        """
        event = self.get_object()
        event.status = EventStatus.PUBLISHED
        event.save()
        
        log_action(
            user=request.user,
            action="PUBLISH",
            module="EVENTS",
            object_id=event.id,
            description=f"Publicó el evento: {event.title}",
            request=request
        )
        
        return Response(EventSerializer(event).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={200: EventSerializer})
    @action(detail=True, methods=['post'])
    def archive(self, request, pk=None):
        """
        Archiva un evento.
        """
        event = self.get_object()
        event.status = EventStatus.ARCHIVED
        event.save()
        
        log_action(
            user=request.user,
            action="ARCHIVE",
            module="EVENTS",
            object_id=event.id,
            description=f"Archivó el evento: {event.title}",
            request=request
        )
        
        return Response(EventSerializer(event).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={200: EventSerializer})
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """
        Cancela un evento.
        """
        event = self.get_object()
        event.status = EventStatus.CANCELLED
        event.save()
        
        log_action(
            user=request.user,
            action="CANCEL",
            module="EVENTS",
            object_id=event.id,
            description=f"Canceló el evento: {event.title}",
            request=request
        )
        
        return Response(EventSerializer(event).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={201: EventSerializer})
    @action(detail=True, methods=['post'])
    def duplicate(self, request, pk=None):
        """
        Duplica un evento en borrador (DRAFT) empujando fechas un mes adelante.
        """
        instance = self.get_object()
        
        cloned = Event.objects.create(
            title=f"Copia de {instance.title}",
            description=instance.description,
            cover_image=instance.cover_image,
            start_date=instance.start_date + timezone.timedelta(days=30),
            end_date=instance.end_date + timezone.timedelta(days=30),
            location=instance.location,
            latitude=instance.latitude,
            longitude=instance.longitude,
            capacity=instance.capacity,
            requires_registration=instance.requires_registration,
            status=EventStatus.DRAFT,
        )

        log_action(
            user=request.user,
            action="DUPLICATE",
            module="EVENTS",
            object_id=cloned.id,
            description=f"Duplicó el evento {instance.id} a la nueva copia {cloned.id}",
            request=request
        )
        
        return Response(EventSerializer(cloned).data, status=status.HTTP_201_CREATED)

    @extend_schema(request=None, responses={201: EventRegistrationSerializer})
    @action(detail=True, methods=['post'])
    def register(self, request, pk=None):
        """
        Permite a un usuario autenticado inscribirse al evento (controlando aforo).
        """
        event = self.get_object()

        if not event.requires_registration:
            return Response(
                {"detail": "Este evento no requiere inscripción previa."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validar si ya está registrado
        if EventRegistration.objects.filter(event=event, user=request.user, status=EventRegistrationStatus.CONFIRMED).exists():
            return Response(
                {"detail": "Ya te encuentras inscrito en este evento."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validar aforo
        if event.capacity is not None:
            # Obtener aforo en tiempo real de forma segura
            current_count = EventRegistration.objects.filter(
                event=event,
                status=EventRegistrationStatus.CONFIRMED
            ).count()
            if current_count >= event.capacity:
                return Response(
                    {"detail": "Aforo completo. No hay cupos disponibles para este evento."},
                    status=status.HTTP_400_BAD_REQUEST
                )

        # Registrar
        registration, created = EventRegistration.objects.get_or_create(
            event=event,
            user=request.user,
            defaults={"status": EventRegistrationStatus.CONFIRMED}
        )

        # Si ya existía cancelada, reactivarla
        if not created and registration.status == EventRegistrationStatus.CANCELLED:
            registration.status = EventRegistrationStatus.CONFIRMED
            registration.save()

        log_action(
            user=request.user,
            action="REGISTER_EVENT",
            module="EVENTS",
            object_id=event.id,
            description=f"El usuario {request.user.email} se inscribió al evento {event.title}",
            request=request
        )

        return Response(EventRegistrationSerializer(registration).data, status=status.HTTP_201_CREATED)

    @extend_schema(request=None, responses={200: EventRegistrationSerializer(many=True)})
    @action(detail=True, methods=['get'])
    def attendees(self, request, pk=None):
        """
        Lista todos los inscritos confirmados al evento (Administración).
        """
        event = self.get_object()
        registrations = event.registrations.all()
        
        # Opcional: paginar si hay demasiados
        page = self.paginate_queryset(registrations)
        if page is not None:
            serializer = EventRegistrationSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = EventRegistrationSerializer(registrations, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
