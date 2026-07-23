#!/bin/bash
set -e

echo "=================================================="
echo "   Iniciando Despliegue de Génesis App en VPS     "
echo "=================================================="

# 1. Obtener cambios del repositorio
echo "[1/3] Actualizando código desde Git..."
git pull origin main || git pull origin master

# 2. Reconstruir e iniciar contenedores
echo "[2/3] Compilando e iniciando servicios en Docker..."
docker compose down
docker compose up -d --build

# 3. Mostrar estado
echo "[3/3] Verificando estado de los servicios:"
docker compose ps

echo "=================================================="
echo " ¡Despliegue Exitoso! Escuchando en el puerto 80.  "
echo "=================================================="
