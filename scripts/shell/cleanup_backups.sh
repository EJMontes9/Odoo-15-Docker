#!/bin/bash

# Configuración
BACKUP_DIR="/backups"
RETENTION_DAYS=30
LOG_FILE="/logs/backup_cleanup.log"

# Función de limpieza
cleanup_old_backups() {
    echo "$(date): Iniciando limpieza de backups antiguos..." >> "$LOG_FILE"

    # Limpiar backups de DB antiguos
    find "$BACKUP_DIR/db" -type f -mtime +$RETENTION_DAYS -delete -print >> "$LOG_FILE"

    # Limpiar backups del sistema antiguos
    find "$BACKUP_DIR/system" -type f -mtime +$RETENTION_DAYS -delete -print >> "$LOG_FILE"

    echo "Limpieza completada" >> "$LOG_FILE"
}

# Ejecutar limpieza
cleanup_old_backups