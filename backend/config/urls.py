from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

api_v1_patterns = [
    path('auth/', include('apps.authentication.urls')),
    path('settings/', include('apps.settings_app.urls')),
    path('audit/', include('apps.audit.urls')),
    path('', include('apps.publications.urls')),
    path('', include('apps.services.urls')),
    path('', include('apps.devotionals.urls')),
    path('', include('apps.events.urls')),
    path('', include('apps.cells.urls')),
    path('', include('apps.church_requests.urls')),
    path('notifications/', include('apps.notifications.urls')),
    path('users/', include('apps.users.urls')),
    path('roles/', include('apps.roles.urls')),
    path('multimedia/', include('apps.multimedia.urls')),
    path('reports/', include('apps.reports.urls')),
]

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/', include(api_v1_patterns)),
    
    # OpenAPI Schema and Interactive Docs
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
