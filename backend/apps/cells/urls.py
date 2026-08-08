from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import CellGroupViewSet
from .views_management import CellMeetingViewSet, MemberFollowUpViewSet

router = DefaultRouter()
router.register(r'cells', CellGroupViewSet, basename='cells')
router.register(r'cell-meetings', CellMeetingViewSet, basename='cell-meetings')
router.register(r'cell-follow-ups', MemberFollowUpViewSet, basename='cell-follow-ups')

urlpatterns = [
    path('', include(router.urls)),
]
