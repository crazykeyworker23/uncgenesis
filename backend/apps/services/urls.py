from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.services.views import ChurchServiceViewSet

router = DefaultRouter()
router.register('services', ChurchServiceViewSet, basename='service')

urlpatterns = [
    path('', include(router.urls)),
]
