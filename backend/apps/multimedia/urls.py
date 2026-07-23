from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MultimediaViewSet

router = DefaultRouter()
router.register('', MultimediaViewSet, basename='multimedia')

urlpatterns = [
    path('', include(router.urls)),
]
