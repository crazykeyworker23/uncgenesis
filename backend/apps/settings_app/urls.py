from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.settings_app.views import (
    PublicSettingsView,
    AppSettingsUpdateView,
    ChurchSettingsUpdateView,
    ServiceScheduleViewSet,
    SocialNetworkViewSet,
)

router = DefaultRouter()
router.register('schedules', ServiceScheduleViewSet, basename='settings_schedules')
router.register('social-networks', SocialNetworkViewSet, basename='settings_socials')

urlpatterns = [
    path('public/', PublicSettingsView.as_view(), name='settings_public'),
    path('app/', AppSettingsUpdateView.as_view(), name='settings_app_update'),
    path('church/', ChurchSettingsUpdateView.as_view(), name='settings_church_update'),
    path('', include(router.urls)),
]
