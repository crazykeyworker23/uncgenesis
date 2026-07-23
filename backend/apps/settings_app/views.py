from rest_framework import status, generics, permissions, viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema

from apps.settings_app.models import AppSettings, ChurchSettings, ServiceSchedule, SocialNetwork
from apps.settings_app.serializers import (
    AppSettingsSerializer,
    ChurchSettingsSerializer,
    PublicSettingsSerializer,
    ServiceScheduleSerializer,
    SocialNetworkSerializer,
)
from apps.roles.permissions import HasAppPermission


class PublicSettingsView(APIView):
    """
    Endpoint público para que la app móvil y visitantes obtengan la información de la iglesia,
    horarios, redes sociales e identidad visual (colores, logos).
    """
    permission_classes = [permissions.AllowAny]

    @extend_schema(responses={200: PublicSettingsSerializer})
    def get(self, request):
        app_settings = AppSettings.get_solo()
        church_settings = ChurchSettings.get_solo()
        schedules = ServiceSchedule.objects.all()
        social_networks = SocialNetwork.objects.all()

        data = {
            'app': app_settings,
            'church': church_settings,
            'schedules': schedules,
            'social_networks': social_networks,
        }

        serializer = PublicSettingsSerializer(data)
        return Response(serializer.data, status=status.HTTP_200_OK)


class AppSettingsUpdateView(generics.RetrieveUpdateAPIView):
    """
    Ver y actualizar la configuración de la aplicación móvil (colores, logos, etc).
    """
    permission_classes = [HasAppPermission]
    required_permission = 'SETTINGS_EDIT'
    serializer_class = AppSettingsSerializer

    def get_object(self):
        return AppSettings.get_solo()


class ChurchSettingsUpdateView(generics.RetrieveUpdateAPIView):
    """
    Ver y actualizar la configuración e información de contacto de la iglesia.
    """
    permission_classes = [HasAppPermission]
    required_permission = 'SETTINGS_EDIT'
    serializer_class = ChurchSettingsSerializer

    def get_object(self):
        return ChurchSettings.get_solo()


class ServiceScheduleViewSet(viewsets.ModelViewSet):
    """
    CRUD para los horarios de servicios religiosos.
    """
    queryset = ServiceSchedule.objects.all()
    serializer_class = ServiceScheduleSerializer
    permission_classes = [permissions.IsAuthenticated, HasAppPermission]
    required_permission = 'SETTINGS_EDIT'
    pagination_class = None


class SocialNetworkViewSet(viewsets.ModelViewSet):
    """
    CRUD para los enlaces de redes sociales de la iglesia.
    """
    queryset = SocialNetwork.objects.all()
    serializer_class = SocialNetworkSerializer
    permission_classes = [permissions.IsAuthenticated, HasAppPermission]
    required_permission = 'SETTINGS_EDIT'
    pagination_class = None
