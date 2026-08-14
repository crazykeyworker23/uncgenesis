from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend

from apps.roles.permissions import HasAppPermission
from .models import Multimedia
from .serializers import MultimediaSerializer

MEDIA_PERM_MAP = {
    'list': 'MEDIA_VIEW',
    'retrieve': 'MEDIA_VIEW',
    'create': 'MEDIA_CREATE',
    'destroy': 'MEDIA_DELETE',
}


class MultimediaViewSet(viewsets.ModelViewSet):
    queryset = Multimedia.objects.select_related('uploaded_by').all()
    serializer_class = MultimediaSerializer
    permission_classes = [IsAuthenticated, HasAppPermission]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['file_type']
    search_fields = ['title']
    ordering_fields = ['created_at', 'title', 'file_size']
    ordering = ['-created_at']

    def get_required_permission(self):
        return MEDIA_PERM_MAP.get(self.action, 'MEDIA_VIEW')

    def check_permissions(self, request):
        self.required_permission = self.get_required_permission()
        super().check_permissions(request)
