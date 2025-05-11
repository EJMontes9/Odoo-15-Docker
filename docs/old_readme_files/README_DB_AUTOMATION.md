# Automatización de Creación y Restauración de Base de Datos

Este documento explica la funcionalidad de automatización para crear y restaurar la base de datos Odoo.

## Descripción

El sistema ahora incluye un script de automatización (`setup_odoo_db.sh`) que se ejecuta durante el inicio del contenedor Odoo y realiza las siguientes acciones:

1. Verifica si la base de datos `odoo` existe
2. Si no existe, la crea automáticamente
3. Busca el archivo `.dump` más reciente en la carpeta `/backups` (que corresponde a `./backups/db` en el host)
4. Restaura ese archivo en la base de datos `odoo`

## Cómo Usar

Para utilizar esta funcionalidad:

1. Coloca tu archivo de respaldo (con extensión `.dump`) en la carpeta `./backups/db` de tu máquina anfitriona
2. Inicia los contenedores con `docker-compose up -d`
3. El sistema detectará automáticamente el archivo más reciente y lo restaurará si la base de datos no existe

## Verificación

Puedes verificar que la automatización funcionó correctamente de las siguientes maneras:

1. Revisar los logs del contenedor Odoo:
   ```bash
   docker logs odoo-app
   ```
   Deberías ver mensajes como:
   - "Verificando si la base de datos 'odoo' existe..."
   - "La base de datos 'odoo' no existe. Creándola..."
   - "Buscando el archivo dump más reciente en /backups..."
   - "Encontrado archivo dump: /backups/[nombre_del_archivo].dump"
   - "Restauración completada exitosamente."

2. Conectarte a la base de datos para verificar que se creó correctamente:
   ```bash
   docker exec -it odoo-db psql -U odoo -d odoo -c "\dt"
   ```
   Esto debería mostrar las tablas restauradas.

## Solución de Problemas

Si encuentras problemas con la automatización:

1. **No se encuentra ningún archivo dump**:
   - Verifica que los archivos tengan la extensión `.dump`
   - Asegúrate de que estén en la carpeta `./backups/db`
   - Comprueba los permisos de los archivos

2. **Error al restaurar el dump**:
   - Verifica que el formato del dump sea compatible con `pg_restore`
   - Asegúrate de que el usuario `odoo` tenga permisos suficientes

3. **La base de datos ya existe pero quieres restaurarla**:
   - Si necesitas forzar la recreación de la base de datos, puedes eliminarla primero:
     ```bash
     docker exec -it odoo-db psql -U odoo -d postgres -c "DROP DATABASE odoo;"
     ```
   - Luego reinicia el contenedor Odoo:
     ```bash
     docker restart odoo-app
     ```

## Personalización

Si necesitas personalizar el comportamiento del script:

1. Edita el archivo `scripts/shell/setup_odoo_db.sh`
2. Realiza tus modificaciones (por ejemplo, cambiar el nombre de la base de datos o el patrón de búsqueda de archivos)
3. Reinicia el contenedor Odoo:
   ```bash
   docker restart odoo-app
   ```