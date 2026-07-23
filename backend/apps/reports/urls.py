from django.urls import path
from .views import ReportsSummaryAPIView, ReportsExportAPIView, DashboardStatsAPIView

urlpatterns = [
    path('dashboard/', DashboardStatsAPIView.as_view(), name='reports-dashboard'),
    path('summary/', ReportsSummaryAPIView.as_view(), name='reports-summary'),
    path('export/', ReportsExportAPIView.as_view(), name='reports-export'),
]

