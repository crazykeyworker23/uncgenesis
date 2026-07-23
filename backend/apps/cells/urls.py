from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import CellGroupViewSet

router = DefaultRouter()
router.register(r'cells', CellGroupViewSet, basename='cells')

urlpatterns = [
    path('', include(router.urls)),
]
