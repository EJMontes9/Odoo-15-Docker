# Gestión de Base de Datos

## Descripción

Este documento explica las opciones disponibles para configurar y gestionar la base de datos PostgreSQL para Odoo.

## Métodos de Configuración

### 1. Configuración desde el Contenedor PostgreSQL (Recomendado)

Este método configura la base de datos directamente desde el contenedor PostgreSQL, ofreciendo mayor simplicidad, rendimiento y seguridad.

#### Pasos:

1. Coloca tu archivo `.dump` en la carpeta `./backups/db` de tu máquina anfitriona

2. Inicia los contenedores con `docker-compose up -d`

3. Ejecuta el script de configuración:

   **Para Linux/Mac:**
   ```bash
   ./scripts/shell/setup_db_from_host.sh
   ```

   **Para Windows (PowerShell):**
   ```powershell
   .\scripts\shell\setup_db_from_host.ps1
   ```

#### Ventajas:

- **Simplicidad**: Todas las operaciones de base de datos se realizan directamente en el contenedor PostgreSQL.

- **Rendimiento**: La restauración de la base de datos es más rápida cuando se realiza directamente en el contenedor PostgreSQL.

- **Seguridad**: No es necesario exponer credenciales de base de datos en el contenedor Odoo.

### 2. Método Anterior: Automatización desde el Contenedor Odoo

> **Nota**: Este método ya no se utiliza por defecto, pero se mantiene la documentación por compatibilidad.

El sistema incluía un script de automatización que:

1. Verifica si la base de datos `odoo` existe

2. Si no existe, la crea automáticamente

3. Busca el archivo `.dump` más reciente en la carpeta `./backups/db`

4. Restaura ese archivo en la base de datos `odoo`

Este proceso se ejecutaba automáticamente al iniciar el contenedor de Odoo.

### 3. Creación y Restauración Manual

Si prefieres realizar el proceso manualmente, puedes seguir estos pasos:

#### Crear la base de datos `odoo` manualmente:

1. Accede al contenedor de la base de datos:
   ```bash
   docker exec -it odoo-db bash
   ```

2. Ingresa al cliente PostgreSQL:
   ```bash
   psql -U odoo -d postgres
   ```

3. Crea la base de datos `odoo` y asígnala al usuario `odoo`:
   ```sql
   CREATE DATABASE odoo OWNER odoo;
   ```

4. Verifica que la base de datos fue creada correctamente:
   ```sql
   \l
   ```

5. Sal del cliente PostgreSQL:
   ```sql
   \q
   ```

#### Restaurar la base de datos `odoo` manualmente desde un archivo `.dump`:

1. Coloca el archivo `.dump` en la carpeta `./backups/db` en tu máquina anfitriona

2. Accede al contenedor del servicio PostgreSQL:
   ```bash
   docker exec -it odoo-db bash
   ```

3. Dentro del contenedor, restaura el `.dump` en la base de datos `odoo`:
   ```bash
   pg_restore -U odoo -d odoo /backups/archivo.dump
   ```

4. Verifica que las tablas se restauraron correctamente:
   ```bash
   psql -U odoo -d odoo -c "\dt"
   ```

## Solución de Problemas

### Error de PostgreSQL Client

Si encuentras un error como:

```
/opt/scripts/shell/setup_odoo_db.sh: line 12: psql: command not found
```

Este error ocurre porque el contenedor de Odoo no tiene instaladas las herramientas cliente de PostgreSQL, necesarias para ejecutar los comandos `psql` y `pg_restore`.

#### Solución para PostgreSQL Client

Se ha modificado el Dockerfile para incluir el paquete `postgresql-client`, que proporciona las herramientas necesarias.

Para aplicar esta solución, es necesario reconstruir la imagen Docker:

```bash
docker-compose down
docker-compose build
docker-compose up -d
```

### Problemas con el Método de Configuración desde PostgreSQL

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

6. **Eliminar una base de datos**:
   ```bash
   docker exec odoo-db psql -U odoo -d postgres -c "DROP DATABASE IF EXISTS odoo;"
   ```

## Regeneración de Assets de Odoo

### Problema: Pantalla blanca y errores 404 en assets

Si al intentar acceder a Odoo ves una pantalla blanca y en los logs encuentras errores como:

```
GET /web/assets/54466-f970e4c/web.assets_common.min.css HTTP/1.1" 404
GET /web/assets/54467-0775dd5/web.assets_backend.min.css HTTP/1.1" 404
GET /web/assets/54468-f970e4c/web.assets_common.min.js HTTP/1.1" 404
```

Esto indica que los assets están corruptos o no se han generado correctamente.

### Solución paso a paso

#### 1. Detener el contenedor de Odoo

Primero, detén el contenedor de Odoo para liberar las conexiones a la base de datos:

```bash
docker stop odoo-app
```

#### 2. Listar las bases de datos existentes

Verifica qué bases de datos existen en PostgreSQL:

```bash
docker exec odoo-db psql -U odoo -d postgres -c "\l"
```

**Salida esperada:**
```
     Name     | Owner | Encoding |  Collate   |   Ctype
--------------+-------+----------+------------+------------
 odoo         | odoo  | UTF8     | en_US.utf8 | en_US.utf8
 odoo20250913 | odoo  | UTF8     | en_US.utf8 | en_US.utf8
 postgres     | odoo  | UTF8     | en_US.utf8 | en_US.utf8
```

#### 3. Limpiar assets corruptos de TODAS las bases de datos

**IMPORTANTE**: Debes limpiar los assets de CADA base de datos de Odoo que tengas, no solo de la base `postgres`.

Para cada base de datos de Odoo que veas en el listado (ejemplo: `odoo`, `odoo20250913`), ejecuta:

```bash
# Para la base de datos 'odoo'
docker exec odoo-db psql -U odoo -d odoo -c "DELETE FROM ir_attachment WHERE name LIKE 'web.assets_%' OR url LIKE '/web/assets/%';"

# Para otras bases de datos (ajusta el nombre)
docker exec odoo-db psql -U odoo -d odoo20250913 -c "DELETE FROM ir_attachment WHERE name LIKE 'web.assets_%' OR url LIKE '/web/assets/%';"
```

**Salida esperada:**
```
DELETE 52  # Número de registros eliminados
```

#### 4. Verificar archivos de assets en filestore (opcional)

Si los archivos físicos están corruptos, puedes verificar el directorio de filestore:

```bash
# Ver estructura del filestore
docker exec odoo-app ls -la /var/lib/odoo/filestore/
```

#### 5. Reiniciar Odoo para regenerar assets

Inicia el contenedor de Odoo nuevamente. Los assets se regenerarán automáticamente:

```bash
docker start odoo-app
```

#### 6. Monitorear logs durante la regeneración

Observa los logs para asegurarte de que no haya errores durante la regeneración de assets:

```bash
docker logs -f odoo-app --tail 50
```

**Buscar estos mensajes:**
- `Modules loaded` - Indica que los módulos cargaron correctamente
- `Generating routing map` - Odoo está generando rutas
- Sin errores de variables SCSS faltantes

#### 7. Verificar acceso a Odoo

Abre tu navegador y accede a: `http://localhost:8069`

La interfaz de Odoo debería cargar correctamente sin errores 404.

### Problema adicional: Variables SCSS faltantes

Si después de limpiar los assets sigues viendo errores como:

```
Error: Undefined variable: "$mk-appbar-background"
```

Esto indica que falta una variable SCSS en tu tema personalizado.

#### Solución para Variables SCSS

1. Identifica el archivo de variables del tema:
   ```bash
   # Ejemplo para aeroportuaria_theme
   addons/Aeroportuaria_ERP/themes/aeroportuaria_theme/static/src/variables.scss
   ```

2. Busca dónde se usa la variable faltante:
   ```bash
   docker exec odoo-app grep -r "\$mk-appbar-background" /mnt/extra-addons/
   ```

3. Agrega la variable faltante al archivo `variables.scss`:
   ```scss
   //----------------------------------------------------------
   // AppBar Colors
   //----------------------------------------------------------

   $mk-appbar-color: #dee2e6;
   $mk-appbar-background: #000000;
   ```

4. Reinicia Odoo para aplicar los cambios:
   ```bash
   docker restart odoo-app
   ```

### Comandos rápidos de referencia

```bash
# Ver todas las bases de datos
docker exec odoo-db psql -U odoo -d postgres -c "\l"

# Limpiar assets de una base específica
docker exec odoo-db psql -U odoo -d NOMBRE_BD -c "DELETE FROM ir_attachment WHERE name LIKE 'web.assets_%' OR url LIKE '/web/assets/%';"

# Detener/Iniciar Odoo
docker stop odoo-app
docker start odoo-app

# Ver logs en tiempo real
docker logs -f odoo-app --tail 50

# Reiniciar completamente
docker restart odoo-app
```

## Eliminación Segura de Registros con Restricciones

### Problema: Eliminar activo fijo con líneas de amortización asentadas

Cuando intentas eliminar un activo fijo desde la interfaz de Odoo y obtienes estos errores:

1. **Error al eliminar directamente**: "Sólo puede eliminar activos en estado borrador"
2. **Error al poner en borrador**: "No puede eliminar un activo que contenga líneas de amortización asentadas"

Este problema ocurre porque el activo tiene líneas de depreciación contabilizadas que el sistema protege.

### IMPORTANTE: Solo para Producción

**ADVERTENCIA**: Estos comandos son para casos excepcionales en producción cuando un registro se creó por error.

**Requisitos previos**:
1. Verificar que es un error real de creación
2. Tener respaldo de base de datos reciente
3. Ejecutar en horarios de bajo tráfico
4. Documentar el caso para auditoría

### Plan de Eliminación Segura (Paso a Paso)

#### Paso 1: Verificación del Activo

**Query 1.1: Verificar datos básicos del activo**

```sql
-- Para Query Deluxe en Odoo
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
WHERE id = 1159;  -- Cambiar por el ID real
```

**Salida esperada:**
- Verificar que el `id` sea correcto
- Anotar el `state` actual (draft/open/close/removed)
- Confirmar que es el activo correcto por `name` y `code`
- Ver `purchase_value` (valor de compra) y `salvage_value` (valor residual)

**Query 1.2: Contar líneas de amortización**

```sql
-- Para Query Deluxe en Odoo
-- Esta query es SEGURA (solo cuenta registros)

SELECT
    COUNT(*) as total_lineas,
    SUM(CASE WHEN type = 'depreciate' AND move_check = true THEN 1 ELSE 0 END) as lineas_asentadas,
    SUM(CASE WHEN type = 'depreciate' AND move_check = false THEN 1 ELSE 0 END) as lineas_borrador
FROM account_asset_line
WHERE asset_id = 1159;  -- Cambiar por el ID real
```

**Salida esperada:**
- `total_lineas`: Total de líneas de depreciación
- `lineas_asentadas`: Líneas contabilizadas (el problema)
- `lineas_borrador`: Líneas en borrador

#### Paso 2: Verificar Dependencias Críticas

**Query 2.1: Verificar asientos contables relacionados**

```sql
-- Para Query Deluxe en Odoo
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
WHERE aal.asset_id = 1159  -- Cambiar por el ID real
ORDER BY aal.id;
```

**Revisar:**
- Si hay `asiento_id` NO nulos, hay movimientos contables vinculados
- Anotar los IDs de asientos para verificación posterior

**Query 2.2: Verificar otras relaciones**

```sql
-- Para Query Deluxe en Odoo
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

**Anotar:**
- Número de registros en cada tabla relacionada
- Estas tablas también deberán limpiarse

#### Paso 3: Plan de Eliminación (CON TRANSACCIÓN)

**CRÍTICO: NO ejecutar directamente en Query Deluxe**

Estos comandos deben ejecutarse desde `docker exec` con control de transacciones para poder hacer rollback si algo falla.

**Script completo de eliminación:**

```sql
-- EJECUTAR DESDE DOCKER EXEC (NO desde Query Deluxe)

BEGIN;  -- Iniciar transacción

-- Paso 1: Eliminar líneas de amortización
DELETE FROM account_asset_line
WHERE asset_id = 1159;  -- Cambiar ID

-- Verificar eliminación
SELECT COUNT(*) as lineas_restantes FROM account_asset_line WHERE asset_id = 1159;
-- Debe retornar 0

-- Paso 2: Eliminar relaciones con grupos
DELETE FROM account_asset_group_rel
WHERE account_asset_id = 1159;  -- Cambiar ID

-- Paso 3: Eliminar verificaciones físicas (si existen)
DELETE FROM physical_verification_asset
WHERE asset_id = 1159;  -- Cambiar ID

-- Paso 4: Finalmente, eliminar el activo
DELETE FROM account_asset
WHERE id = 1159;  -- Cambiar ID

-- Verificar eliminación del activo
SELECT COUNT(*) as activo_existe FROM account_asset WHERE id = 1159;
-- Debe retornar 0

-- SI TODO ESTÁ BIEN:
COMMIT;

-- SI HAY ALGÚN PROBLEMA:
-- ROLLBACK;
```

#### Paso 4: Ejecución Segura en Producción

**Comando completo con Docker:**

```bash
# 1. Crear un respaldo rápido ANTES de ejecutar (MUY IMPORTANTE)
docker exec odoo-db pg_dump -U odoo -d NOMBRE_BD_PRODUCCION -t account_asset -t account_asset_line > /backups/asset_backup_$(date +YYYYMMDD_HHMMSS).sql

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

### Checklist Final

Antes de ejecutar en producción, verificar:

- [ ] Respaldo de base de datos creado
- [ ] Horario de bajo tráfico confirmado
- [ ] ID del activo verificado (1159 en este caso)
- [ ] Queries de verificación ejecutadas en Query Deluxe
- [ ] Resultados de verificación documentados
- [ ] Usuario con permisos de PostgreSQL disponible
- [ ] Plan de rollback preparado
- [ ] Stakeholders notificados del mantenimiento

### Recuperación en Caso de Error

Si algo sale mal ANTES de hacer COMMIT:

```sql
ROLLBACK;  -- Cancela todos los cambios
```

Si ya hiciste COMMIT y necesitas recuperar:

```bash
# Restaurar desde el respaldo creado
docker exec -i odoo-db psql -U odoo -d NOMBRE_BD_PRODUCCION < /backups/asset_backup_FECHA.sql
```

### Notas Importantes

1. **Query Deluxe**: Usar SOLO para verificación (SELECT), NUNCA para DELETE en producción
2. **Docker exec**: Usar para comandos DELETE con control de transacciones
3. **Timing**: Ejecutar en horarios de bajo uso (madrugada, fin de semana)
4. **Documentación**: Registrar en ticket/caso el ID eliminado y razón
5. **Testing**: Si es posible, probar primero en ambiente de staging/QA
