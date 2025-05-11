#!/bin/bash
set -e

# Setup wkhtmltopdf symbolic link
echo "Configurando wkhtmltopdf..."
chmod +x /opt/scripts/shell/setup_wkhtmltopdf_link.sh
/opt/scripts/shell/setup_wkhtmltopdf_link.sh

# Ensure filestore directory structure exists
echo "Configurando estructura de directorios para filestore..."
mkdir -p /var/lib/odoo/filestore/odoo
chown -R odoo:odoo /var/lib/odoo
chmod -R 755 /var/lib/odoo

# Esperar a que PostgreSQL esté disponible
echo "Esperando a que PostgreSQL esté disponible..."
wait-for-it.py ${HOST}:5432 -t 60

# Nota: La configuración de la base de datos ahora se realiza desde el host
# usando el script setup_db_from_host.sh

# Iniciar Odoo
echo "Iniciando Odoo..."
exec python3.10 /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf
