import os
from pathlib import Path
from datetime import timedelta
import environ

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Initialize environ
env = environ.Env()
# Read .env file if it exists
environ.Env.read_env(os.path.join(BASE_DIR, '.env'))

SECRET_KEY = env('SECRET_KEY', default='django-insecure-default-change-me')

ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['localhost', '127.0.0.1'])

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third party apps
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'corsheaders',
    'django_filters',
    'drf_spectacular',

    # Local apps
    'apps.users.apps.UsersConfig',
    'apps.roles.apps.RolesConfig',
    'apps.authentication.apps.AuthenticationConfig',
    'apps.settings_app.apps.SettingsAppConfig',
    'apps.audit.apps.AuditConfig',
    'apps.publications.apps.PublicationsConfig',
    'apps.services.apps.ServicesConfig',
    'apps.devotionals.apps.DevotionalsConfig',
    'apps.events.apps.EventsConfig',
    'apps.cells.apps.CellsConfig',
    'apps.church_requests.apps.RequestsConfig',
    'apps.notifications.apps.NotificationsConfig',
    'apps.multimedia.apps.MultimediaConfig',
    'apps.reports.apps.ReportsConfig',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = 'config.asgi.application'

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Custom User Model
AUTH_USER_MODEL = 'users.CustomUser'

# Internationalization
LANGUAGE_CODE = 'es-pe'
TIME_ZONE = 'America/Lima'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# CORS and CSRF Config
CORS_ALLOW_ALL_ORIGINS = env.bool('CORS_ALLOW_ALL_ORIGINS', default=True)
CORS_ALLOWED_ORIGINS = env.list('CORS_ALLOWED_ORIGINS', default=[
    'http://localhost:5173',
    'http://127.0.0.1:5173',
    'http://localhost',
    'http://72.61.48.152',
    'http://72.61.48.152:8080',
])
CORS_ALLOW_CREDENTIALS = True

CSRF_TRUSTED_ORIGINS = env.list('CSRF_TRUSTED_ORIGINS', default=[
    'http://localhost',
    'http://127.0.0.1',
    'http://72.61.48.152',
    'http://72.61.48.152:8080',
])

# Dirección del panel, para los enlaces que se mandan por correo.
#
# Se tomaba el primer origen de CORS, que es otra cosa: esa lista dice quién
# puede llamar a la API, no a dónde mandar a la persona. Si además quedaba
# vacía, el enlace de recuperar contraseña rompía la petición.
FRONTEND_URL = env(
    'FRONTEND_URL',
    default=(CORS_ALLOWED_ORIGINS[0] if CORS_ALLOWED_ORIGINS else 'http://localhost'),
).rstrip('/')

# Django REST Framework Config
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10,
    'DEFAULT_FILTER_BACKENDS': (
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
    ),
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

# Simple JWT Config
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=15),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUDIENCE': None,
    'ISSUER': None,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'TOKEN_OBTAIN_SERIALIZER': 'apps.authentication.serializers.CustomTokenObtainPairSerializer',
}

# DRF Spectacular Config
SPECTACULAR_SETTINGS = {
    'TITLE': 'Génesis API',
    'DESCRIPTION': 'API central del ecosistema digital Génesis App',
    'VERSION': '1.0.0',
    'SERVE_INCLUDE_SCHEMA': False,
}

# Email configurations
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = env('EMAIL_HOST', default='localhost')
EMAIL_PORT = env.int('EMAIL_PORT', default=1025)
EMAIL_HOST_USER = env('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = env('EMAIL_HOST_PASSWORD', default='')
EMAIL_USE_TLS = env.bool('EMAIL_USE_TLS', default=True)
DEFAULT_FROM_EMAIL = EMAIL_HOST_USER

# Celery
#
# Estas dos claves no estaban definidas en ninguna parte. Celery, al no
# encontrarlas, usaba su valor por omisión —RabbitMQ en localhost—, que aquí no
# existe: el trabajador llevaba desde el principio sin poder conectarse. El
# efecto era silencioso y difícil de ver: los avisos programados (entre ellos el
# recordatorio de los devocionales a las 7:00) nunca llegaban a ejecutarse.
#
# CELERY_BROKER_URL se define en docker-compose apuntando a una base de Redis
# distinta a la de la caché, para que vaciar la caché no se lleve por delante
# la cola. Si no viniera, se cae a REDIS_URL: con la cola compartida se pierden
# tareas al limpiar la caché, pero al menos el trabajador arranca.
CELERY_BROKER_URL = env(
    'CELERY_BROKER_URL',
    default=env('REDIS_URL', default='redis://redis:6379/0'),
)
CELERY_RESULT_BACKEND = env('CELERY_RESULT_BACKEND', default=CELERY_BROKER_URL)
CELERY_TIMEZONE = TIME_ZONE

# Red de seguridad: si un envío programado se pierde porque el servidor estaba
# reiniciándose o el broker no respondía, esta ronda lo recoge igualmente en
# cuanto vence su hora, en lugar de dejarlo pendiente para siempre.
CELERY_BEAT_SCHEDULE = {
    'entregar-notificaciones-pendientes': {
        'task': 'apps.notifications.tasks.deliver_pending_notifications',
        'schedule': 300.0,  # cada 5 minutos
    },
}

# Firebase configurations
#
# Se admiten dos formas, porque pegar el JSON entero de la cuenta de servicio
# dentro de una variable de entorno es fácil de estropear (la clave privada
# lleva saltos de línea):
#
#   FIREBASE_CREDENTIALS={"type":"service_account", ...}   ← JSON en una línea
#   FIREBASE_CREDENTIALS=/etc/genesis/firebase.json        ← ruta al archivo
#
# Antes se usaba `env.json`, que revienta al arrancar si el valor no es JSON
# válido: un error de copiado dejaba el servidor entero sin levantar. Ahora se
# anota el problema y el sitio funciona; sólo dejan de salir los avisos al
# teléfono, y quedan igualmente registrados dentro de la app.
def _cargar_credenciales_firebase():
    import json
    import logging

    valor = (env('FIREBASE_CREDENTIALS', default='') or '').strip()
    if not valor:
        return None

    if valor.startswith('{'):
        try:
            return json.loads(valor)
        except ValueError:
            logging.getLogger('config.settings').error(
                'FIREBASE_CREDENTIALS no es un JSON válido: las notificaciones '
                'quedarán registradas pero no saldrán al teléfono.'
            )
            return None

    if os.path.exists(valor):
        # firebase_admin acepta directamente la ruta del archivo.
        return valor

    logging.getLogger('config.settings').error(
        'FIREBASE_CREDENTIALS apunta a un archivo que no existe (%s).', valor
    )
    return None


FIREBASE_CREDENTIALS = _cargar_credenciales_firebase()

