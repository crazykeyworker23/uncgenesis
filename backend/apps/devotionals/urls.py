from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.devotionals.views import DevotionalViewSet

router = DefaultRouter()
router.register('devotionals', DevotionalViewSet, basename='devotional')

urlpatterns = [
    path('', include(router.urls)),
]
