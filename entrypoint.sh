#!/bin/bash
set -e

# Esperar a que PostgreSQL esté disponible
echo "Esperando a que PostgreSQL esté disponible..."
wait-for-it.py ${HOST}:5432 -t 60

# Iniciar Odoo
echo "Iniciando Odoo..."
exec python3 /opt/odoo/odoo-bin -c /etc/odoo/odoo.conf
