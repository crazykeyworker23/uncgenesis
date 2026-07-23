from rest_framework import viewsets, status, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema

from apps.services.models import ChurchService, ServiceStatus, ServiceVerse
from apps.services.serializers import ChurchServiceSerializer
from apps.roles.permissions import HasAppPermission
from apps.audit.services import log_action


class ChurchServiceViewSet(viewsets.ModelViewSet):
    queryset = ChurchService.objects.all()
    serializer_class = ChurchServiceSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'is_live']
    search_fields = ['title', 'sermon_notes']
    ordering_fields = ['date', 'created_at', 'views_count']

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
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
            raise Http404("No existe un servicio con ese ID o Slug.")

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.views_count += 1
        instance.save(update_fields=['views_count'])
        return super().retrieve(request, *args, **kwargs)

    @property
    def required_permission(self):
        if self.action in ['create', 'duplicate']:
            return 'SERVICES_CREATE'
        elif self.action in ['update', 'partial_update']:
            return 'SERVICES_EDIT'
        elif self.action in ['destroy']:
            return 'SERVICES_DELETE'
        elif self.action in ['publish', 'archive']:
            return 'SERVICES_PUBLISH'
        return None

    def perform_create(self, serializer):
        service = serializer.save()
        log_action(
            user=self.request.user,
            action="CREATE",
            module="SERVICES",
            object_id=service.id,
            description=f"Registró el servicio: {service.title} ({service.date})",
            request=self.request
        )

    def perform_update(self, serializer):
        service = serializer.save()
        log_action(
            user=self.request.user,
            action="EDIT",
            module="SERVICES",
            object_id=service.id,
            description=f"Editó el servicio: {service.title}",
            request=self.request
        )

    def perform_destroy(self, instance):
        log_action(
            user=self.request.user,
            action="DELETE",
            module="SERVICES",
            object_id=instance.id,
            description=f"Eliminó el servicio: {instance.title}",
            request=self.request
        )
        instance.delete()

    @extend_schema(request=None, responses={200: ChurchServiceSerializer})
    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """
        Publica un servicio religioso inmediatamente.
        """
        service = self.get_object()
        service.status = ServiceStatus.PUBLISHED
        service.save()
        
        log_action(
            user=request.user,
            action="PUBLISH",
            module="SERVICES",
            object_id=service.id,
            description=f"Publicó el servicio: {service.title}",
            request=request
        )
        
        return Response(ChurchServiceSerializer(service).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={200: ChurchServiceSerializer})
    @action(detail=True, methods=['post'])
    def archive(self, request, pk=None):
        """
        Archiva un servicio religioso.
        """
        service = self.get_object()
        service.status = ServiceStatus.ARCHIVED
        service.save()
        
        log_action(
            user=request.user,
            action="ARCHIVE",
            module="SERVICES",
            object_id=service.id,
            description=f"Archivó el servicio: {service.title}",
            request=request
        )
        
        return Response(ChurchServiceSerializer(service).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={201: ChurchServiceSerializer})
    @action(detail=True, methods=['post'])
    def duplicate(self, request, pk=None):
        """
        Duplica un servicio religioso en borrador (copiando notas y versículos asociados).
        """
        instance = self.get_object()
        
        cloned = ChurchService.objects.create(
            title=f"Copia de {instance.title}",
            date=instance.date,
            video_url=instance.video_url,
            audio_url=instance.audio_url,
            sermon_notes=instance.sermon_notes,
            is_live=instance.is_live,
            status=ServiceStatus.DRAFT,
        )
        
        # Copiar versículos relacionados
        for verse in instance.verses.all():
            ServiceVerse.objects.create(
                service=cloned,
                book=verse.book,
                chapter=verse.chapter,
                verses=verse.verses,
                text=verse.text
            )

        log_action(
            user=request.user,
            action="DUPLICATE",
            module="SERVICES",
            object_id=cloned.id,
            description=f"Duplicó el servicio {instance.id} al nuevo servicio {cloned.id}",
            request=request
        )
        
        return Response(ChurchServiceSerializer(cloned).data, status=status.HTTP_201_CREATED)
