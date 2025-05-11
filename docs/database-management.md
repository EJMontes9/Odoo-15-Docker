# Gestión de Base de Datos / Database Management

## Descripción / Description

Este documento explica las opciones disponibles para configurar y gestionar la base de datos PostgreSQL para Odoo.

This document explains the available options for configuring and managing the PostgreSQL database for Odoo.

## Métodos de Configuración / Configuration Methods

### 1. Configuración desde el Contenedor PostgreSQL (Recomendado) / Configuration from PostgreSQL Container (Recommended)

Este método configura la base de datos directamente desde el contenedor PostgreSQL, ofreciendo mayor simplicidad, rendimiento y seguridad.

This method configures the database directly from the PostgreSQL container, offering greater simplicity, performance, and security.

#### Pasos / Steps:

1. Coloca tu archivo `.dump` en la carpeta `./backups/db` de tu máquina anfitriona
   
   Place your `.dump` file in the `./backups/db` folder on your host machine

2. Inicia los contenedores con `docker-compose up -d`
   
   Start the containers with `docker-compose up -d`

3. Ejecuta el script de configuración:
   
   Run the configuration script:

   **Para Linux/Mac / For Linux/Mac:**
   ```bash
   ./scripts/shell/setup_db_from_host.sh
   ```

   **Para Windows (PowerShell) / For Windows (PowerShell):**
   ```powershell
   .\scripts\shell\setup_db_from_host.ps1
   ```

#### Ventajas / Advantages:

- **Simplicidad / Simplicity**: Todas las operaciones de base de datos se realizan directamente en el contenedor PostgreSQL.
  
  All database operations are performed directly in the PostgreSQL container.

- **Rendimiento / Performance**: La restauración de la base de datos es más rápida cuando se realiza directamente en el contenedor PostgreSQL.
  
  Database restoration is faster when performed directly in the PostgreSQL container.

- **Seguridad / Security**: No es necesario exponer credenciales de base de datos en el contenedor Odoo.
  
  No need to expose database credentials in the Odoo container.

### 2. Método Anterior: Automatización desde el Contenedor Odoo / Previous Method: Automation from Odoo Container

> **Nota / Note**: Este método ya no se utiliza por defecto, pero se mantiene la documentación por compatibilidad.
> 
> This method is no longer used by default, but the documentation is maintained for compatibility.

El sistema incluía un script de automatización que:

The system included an automation script that:

1. Verifica si la base de datos `odoo` existe
   
   Checks if the `odoo` database exists

2. Si no existe, la crea automáticamente
   
   If it doesn't exist, creates it automatically

3. Busca el archivo `.dump` más reciente en la carpeta `./backups/db`
   
   Looks for the most recent `.dump` file in the `./backups/db` folder

4. Restaura ese archivo en la base de datos `odoo`
   
   Restores that file to the `odoo` database

Este proceso se ejecutaba automáticamente al iniciar el contenedor de Odoo.

This process was executed automatically when starting the Odoo container.

### 3. Creación y Restauración Manual / Manual Creation and Restoration

Si prefieres realizar el proceso manualmente, puedes seguir estos pasos:

If you prefer to perform the process manually, you can follow these steps:

#### Crear la base de datos `odoo` manualmente / Create the `odoo` database manually:

1. Accede al contenedor de la base de datos:
   
   Access the database container:
   ```bash
   docker exec -it odoo-db bash
   ```

2. Ingresa al cliente PostgreSQL:
   
   Enter the PostgreSQL client:
   ```bash
   psql -U odoo -d postgres
   ```

3. Crea la base de datos `odoo` y asígnala al usuario `odoo`:
   
   Create the `odoo` database and assign it to the `odoo` user:
   ```sql
   CREATE DATABASE odoo OWNER odoo;
   ```

4. Verifica que la base de datos fue creada correctamente:
   
   Verify that the database was created correctly:
   ```sql
   \l
   ```

5. Sal del cliente PostgreSQL:
   
   Exit the PostgreSQL client:
   ```sql
   \q
   ```

#### Restaurar la base de datos `odoo` manualmente desde un archivo `.dump` / Restore the `odoo` database manually from a `.dump` file:

1. Coloca el archivo `.dump` en la carpeta `./backups/db` en tu máquina anfitriona
   
   Place the `.dump` file in the `./backups/db` folder on your host machine

2. Accede al contenedor del servicio PostgreSQL:
   
   Access the PostgreSQL service container:
   ```bash
   docker exec -it odoo-db bash
   ```

3. Dentro del contenedor, restaura el `.dump` en la base de datos `odoo`:
   
   Inside the container, restore the `.dump` to the `odoo` database:
   ```bash
   pg_restore -U odoo -d odoo /backups/archivo.dump
   ```

4. Verifica que las tablas se restauraron correctamente:
   
   Verify that the tables were restored correctly:
   ```bash
   psql -U odoo -d odoo -c "\dt"
   ```

## Solución de Problemas / Troubleshooting

### Error de PostgreSQL Client / PostgreSQL Client Error

Si encuentras un error como:

If you encounter an error like:

```
/opt/scripts/shell/setup_odoo_db.sh: line 12: psql: command not found
```

Este error ocurre porque el contenedor de Odoo no tiene instaladas las herramientas cliente de PostgreSQL, necesarias para ejecutar los comandos `psql` y `pg_restore`.

This error occurs because the Odoo container does not have the PostgreSQL client tools installed, which are necessary to run the `psql` and `pg_restore` commands.

#### Solución / Solution:

Se ha modificado el Dockerfile para incluir el paquete `postgresql-client`, que proporciona las herramientas necesarias.

The Dockerfile has been modified to include the `postgresql-client` package, which provides the necessary tools.

Para aplicar esta solución, es necesario reconstruir la imagen Docker:

To apply this solution, it is necessary to rebuild the Docker image:

```bash
docker-compose down
docker-compose build
docker-compose up -d
```

### Problemas con el Método de Configuración desde PostgreSQL / Issues with the Configuration Method from PostgreSQL

Si encuentras problemas con la configuración de la base de datos:

If you encounter problems with the database configuration:

1. **Verifica que los contenedores estén en ejecución / Verify that the containers are running**:

   **Linux/Mac:**
   ```bash
   docker ps | grep odoo
   ```

   **Windows (PowerShell):**
   ```powershell
   docker ps | Select-String odoo
   ```

2. **Verifica los logs del contenedor PostgreSQL / Check the PostgreSQL container logs**:
   ```bash
   docker logs odoo-db
   ```

3. **Ejecuta el script manualmente en el contenedor PostgreSQL / Run the script manually in the PostgreSQL container**:
   ```bash
   docker exec -it odoo-db bash
   cd /tmp
   ./db_setup.sh
   ```

4. **Verifica que el archivo `.dump` exista en la carpeta `./backups/db` / Verify that the `.dump` file exists in the `./backups/db` folder**:

   **Linux/Mac:**
   ```bash
   ls -la ./backups/db
   ```

   **Windows (PowerShell):**
   ```powershell
   Get-ChildItem -Path .\backups\db -Force
   ```

5. **Problemas específicos de Windows / Windows-specific issues**:
   - Si recibes errores de permisos al ejecutar el script PowerShell, intenta ejecutar PowerShell como administrador.
     
     If you receive permission errors when running the PowerShell script, try running PowerShell as administrator.
   - Si el script no encuentra el archivo db_setup.sh, verifica la ruta y asegúrate de que estás ejecutando el script desde la raíz del proyecto.
     
     If the script cannot find the db_setup.sh file, check the path and make sure you are running the script from the project root.
   - Si recibes errores de formato de línea (CRLF vs LF), asegúrate de que el archivo db_setup.sh tenga el formato de línea correcto para Linux (LF).
     
     If you receive line format errors (CRLF vs LF), make sure the db_setup.sh file has the correct line format for Linux (LF).