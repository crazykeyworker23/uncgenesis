from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.publications.views import (
    PublicationViewSet,
    PublicationCategoryViewSet,
    PublicationTagViewSet,
)

router = DefaultRouter()
router.register('publications', PublicationViewSet, basename='publication')
router.register('categories', PublicationCategoryViewSet, basename='category')
router.register('tags', PublicationTagViewSet, basename='tag')

urlpatterns = [
    path('', include(router.urls)),
]
