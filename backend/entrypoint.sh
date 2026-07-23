#!/bin/sh
set -e

echo "=== Ejecutando migraciones de base de datos ==="
python manage.py migrate --noinput

echo "=== Recopilando archivos estáticos de Django ==="
python manage.py collectstatic --noinput

exec "$@"
