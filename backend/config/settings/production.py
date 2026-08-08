from .base import *

DEBUG = False

# Database
DATABASES = {
    'default': env.db('DATABASE_URL')
}

# Redis Cache Settings
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': env('REDIS_URL'),
    }
}

# ── Seguridad HTTP ───────────────────────────────────────────────────────────
# El despliegue actual atiende en http://<ip>:8080 sin certificado TLS. Forzar
# HTTPS aquí dejaría la app móvil y el panel sin servicio, así que las medidas
# que dependen de TLS se activan por variable de entorno.
#
# Cuando el servidor tenga certificado, basta con poner en el .env del VPS:
#   USE_HTTPS=True
USE_HTTPS = env.bool('USE_HTTPS', default=False)

SECURE_SSL_REDIRECT = env.bool('SECURE_SSL_REDIRECT', default=USE_HTTPS)
SESSION_COOKIE_SECURE = USE_HTTPS
CSRF_COOKIE_SECURE = USE_HTTPS
SECURE_HSTS_SECONDS = 31536000 if USE_HTTPS else 0
SECURE_HSTS_INCLUDE_SUBDOMAINS = USE_HTTPS
SECURE_HSTS_PRELOAD = USE_HTTPS

if USE_HTTPS:
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Estas no dependen de TLS y se aplican siempre.
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'

# ── CORS ─────────────────────────────────────────────────────────────────────
# Nginx sirve el panel y la API en el mismo origen, y la app móvil no es un
# navegador: ninguno necesita CORS abierto. En desarrollo sigue permitido todo.
# Si algún cliente externo lo necesitara, se listan sus orígenes en
# CORS_ALLOWED_ORIGINS del .env.
CORS_ALLOW_ALL_ORIGINS = env.bool('CORS_ALLOW_ALL_ORIGINS', default=False)

# ── Tareas asíncronas ────────────────────────────────────────────────────────
# En producción las tareas van al broker y respetan su fecha programada. El
# modo "eager" de desarrollo las ejecutaba al instante, por lo que el aviso del
# devocional de las 7 AM y los recordatorios programados de célula salían de
# inmediato en lugar de a su hora.
CELERY_TASK_ALWAYS_EAGER = False
CELERY_TASK_EAGER_PROPAGATES = False

# ── Aviso de configuración ───────────────────────────────────────────────────
# SECRET_KEY firma los tokens JWT: con el valor por defecto cualquiera podría
# emitir sesiones válidas. No se corta el arranque para no dejar el servicio
# caído, pero el aviso queda registrado en el log del contenedor.
if SECRET_KEY == 'django-insecure-default-change-me':
    import warnings

    warnings.warn(
        'SECRET_KEY no está definida en el entorno: se está usando el valor por '
        'defecto, que es público. Define SECRET_KEY en el .env del servidor.',
        RuntimeWarning,
    )
