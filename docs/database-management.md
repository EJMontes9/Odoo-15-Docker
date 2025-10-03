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
6. **Eliminar una base de datos / Delete a database**:
   ```bash
   docker exec odoo-db psql -U odoo -d postgres -c "DROP DATABASE IF EXISTS odoo;"
   ```

## Regeneración de Assets de Odoo / Odoo Assets Regeneration

### Problema: Pantalla blanca y errores 404 en assets / Issue: White screen and 404 errors on assets

Si al intentar acceder a Odoo ves una pantalla blanca y en los logs encuentras errores como:

If when trying to access Odoo you see a white screen and in the logs you find errors like:

```
GET /web/assets/54466-f970e4c/web.assets_common.min.css HTTP/1.1" 404
GET /web/assets/54467-0775dd5/web.assets_backend.min.css HTTP/1.1" 404
GET /web/assets/54468-f970e4c/web.assets_common.min.js HTTP/1.1" 404
```

Esto indica que los assets están corruptos o no se han generado correctamente.

This indicates that the assets are corrupted or have not been generated correctly.

### Solución paso a paso / Step-by-step solution

#### 1. Detener el contenedor de Odoo / Stop the Odoo container

Primero, detén el contenedor de Odoo para liberar las conexiones a la base de datos:

First, stop the Odoo container to free up database connections:

```bash
docker stop odoo-app
```

#### 2. Listar las bases de datos existentes / List existing databases

Verifica qué bases de datos existen en PostgreSQL:

Check which databases exist in PostgreSQL:

```bash
docker exec odoo-db psql -U odoo -d postgres -c "\l"
```

**Salida esperada / Expected output:**
```
     Name     | Owner | Encoding |  Collate   |   Ctype
--------------+-------+----------+------------+------------
 odoo         | odoo  | UTF8     | en_US.utf8 | en_US.utf8
 odoo20250913 | odoo  | UTF8     | en_US.utf8 | en_US.utf8
 postgres     | odoo  | UTF8     | en_US.utf8 | en_US.utf8
```

#### 3. Limpiar assets corruptos de TODAS las bases de datos / Clean corrupted assets from ALL databases

**IMPORTANTE**: Debes limpiar los assets de CADA base de datos de Odoo que tengas, no solo de la base `postgres`.

**IMPORTANT**: You must clean the assets from EACH Odoo database you have, not just from the `postgres` database.

Para cada base de datos de Odoo que veas en el listado (ejemplo: `odoo`, `odoo20250913`), ejecuta:

For each Odoo database you see in the list (example: `odoo`, `odoo20250913`), run:

```bash
# Para la base de datos 'odoo' / For the 'odoo' database
docker exec odoo-db psql -U odoo -d odoo -c "DELETE FROM ir_attachment WHERE name LIKE 'web.assets_%' OR url LIKE '/web/assets/%';"

# Para otras bases de datos (ajusta el nombre) / For other databases (adjust the name)
docker exec odoo-db psql -U odoo -d odoo20250913 -c "DELETE FROM ir_attachment WHERE name LIKE 'web.assets_%' OR url LIKE '/web/assets/%';"
```

**Salida esperada / Expected output:**
```
DELETE 52  # Número de registros eliminados / Number of deleted records
```

#### 4. Verificar archivos de assets en filestore (opcional) / Check asset files in filestore (optional)

Si los archivos físicos están corruptos, puedes verificar el directorio de filestore:

If physical files are corrupted, you can check the filestore directory:

```bash
# Ver estructura del filestore / View filestore structure
docker exec odoo-app ls -la /var/lib/odoo/filestore/
```

#### 5. Reiniciar Odoo para regenerar assets / Restart Odoo to regenerate assets

Inicia el contenedor de Odoo nuevamente. Los assets se regenerarán automáticamente:

Start the Odoo container again. Assets will regenerate automatically:

```bash
docker start odoo-app
```

#### 6. Monitorear logs durante la regeneración / Monitor logs during regeneration

Observa los logs para asegurarte de que no haya errores durante la regeneración de assets:

Watch the logs to ensure there are no errors during asset regeneration:

```bash
docker logs -f odoo-app --tail 50
```

**Buscar estos mensajes / Look for these messages:**
- `Modules loaded` - Indica que los módulos cargaron correctamente / Indicates modules loaded correctly
- `Generating routing map` - Odoo está generando rutas / Odoo is generating routes
- Sin errores de variables SCSS faltantes / No missing SCSS variable errors

#### 7. Verificar acceso a Odoo / Verify Odoo access

Abre tu navegador y accede a: `http://localhost:8069`

La interfaz de Odoo debería cargar correctamente sin errores 404.

The Odoo interface should load correctly without 404 errors.

### Problema adicional: Variables SCSS faltantes / Additional issue: Missing SCSS variables

Si después de limpiar los assets sigues viendo errores como:

If after cleaning assets you still see errors like:

```
Error: Undefined variable: "$mk-appbar-background"
```

Esto indica que falta una variable SCSS en tu tema personalizado.

This indicates a missing SCSS variable in your custom theme.

#### Solución / Solution:

1. Identifica el archivo de variables del tema:

   Identify the theme variables file:
   ```bash
   # Ejemplo para aeroportuaria_theme
   # Example for aeroportuaria_theme
   addons/Aeroportuaria_ERP/themes/aeroportuaria_theme/static/src/variables.scss
   ```

2. Busca dónde se usa la variable faltante:

   Find where the missing variable is used:
   ```bash
   docker exec odoo-app grep -r "\$mk-appbar-background" /mnt/extra-addons/
   ```

3. Agrega la variable faltante al archivo `variables.scss`:

   Add the missing variable to the `variables.scss` file:
   ```scss
   //----------------------------------------------------------
   // AppBar Colors
   //----------------------------------------------------------

   $mk-appbar-color: #dee2e6;
   $mk-appbar-background: #000000;
   ```

4. Reinicia Odoo para aplicar los cambios:

   Restart Odoo to apply changes:
   ```bash
   docker restart odoo-app
   ```

### Comandos rápidos de referencia / Quick reference commands

```bash
# Ver todas las bases de datos / List all databases
docker exec odoo-db psql -U odoo -d postgres -c "\l"

# Limpiar assets de una base específica / Clean assets from specific database
docker exec odoo-db psql -U odoo -d NOMBRE_BD -c "DELETE FROM ir_attachment WHERE name LIKE 'web.assets_%' OR url LIKE '/web/assets/%';"

# Detener/Iniciar Odoo / Stop/Start Odoo
docker stop odoo-app
docker start odoo-app

# Ver logs en tiempo real / Watch logs in real-time
docker logs -f odoo-app --tail 50

# Reiniciar completamente / Full restart
docker restart odoo-app
```

## Eliminación Segura de Registros con Restricciones / Safe Deletion of Records with Restrictions

### Problema: Eliminar activo fijo con líneas de amortización asentadas / Issue: Delete fixed asset with posted depreciation lines

Cuando intentas eliminar un activo fijo desde la interfaz de Odoo y obtienes estos errores:

When trying to delete a fixed asset from Odoo's interface and you get these errors:

1. **Error al eliminar directamente**: "Sólo puede eliminar activos en estado borrador"
2. **Error al poner en borrador**: "No puede eliminar un activo que contenga líneas de amortización asentadas"

Este problema ocurre porque el activo tiene líneas de depreciación contabilizadas que el sistema protege.

This issue occurs because the asset has posted depreciation entries that the system protects.

### ⚠️ IMPORTANTE: Solo para Producción / IMPORTANT: Production Only

**ADVERTENCIA**: Estos comandos son para casos excepcionales en producción cuando un registro se creó por error.

**WARNING**: These commands are for exceptional cases in production when a record was created by mistake.

**Requisitos previos / Prerequisites**:
1. Verificar que es un error real de creación
2. Tener respaldo de base de datos reciente
3. Ejecutar en horarios de bajo tráfico
4. Documentar el caso para auditoría

### Plan de Eliminación Segura (Paso a Paso) / Safe Deletion Plan (Step by Step)

#### Paso 1: Verificación del Activo / Step 1: Asset Verification

**Query 1.1: Verificar datos básicos del activo**

```sql
-- Para Query Deluxe en Odoo / For Query Deluxe in Odoo
-- Esta query es SEGURA (solo lectura, pocos datos)

SELECT
    id,
    name,
    code,
    state,
    date_start,
    purchase_value,
    salvage_value,
    company_id,
    profile_id
FROM account_asset
WHERE id = 1159;  -- Cambiar por el ID real / Change to actual ID
```

**Salida esperada / Expected output:**
- Verificar que el `id` sea correcto
- Anotar el `state` actual (draft/open/close/removed)
- Confirmar que es el activo correcto por `name` y `code`
- Ver `purchase_value` (valor de compra) y `salvage_value` (valor residual)

**Query 1.2: Contar líneas de amortización**

```sql
-- Para Query Deluxe en Odoo / For Query Deluxe in Odoo
-- Esta query es SEGURA (solo cuenta registros)

SELECT
    COUNT(*) as total_lineas,
    SUM(CASE WHEN type = 'depreciate' AND move_check = true THEN 1 ELSE 0 END) as lineas_asentadas,
    SUM(CASE WHEN type = 'depreciate' AND move_check = false THEN 1 ELSE 0 END) as lineas_borrador
FROM account_asset_line
WHERE asset_id = 1159;  -- Cambiar por el ID real / Change to actual ID
```

**Salida esperada / Expected output:**
- `total_lineas`: Total de líneas de depreciación
- `lineas_asentadas`: Líneas contabilizadas (el problema)
- `lineas_borrador`: Líneas en borrador

#### Paso 2: Verificar Dependencias Críticas / Step 2: Verify Critical Dependencies

**Query 2.1: Verificar asientos contables relacionados**

```sql
-- Para Query Deluxe en Odoo / For Query Deluxe in Odoo
-- Esta query es SEGURA (solo lectura)

SELECT
    aal.id as linea_id,
    aal.type as tipo_linea,
    aal.move_check as asentada,
    aal.name as descripcion,
    am.id as asiento_id,
    am.name as numero_asiento,
    am.state as estado_asiento,
    am.date as fecha_asiento
FROM account_asset_line aal
LEFT JOIN account_move am ON aal.move_id = am.id
WHERE aal.asset_id = 1159  -- Cambiar por el ID real / Change to actual ID
ORDER BY aal.id;
```

**Revisar / Review:**
- Si hay `asiento_id` NO nulos, hay movimientos contables vinculados
- Anotar los IDs de asientos para verificación posterior

**Query 2.2: Verificar otras relaciones**

```sql
-- Para Query Deluxe en Odoo / For Query Deluxe in Odoo
-- Esta query es SEGURA (verifica múltiples tablas)

SELECT 'account_asset_line' as tabla, COUNT(*) as registros
FROM account_asset_line WHERE asset_id = 1159
UNION ALL
SELECT 'physical_verification_asset', COUNT(*)
FROM physical_verification_asset WHERE asset_id = 1159
UNION ALL
SELECT 'account_asset_group_rel', COUNT(*)
FROM account_asset_group_rel WHERE account_asset_id = 1159;
```

**Anotar / Note:**
- Número de registros en cada tabla relacionada
- Estas tablas también deberán limpiarse

#### Paso 3: Plan de Eliminación (CON TRANSACCIÓN) / Step 3: Deletion Plan (WITH TRANSACTION)

**⚠️ CRÍTICO: NO ejecutar directamente en Query Deluxe**

Estos comandos deben ejecutarse desde `docker exec` con control de transacciones para poder hacer rollback si algo falla.

**Script completo de eliminación:**

```sql
-- EJECUTAR DESDE DOCKER EXEC (NO desde Query Deluxe)
-- RUN FROM DOCKER EXEC (NOT from Query Deluxe)

BEGIN;  -- Iniciar transacción / Start transaction

-- Paso 1: Eliminar líneas de amortización
DELETE FROM account_asset_line
WHERE asset_id = 1159;  -- Cambiar ID / Change ID

-- Verificar eliminación
SELECT COUNT(*) as lineas_restantes FROM account_asset_line WHERE asset_id = 1159;
-- Debe retornar 0 / Should return 0

-- Paso 2: Eliminar relaciones con grupos
DELETE FROM account_asset_group_rel
WHERE account_asset_id = 1159;  -- Cambiar ID / Change ID

-- Paso 3: Eliminar verificaciones físicas (si existen)
DELETE FROM physical_verification_asset
WHERE asset_id = 1159;  -- Cambiar ID / Change ID

-- Paso 4: Finalmente, eliminar el activo
DELETE FROM account_asset
WHERE id = 1159;  -- Cambiar ID / Change ID

-- Verificar eliminación del activo
SELECT COUNT(*) as activo_existe FROM account_asset WHERE id = 1159;
-- Debe retornar 0 / Should return 0

-- SI TODO ESTÁ BIEN: / IF EVERYTHING IS OK:
COMMIT;

-- SI HAY ALGÚN PROBLEMA: / IF THERE'S ANY PROBLEM:
-- ROLLBACK;
```

#### Paso 4: Ejecución Segura en Producción / Step 4: Safe Production Execution

**Comando completo con Docker:**

```bash
# 1. Crear un respaldo rápido ANTES de ejecutar (MUY IMPORTANTE)
docker exec odoo-db pg_dump -U odoo -d NOMBRE_BD_PRODUCCION -t account_asset -t account_asset_line > /backups/asset_backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Ejecutar el script de eliminación
docker exec -i odoo-db psql -U odoo -d NOMBRE_BD_PRODUCCION << 'EOF'
BEGIN;

-- Guardar info del activo antes de eliminar (para auditoría)
CREATE TEMP TABLE activo_eliminado AS
SELECT * FROM account_asset WHERE id = 1159;

-- Eliminar líneas de amortización
DELETE FROM account_asset_line WHERE asset_id = 1159;

-- Eliminar relaciones
DELETE FROM account_asset_group_rel WHERE account_asset_id = 1159;
DELETE FROM physical_verification_asset WHERE asset_id = 1159;

-- Eliminar el activo
DELETE FROM account_asset WHERE id = 1159;

-- Mostrar resumen
SELECT
    'Activo eliminado' as accion,
    id,
    name,
    code,
    state
FROM activo_eliminado;

-- Confirmar cambios
COMMIT;
EOF

# 3. Verificar que se eliminó
docker exec odoo-db psql -U odoo -d NOMBRE_BD_PRODUCCION -c "SELECT COUNT(*) FROM account_asset WHERE id = 1159;"
# Debe retornar 0
```

### Alternativa: Usar Query Deluxe para Verificación + Docker para Eliminación

**Paso A: En Query Deluxe (SOLO VERIFICACIÓN)**

```sql
-- Query segura para verificar TODO antes de eliminar
SELECT
    'ACTIVO' as tipo,
    id::text as id_registro,
    name as descripcion,
    state as estado
FROM account_asset WHERE id = 1159
UNION ALL
SELECT
    'LINEA_AMORTIZACION',
    id::text,
    name,
    CASE WHEN move_check THEN 'ASENTADA' ELSE 'BORRADOR' END
FROM account_asset_line WHERE asset_id = 1159
UNION ALL
SELECT
    'VERIFICACION_FISICA',
    id::text,
    verification_name,
    state
FROM physical_verification_asset WHERE asset_id = 1159;
```

**Paso B: En Docker (ELIMINACIÓN REAL)**

```bash
# Solo si la verificación anterior dio OK
docker exec -i odoo-db psql -U odoo -d NOMBRE_BD_PRODUCCION << 'EOF'
BEGIN;
DELETE FROM account_asset_line WHERE asset_id = 1159;
DELETE FROM account_asset_group_rel WHERE account_asset_id = 1159;
DELETE FROM physical_verification_asset WHERE asset_id = 1159;
DELETE FROM account_asset WHERE id = 1159;
COMMIT;
EOF
```

### Checklist Final / Final Checklist

Antes de ejecutar en producción, verificar:

Before running in production, verify:

- [ ] Respaldo de base de datos creado
- [ ] Horario de bajo tráfico confirmado
- [ ] ID del activo verificado (1159 en este caso)
- [ ] Queries de verificación ejecutadas en Query Deluxe
- [ ] Resultados de verificación documentados
- [ ] Usuario con permisos de PostgreSQL disponible
- [ ] Plan de rollback preparado
- [ ] Stakeholders notificados del mantenimiento

### Recuperación en Caso de Error / Recovery in Case of Error

Si algo sale mal ANTES de hacer COMMIT:

If something goes wrong BEFORE doing COMMIT:

```sql
ROLLBACK;  -- Cancela todos los cambios / Cancels all changes
```

Si ya hiciste COMMIT y necesitas recuperar:

If you already did COMMIT and need to recover:

```bash
# Restaurar desde el respaldo creado
docker exec -i odoo-db psql -U odoo -d NOMBRE_BD_PRODUCCION < /backups/asset_backup_FECHA.sql
```

### Notas Importantes / Important Notes

1. **Query Deluxe**: Usar SOLO para verificación (SELECT), NUNCA para DELETE en producción
2. **Docker exec**: Usar para comandos DELETE con control de transacciones
3. **Timing**: Ejecutar en horarios de bajo uso (madrugada, fin de semana)
4. **Documentación**: Registrar en ticket/caso el ID eliminado y razón
5. **Testing**: Si es posible, probar primero en ambiente de staging/QA