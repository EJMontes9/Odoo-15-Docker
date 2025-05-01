#!/bin/bash

# Directorio de backups
BACKUP_DIR="/backups"
LOG_FILE="/logs/backup_check.log"

# Función para verificar backups
check_backups() {
    echo "$(date): Iniciando verificación de backups..." >> "$LOG_FILE"

    # Verificar backups de DB
    DB_BACKUPS=$(ls -1 $BACKUP_DIR/db/ 2>/dev/null | wc -l)
    echo "Backups de DB encontrados: $DB_BACKUPS" >> "$LOG_FILE"

    # Verificar backups del sistema
    SYS_BACKUPS=$(ls -1 $BACKUP_DIR/system/ 2>/dev/null | wc -l)
    echo "Backups del sistema encontrados: $SYS_BACKUPS" >> "$LOG_FILE"

    # Verificar espacio en disco
    DISK_SPACE=$(df -h $BACKUP_DIR | tail -1 | awk '{print $5}')
    echo "Espacio en disco usado: $DISK_SPACE" >> "$LOG_FILE"

    # Alertar si el espacio en disco es mayor al 80%
    if [ "${DISK_SPACE%?}" -gt 80 ]; then
        echo "¡ALERTA! Espacio en disco crítico" >> "$LOG_FILE"
    fi
}

# Ejecutar verificación
check_backups