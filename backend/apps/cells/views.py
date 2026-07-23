from rest_framework import viewsets, filters, permissions
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from apps.roles.permissions import HasAppPermission
from .models import CellGroup
from .serializers import CellGroupSerializer

PERM_MAP = {
    'list':    'CELLS_VIEW',
    'retrieve':'CELLS_VIEW',
    'create':  'CELLS_CREATE',
    'update':  'CELLS_EDIT',
    'partial_update': 'CELLS_EDIT',
    'destroy': 'CELLS_DELETE',
}

class CellGroupViewSet(viewsets.ModelViewSet):
    queryset = CellGroup.objects.select_related('leader').all()
    serializer_class = CellGroupSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'meeting_day', 'leader']
    search_fields = ['name', 'address', 'leader__first_name', 'leader__last_name']
    ordering_fields = ['name', 'created_at', 'meeting_day']
    ordering = ['name']

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [IsAuthenticated(), HasAppPermission()]

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
            raise Http404("No se encontró la célula.")

    def get_required_permission(self):
        return PERM_MAP.get(self.action, 'CELLS_VIEW')

    def check_permissions(self, request):
        if self.action in ['list', 'retrieve']:
            return
        self.required_permission = self.get_required_permission()
        super().check_permissions(request)
