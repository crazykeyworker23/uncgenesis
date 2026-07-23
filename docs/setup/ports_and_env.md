# GUÍA DE PUERTOS Y VARIABLES DE ENTORNO

Este documento recopila las configuraciones de puertos de los contenedores Docker y define las variables de entorno requeridas para el correcto funcionamiento del ecosistema.

---

## 1. Mapeo de Puertos Locales

Para evitar conflictos de puertos en la máquina host durante el desarrollo local, se han reservado y configurado los siguientes puertos estándar:

| Servicio | Puerto Interno (Docker) | Puerto Externo (Host) | Protocolo | Descripción |
|---|:---:|:---:|:---:|---|
| **db** | `5432` | `5432` | TCP | Base de datos PostgreSQL central |
| **redis** | `6379` | `6379` | TCP | Cache de datos y Broker para Celery |
| **backend** | `8000` | `8000` | HTTP | API REST de Django + DRF |
| **frontend_admin** | `5173` | `5173` | HTTP | Servidor de desarrollo React + Vite |

---

## 2. Configuración del Backend (Django)

El archivo `.env` del backend debe ubicarse en `/backend/.env`.

### Variables Clave

- `SECRET_KEY`: Llave de seguridad de Django. Debe ser un hash largo y aleatorio en producción.
- `DEBUG`: Define si se muestran mensajes de error detallados (`True` o `False`). En producción debe ser `False`.
- `ALLOWED_HOSTS`: Lista de hosts/dominios permitidos para recibir peticiones, separados por comas.
- `DATABASE_URL`: URI de conexión a la base de datos PostgreSQL.
- `REDIS_URL`: URI de conexión a la instancia de Redis.
- `CORS_ALLOWED_ORIGINS`: Lista de orígenes cruzados (CORS) permitidos para consumir la API (ej. la URL del panel React).

---

## 3. Configuración del Frontend Administrativo (React)

El archivo `.env` de React debe ubicarse en `/frontend-admin/.env`.

### Variables Clave

- `VITE_API_URL`: Dirección base de la API de Django REST Framework (ej. `http://localhost:8000/api/v1`).
- `VITE_GOOGLE_CLIENT_ID`: Identificador de cliente de Google para habilitar el inicio de sesión OAuth en la web.

---

## 4. Configuración de la Aplicación Móvil (Flutter)

La URL de la API se inyecta en tiempo de ejecución o compilación usando variables de entorno o `--dart-define`.

### Ejemplos de Conexión en Desarrollo

- **Simulador de iOS**: Se conecta al backend a través de `http://localhost:8000/api/v1`.
- **Emulador de Android**: Se conecta al backend a través de `http://10.0.2.2:8000/api/v1` (dirección loopback especial que apunta al host local de la máquina de desarrollo).
- **Dispositivo Físico**: Requiere que la computadora y el dispositivo móvil estén en la misma red Wi-Fi. La URL de la API debe ser `http://<IP_DE_TU_COMPUTADORA>:8000/api/v1`.
