from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FCMDeviceViewSet, NotificationViewSet

router = DefaultRouter()
router.register('devices', FCMDeviceViewSet, basename='notification-devices')
router.register('', NotificationViewSet, basename='notifications')

urlpatterns = [
    path('', include(router.urls)),
]
