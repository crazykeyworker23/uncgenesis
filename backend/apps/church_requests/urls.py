from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import PrayerRequestViewSet, VisitorRequestViewSet

router = DefaultRouter()
router.register(r'prayer-requests', PrayerRequestViewSet, basename='prayer-requests')
router.register(r'visitor-requests', VisitorRequestViewSet, basename='visitor-requests')

urlpatterns = [
    path('', include(router.urls)),
]
