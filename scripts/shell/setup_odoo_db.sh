#!/bin/bash
# Script to automatically create and restore the Odoo database
# This script will:
# 1. Check if the "odoo" database exists
# 2. If not, create it
# 3. Find the latest dump file in the /backups directory
# 4. Restore that dump file to the "odoo" database

set -e

echo "Verificando si la base de datos 'odoo' existe..."
DB_EXISTS=$(PGPASSWORD=${PASSWORD} psql -h ${HOST} -U ${USER} -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='odoo'")

if [ "$DB_EXISTS" != "1" ]; then
    echo "La base de datos 'odoo' no existe. Creándola..."
    PGPASSWORD=${PASSWORD} psql -h ${HOST} -U ${USER} -d postgres -c "CREATE DATABASE odoo OWNER ${USER};"
    echo "Base de datos 'odoo' creada exitosamente."

    # Buscar el archivo dump más reciente en el directorio /backups
    echo "Buscando el archivo dump más reciente en /backups..."
    LATEST_DUMP=$(find /backups -name "*.dump" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

    if [ -n "$LATEST_DUMP" ]; then
        echo "Encontrado archivo dump: $LATEST_DUMP"
        echo "Restaurando dump en la base de datos 'odoo'..."
        PGPASSWORD=${PASSWORD} pg_restore -h ${HOST} -U ${USER} -d odoo "$LATEST_DUMP"
        echo "Restauración completada exitosamente."
    else
        echo "No se encontraron archivos dump en /backups."
    fi
else
    echo "La base de datos 'odoo' ya existe. No se realizará ninguna acción."
fi
