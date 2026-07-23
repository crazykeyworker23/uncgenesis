# GÉNESIS APP - ECOSISTEMA DIGITAL CENTRAL

Ecosistema digital completo para la iglesia y comunidad **Génesis**. Este proyecto está organizado en un monorepo que contiene tres componentes principales: el backend administrativo, el panel de administración web y la aplicación móvil.

---

## 1. Arquitectura General y Conexión

El backend de Django REST Framework actúa como la **única fuente de verdad** para el sistema. El panel administrativo en React y la aplicación móvil en Flutter se conectan a él mediante peticiones HTTP/HTTPS a la API `/api/v1/`.

```
                 [ PostgreSQL ]
                       ▲
                       │
               [ Django Backend ]
                  /api/v1/
                  ▲      ▲
                 /        \
                /          \
      [ Flutter App ]    [ React Admin ]
        mobile-app/      frontend-admin/
```

---

## 2. Estructura del Monorepo

El repositorio está organizado en las siguientes carpetas:

```
genesis-app/
├── backend/            # Django, Django REST Framework, Celery, pytest
├── frontend-admin/     # React, Vite, TypeScript, Tailwind CSS, Zustand
├── mobile-app/         # Flutter, Dart, Riverpod, GoRouter, Dio
├── docs/               # Documentación de Arquitectura, APIs, Base de Datos y Guías
│   ├── architecture/   # Diseños arquitectónicos y diagramas
│   ├── api/            # Especificaciones de Endpoints (Swagger/Redoc)
│   ├── database/       # Diagramas del modelo de datos de PostgreSQL
│   └── setup/          # Guías de configuración y despliegue
├── docker-compose.yml  # Orquestador local para desarrollo (DB, Redis, Django, React)
├── .gitignore          # Exclusiones de Git globales por tecnología
└── README.md           # Este archivo
```

---

## 3. Asignación de Puertos

| Servicio | Tecnología | Puerto Host | Descripción |
|---|---|---|---|
| **PostgreSQL** | PostgreSQL 15 | `5432` | Base de datos relacional central |
| **Redis** | Redis 7 | `6379` | Cache del sistema y Broker de tareas de Celery |
| **Django Backend** | Django + DRF | `8000` | Servidor de APIs REST y WebSocket |
| **React Web Admin** | React + Vite | `5173` | Panel de gestión y control administrativo |

---

## 4. Requisitos Previos de Desarrollo

Para ejecutar y colaborar en los proyectos locales se recomiendan las siguientes herramientas:
- **Docker & Docker Compose** (Instalación recomendada para base de datos y servicios asíncronos).
- **Python 3.11** (Para desarrollo del backend en local fuera de Docker).
- **Node.js v20+ & npm** (Para desarrollo de la web en local fuera de Docker).
- **Flutter SDK v3.22+ & Dart** (Para desarrollo de la aplicación móvil).

---

## 5. Guía de Inicio Rápido con Docker

### Paso 1: Configurar Variables de Entorno
Copia los archivos de ejemplo correspondientes a cada carpeta y configúralos con tus credenciales:
```bash
cp backend/.env.example backend/.env
cp frontend-admin/.env.example frontend-admin/.env
cp mobile-app/.env.example mobile-app/.env
```

### Paso 2: Levantar los Servicios mediante Docker Compose
Desde la raíz del repositorio, ejecuta:
```bash
docker compose up --build
```
Este comando construirá las imágenes y pondrá en marcha:
- Base de datos PostgreSQL (`db`)
- Servicio de Cache Redis (`redis`)
- Servidor de Desarrollo Django (`backend`) en http://localhost:8000
- Celery Worker (`celery_worker`) para tareas asíncronas
- Celery Beat (`celery_beat`) para planeación de tareas
- Servidor de Desarrollo React (`frontend_admin`) en http://localhost:5173

---

## 6. Documentación Detallada

Para más información sobre la arquitectura, base de datos, APIs y el onboarding técnico de desarrollo, por favor consulta la carpeta `/docs`:
- [Diseño Arquitectónico](file:///Users/finatech/igchurch/docs/architecture/architecture_design.md)
- [Esquema de Puertos y Variables de Entorno](file:///Users/finatech/igchurch/docs/setup/ports_and_env.md)
