#!/bin/bash
# Script to set up the Odoo database from the host machine
# This script will:
# 1. Copy the db_setup.sh script to the PostgreSQL container
# 2. Make it executable
# 3. Execute it in the PostgreSQL container

set -e

echo "Copiando script de configuración de base de datos al contenedor PostgreSQL..."
docker cp $(dirname "$0")/db_setup.sh odoo-db:/tmp/db_setup.sh

echo "Haciendo el script ejecutable..."
docker exec odoo-db chmod +x /tmp/db_setup.sh

echo "Ejecutando script de configuración de base de datos en el contenedor PostgreSQL..."
docker exec odoo-db /tmp/db_setup.sh

echo "Configuración de base de datos completada."