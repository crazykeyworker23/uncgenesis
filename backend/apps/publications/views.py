from django.utils import timezone
from rest_framework import viewsets, status, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from drf_spectacular.utils import extend_schema

from apps.publications.models import (
    PublicationCategory,
    PublicationTag,
    Publication,
    PublicationStatus,
)
from apps.publications.serializers import (
    PublicationCategorySerializer,
    PublicationTagSerializer,
    PublicationSerializer,
    PublicationDetailSerializer,
)
from apps.roles.permissions import HasAppPermission
from apps.roles.utils import has_any_permission
from apps.audit.services import log_action


class PublicationCategoryViewSet(viewsets.ModelViewSet):
    queryset = PublicationCategory.objects.all()
    serializer_class = PublicationCategorySerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [HasAppPermission()]

    required_permission = 'SETTINGS_EDIT'


class PublicationTagViewSet(viewsets.ModelViewSet):
    queryset = PublicationTag.objects.all()
    serializer_class = PublicationTagSerializer
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [HasAppPermission()]

    required_permission = 'SETTINGS_EDIT'


class PublicationViewSet(viewsets.ModelViewSet):
    queryset = Publication.objects.all()

    MANAGE_PERMISSIONS = [
        'PUBLICATIONS_CREATE', 'PUBLICATIONS_EDIT',
        'PUBLICATIONS_DELETE', 'PUBLICATIONS_PUBLISH',
    ]

    def get_queryset(self):
        queryset = Publication.objects.all()
        # Borradores, programadas y archivadas quedan fuera del acceso público:
        # antes cualquier visitante podía listarlas o abrirlas por slug.
        if self.action in ['list', 'retrieve'] and not has_any_permission(
            self.request.user, self.MANAGE_PERMISSIONS
        ):
            queryset = queryset.filter(status=PublicationStatus.PUBLISHED)
        return queryset
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'category', 'content_type', 'is_featured', 'show_in_app']
    search_fields = ['title', 'summary', 'content']
    ordering_fields = ['published_at', 'created_at', 'views_count']


    def get_serializer_class(self):
        if self.action in ['retrieve', 'list'] and not self.request.query_params.get('simple'):
            return PublicationDetailSerializer
        return PublicationSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            # Permitir que cualquiera lea publicaciones (público)
            # Pero en la vista detalle incrementamos visitas de forma segura
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
            raise Http404("No se encontró la publicación.")

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Incrementar visitas de forma atómica
        instance.views_count += 1
        instance.save(update_fields=['views_count'])
        return super().retrieve(request, *args, **kwargs)

    # Determinar dinámicamente el permiso requerido según la acción
    @property
    def required_permission(self):
        if self.action in ['create', 'duplicate']:
            return 'PUBLICATIONS_CREATE'
        elif self.action in ['update', 'partial_update']:
            return 'PUBLICATIONS_EDIT'
        elif self.action in ['destroy']:
            return 'PUBLICATIONS_DELETE'
        elif self.action in ['publish', 'archive', 'schedule']:
            return 'PUBLICATIONS_PUBLISH'
        return None

    def perform_create(self, serializer):
        publication = serializer.save()
        log_action(
            user=self.request.user,
            action="CREATE",
            module="PUBLICATIONS",
            object_id=publication.id,
            description=f"Creó la publicación: {publication.title}",
            request=self.request
        )

    def perform_update(self, serializer):
        publication = serializer.save()
        log_action(
            user=self.request.user,
            action="EDIT",
            module="PUBLICATIONS",
            object_id=publication.id,
            description=f"Editó la publicación: {publication.title}",
            request=self.request
        )

    def perform_destroy(self, instance):
        log_action(
            user=self.request.user,
            action="DELETE",
            module="PUBLICATIONS",
            object_id=instance.id,
            description=f"Eliminó la publicación: {instance.title}",
            request=self.request
        )
        instance.delete()

    @extend_schema(request=None, responses={200: PublicationSerializer})
    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        """
        Publica una publicación inmediatamente en la aplicación.
        """
        publication = self.get_object()
        publication.status = PublicationStatus.PUBLISHED
        publication.published_at = timezone.now()
        publication.save()
        
        log_action(
            user=request.user,
            action="PUBLISH",
            module="PUBLICATIONS",
            object_id=publication.id,
            description=f"Publicó la publicación: {publication.title}",
            request=request
        )
        
        return Response(PublicationSerializer(publication).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={200: PublicationSerializer})
    @action(detail=True, methods=['post'])
    def archive(self, request, pk=None):
        """
        Archiva una publicación para retirarla de la vista pública.
        """
        publication = self.get_object()
        publication.status = PublicationStatus.ARCHIVED
        publication.save()
        
        log_action(
            user=request.user,
            action="ARCHIVE",
            module="PUBLICATIONS",
            object_id=publication.id,
            description=f"Archivó la publicación: {publication.title}",
            request=request
        )
        
        return Response(PublicationSerializer(publication).data, status=status.HTTP_200_OK)

    @extend_schema(request=None, responses={201: PublicationSerializer})
    @action(detail=True, methods=['post'])
    def duplicate(self, request, pk=None):
        """
        Duplica una publicación existente creando un clon en estado Borrador (DRAFT).
        """
        instance = self.get_object()
        
        cloned = Publication.objects.create(
            title=f"Copia de {instance.title}",
            summary=instance.summary,
            content=instance.content,
            cover_image=instance.cover_image,
            category=instance.category,
            content_type=instance.content_type,
            author=request.user,
            status=PublicationStatus.DRAFT,
            is_featured=instance.is_featured,
            show_in_app=instance.show_in_app,
            send_notification=False,
            seo_title=instance.seo_title,
            seo_description=instance.seo_description,
        )
        
        cloned.tags.set(instance.tags.all())
        
        # Copiar imágenes de la galería si existen
        for img in instance.gallery_images.all():
            from apps.publications.models import PublicationGallery
            PublicationGallery.objects.create(
                publication=cloned,
                image=img.image,
                order=img.order,
                caption=img.caption
            )

        log_action(
            user=request.user,
            action="DUPLICATE",
            module="PUBLICATIONS",
            object_id=cloned.id,
            description=f"Duplicó la publicación {instance.id} a la nueva publicación {cloned.id}",
            request=request
        )
        
        return Response(PublicationSerializer(cloned).data, status=status.HTTP_201_CREATED)

    @extend_schema(request=None, responses={200: PublicationSerializer})
    @action(detail=True, methods=['post'])
    def schedule(self, request, pk=None):
        """
        Programa la fecha de publicación del artículo en estado SCHEDULED.
        """
        publication = self.get_object()
        scheduled_at = request.data.get('scheduled_at')
        if not scheduled_at:
            return Response({"detail": "La fecha programada es obligatoria."}, status=status.HTTP_400_BAD_REQUEST)
            
        publication.status = PublicationStatus.SCHEDULED
        publication.scheduled_at = scheduled_at
        publication.save()
        
        log_action(
            user=request.user,
            action="SCHEDULE",
            module="PUBLICATIONS",
            object_id=publication.id,
            description=f"Programó la publicación: {publication.title} para {scheduled_at}",
            request=request
        )
        
        return Response(PublicationSerializer(publication).data, status=status.HTTP_200_OK)
