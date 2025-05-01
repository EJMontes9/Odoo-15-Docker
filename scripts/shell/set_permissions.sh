#!/bin/bash

# Establecer permisos correctos
chmod -R 755 /scripts
chmod -R 644 /backups
chmod -R 644 /logs
chmod -R 644 /logs_script
chmod -R 755 /config/duplicati

# Asegurar que Duplicati puede acceder a los directorios
chown -R 1000:1000 /backups
chown -R 1000:1000 /logs