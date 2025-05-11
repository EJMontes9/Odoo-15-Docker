# Configuración de Base de Datos desde el Contenedor PostgreSQL

## Descripción

Este documento explica cómo configurar la base de datos Odoo directamente desde el contenedor PostgreSQL, en lugar de hacerlo desde el contenedor Odoo.

## Cambios Realizados

Se han realizado los siguientes cambios en el sistema:

1. Se ha creado un nuevo script `db_setup.sh` que se ejecuta dentro del contenedor PostgreSQL y realiza las siguientes acciones:
   - Verifica si la base de datos `odoo` existe
   - Si no existe, la crea automáticamente
   - Busca el archivo `.dump` más reciente en la carpeta `/backups`
   - Restaura ese archivo en la base de datos `odoo`

2. Se ha creado un script `setup_db_from_host.sh` que se ejecuta desde la máquina host y realiza las siguientes acciones:
   - Copia el script `db_setup.sh` al contenedor PostgreSQL
   - Lo hace ejecutable
   - Lo ejecuta dentro del contenedor PostgreSQL

3. Se ha modificado el script `entrypoint.sh` del contenedor Odoo para eliminar la configuración de la base de datos, ya que ahora se realiza desde el contenedor PostgreSQL.

## Cómo Usar

Para configurar la base de datos Odoo:

1. Asegúrate de que los contenedores estén en ejecución:
   ```bash
   docker-compose up -d
   ```

2. Ejecuta el script desde la máquina host:

   **Para Linux/Mac:**
   ```bash
   ./scripts/shell/setup_db_from_host.sh
   ```

   **Para Windows (PowerShell):**
   ```powershell
   .\scripts\shell\setup_db_from_host.ps1
   ```

3. El script copiará `db_setup.sh` al contenedor PostgreSQL, lo hará ejecutable y lo ejecutará.

4. Si la base de datos `odoo` no existe, se creará y se restaurará el archivo `.dump` más reciente de la carpeta `./backups/db`.

## Ventajas de este Enfoque

1. **Simplicidad**: Todas las operaciones de base de datos se realizan directamente en el contenedor PostgreSQL, sin necesidad de herramientas cliente en el contenedor Odoo.

2. **Rendimiento**: La restauración de la base de datos es más rápida cuando se realiza directamente en el contenedor PostgreSQL.

3. **Seguridad**: No es necesario exponer credenciales de base de datos en el contenedor Odoo.

## Solución de Problemas

Si encuentras problemas con la configuración de la base de datos:

1. **Verifica que los contenedores estén en ejecución**:

   **Linux/Mac:**
   ```bash
   docker ps | grep odoo
   ```

   **Windows (PowerShell):**
   ```powershell
   docker ps | Select-String odoo
   ```

2. **Verifica los logs del contenedor PostgreSQL**:
   ```bash
   docker logs odoo-db
   ```

3. **Ejecuta el script manualmente en el contenedor PostgreSQL**:
   ```bash
   docker exec -it odoo-db bash
   cd /tmp
   ./db_setup.sh
   ```

4. **Verifica que el archivo `.dump` exista en la carpeta `./backups/db`**:

   **Linux/Mac:**
   ```bash
   ls -la ./backups/db
   ```

   **Windows (PowerShell):**
   ```powershell
   Get-ChildItem -Path .\backups\db -Force
   ```

5. **Problemas específicos de Windows**:
   - Si recibes errores de permisos al ejecutar el script PowerShell, intenta ejecutar PowerShell como administrador.
   - Si el script no encuentra el archivo db_setup.sh, verifica la ruta y asegúrate de que estás ejecutando el script desde la raíz del proyecto.
   - Si recibes errores de formato de línea (CRLF vs LF), asegúrate de que el archivo db_setup.sh tenga el formato de línea correcto para Linux (LF).

## Notas Adicionales

- Este enfoque requiere que Docker esté instalado en la máquina host y que los contenedores estén en ejecución.
- Los scripts deben ejecutarse desde la raíz del proyecto:
  - En Linux/Mac: `setup_db_from_host.sh`
  - En Windows: `setup_db_from_host.ps1`
- Automatización:
  - En Linux/Mac: Puedes agregar el script a un cron job o a un script de inicio.
  - En Windows: Puedes crear una tarea programada o agregar el script a un script de inicio de PowerShell.
- En Windows, asegúrate de que la política de ejecución de PowerShell permita ejecutar scripts. Puedes cambiarla temporalmente con:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
