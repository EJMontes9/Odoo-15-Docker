# Contratos - Cambios 2026-02-18

Registro de cambios realizados el 18 de febrero de 2026 en el modulo **contratos**.

## 1. Fix: Wizard de migracion no completaba documentos faltantes en migraciones incompletas

**Tipo:** Correccion de error

**Problema que resuelve:**
Cuando un proceso de `hiring_process` tenia una migracion incompleta (por ejemplo: 62/110 documentos migrados), el wizard solo intentaba completar la actividad faltante (Objeto de Contratacion) pero no migraba los documentos pendientes. El proceso quedaba marcado como "Migracion aun incompleta" sin posibilidad de completarse automaticamente.

**Que se hizo:**
Se agrego el metodo `_complete_missing_documents()` que implementa la siguiente logica:

1. Identifica los attachments ya migrados buscando por `Attachment ID:` o `Original ID:` en la descripcion del `contract.document`
2. Itera sobre los 3 tipos de documentos del hiring_process (preparatoria, precontractual, contractual)
3. Migra solo los attachments que no estan en el set de ya migrados
4. Soporta tanto el modo optimizado (referencia) como el legado (copia completa)
5. Reporta el progreso en el log detallado

Se modifico el bloque de migraciones incompletas en `action_migrate()` para llamar a `_complete_missing_documents()` antes de re-verificar completitud.

**Archivos modificados:**

- `contratos/wizards/migration_hiring_process_wizard.py`
  - Nuevo metodo: `_complete_missing_documents()`
  - Modificado: bloque de migraciones incompletas en `action_migrate()`

---

## 2. Fix: Error SQL por nombres de columna case-sensitive en PostgreSQL

**Tipo:** Correccion de error

**Problema que resuelve:**
Al migrar procesos usando el modo "Optimizado (Referencia)", el wizard fallaba con el error:

```text
column "id_proceso_pre" does not exist
HINT: Perhaps you meant to reference the column "ir_attachment.id_Proceso_pre".
```

**Causa raiz:**
Las columnas de la tabla `ir_attachment` fueron creadas con mayusculas mixtas por Odoo: `id_Proceso_pre`, `id_Proceso_precon`, `id_Proceso_con`. PostgreSQL es case-sensitive cuando las columnas se crean con mayusculas. El SQL directo las referenciaba sin comillas como `id_proceso_pre` (todo minusculas), lo que PostgreSQL no podia resolver.

Este error solo afectaba al modo **optimizado** porque es el unico que usa SQL directo para contar documentos. El modo **legado** usa el ORM de Odoo que maneja los nombres de columna internamente.

**Que se hizo:**
Se agregaron comillas dobles a los nombres de columna en la query SQL para forzar el case correcto:

```sql
-- Antes (incorrecto):
SELECT COUNT(*) FROM ir_attachment WHERE id_proceso_pre = %s

-- Despues (correcto):
SELECT COUNT(*) FROM ir_attachment WHERE "id_Proceso_pre" = %s
```

Columnas corregidas:

- `id_proceso_pre` -> `"id_Proceso_pre"`
- `id_proceso_precon` -> `"id_Proceso_precon"`
- `id_proceso_con` -> `"id_Proceso_con"`

**Archivos modificados:**

- `contratos/wizards/migration_hiring_process_wizard.py` - Metodo `_migrate_documents_optimized()`, query SQL de conteo de documentos originales

---

## 3. Fix: Documentos migrados con modo optimizado no se visualizaban

**Tipo:** Correccion de error

**Problema que resuelve:**
Los documentos migrados con el modo "Optimizado (Referencia)" aparecian en la lista de documentos del contrato pero al abrirlos el campo "Archivo" estaba vacio. No se podia visualizar ni descargar el PDF. Los documentos migrados con el modo legado si funcionaban correctamente.

**Causa raiz:**
El metodo `_migrate_document_by_reference_copy()` creaba el `ir.attachment` usando el ORM de Odoo (`self.env['ir.attachment'].create()`). Sin embargo, en Odoo 15 el ORM de `ir.attachment` tiene logica interna que sobrescribe o ignora el campo `store_fname` cuando se crea un attachment via ORM, ya que espera recibir `datas` (contenido binario en base64). Como la migracion optimizada no pasa `datas` (para no cargar el archivo en memoria), el attachment se creaba sin vinculo real al archivo fisico en el filestore.

**Que se hizo:**
Se reemplazo la creacion del attachment via ORM por una insercion SQL directa:

```sql
INSERT INTO ir_attachment
    (name, mimetype, store_fname, file_size, checksum,
     description, res_model, res_id, res_field, type, ...)
VALUES (...)
```

Esto permite insertar el `store_fname` exactamente como se necesita, sin que el ORM interfiera. No se duplica el archivo fisico ni se carga en memoria. Solo se crea un registro de metadata (~500 bytes) que apunta al mismo archivo en el filestore.

**Archivos modificados:**

- `contratos/wizards/migration_hiring_process_wizard.py` - Metodo `_migrate_document_by_reference_copy()`, reemplazo de ORM create por SQL INSERT

**Reparacion de documentos ya migrados:**

Ver seccion 4 de este documento para el procedimiento completo de reparacion ejecutado en produccion.

---

## 4. Reparacion en produccion: attachments vacios por migracion optimizada

**Tipo:** Procedimiento de reparacion en produccion

**Problema que resuelve:**
Los contratos migrados con el modo "Optimizado (Referencia)" antes del fix #3 tenian sus `ir.attachment` con `store_fname` vacio. Los documentos aparecian en la lista pero no se podian visualizar ni descargar. Se necesitaba copiar el `store_fname` del attachment original del `hiring.process` al attachment del `contract.document`.

**Principio de seguridad:**
- NO se elimina ni modifica ninguna documentacion original de `hiring.process`
- Solo se ACTUALIZA el campo `store_fname` (y metadata asociada) en los attachments del contrato
- Los attachments originales quedan intactos

### Paso 1: Diagnostico - Conteo por contrato

Query para identificar cuantos documentos migrados tienen attachment vacio vs OK por contrato:

```sql
SELECT
    cm.name as contrato,
    COUNT(cd.id) as total_docs,
    COUNT(CASE WHEN ia.store_fname IS NOT NULL
        AND ia.store_fname != '' THEN 1 END) as docs_ok,
    COUNT(CASE WHEN ia.id IS NOT NULL
        AND (ia.store_fname IS NULL OR ia.store_fname = '') THEN 1 END) as docs_sin_archivo,
    COUNT(CASE WHEN ia.id IS NULL THEN 1 END) as docs_sin_attachment
FROM contract_document cd
JOIN contract_management cm ON cd.contract_id = cm.id
LEFT JOIN ir_attachment ia
    ON ia.res_model = 'contract.document'
    AND ia.res_id = cd.id
    AND ia.res_field = 'file'
WHERE cm.migrated = true
GROUP BY cm.name
ORDER BY cm.name;
```

**Resultado:** 15 contratos afectados con un total de **2,095 documentos sin archivo visible**. Ningun caso de documento sin attachment (todos tenian `ir.attachment` creado, pero con `store_fname` vacio).

| Contrato | Total docs | OK | Sin archivo |
|----------|-----------|-----|-------------|
| CDC-AAG-2023-030 | 92 | 44 | 48 |
| COTS-AAG-2023-001 | 88 | 0 | 88 |
| IC-AAG-2024-017 | 21 | 0 | 21 |
| IC-AAG-2024-018 | 16 | 0 | 16 |
| IC-AAG-2024-020 | 23 | 1 | 22 |
| LCC-AAG-2022-010 | 123 | 0 | 123 |
| LCC-AAG-2023-003 | 132 | 0 | 132 |
| LCC-AAG-2024-002 | 103 | 0 | 103 |
| LCC-AAG-2024-003 | 92 | 80 | 12 |
| LICO-AAG-2022-005 | 189 | 0 | 189 |
| LICO-AAG-2022-006 | 194 | 0 | 194 |
| LICO-AAG-2023-004 | 104 | 0 | 104 |
| LICO-AAG-2023-005 | 991 | 0 | 991 |
| LICO-AAG-2024-001 | 5 | 1 | 4 |
| LICSG-AAG-2024-001 | 110 | 62 | 48 |

### Paso 2: Verificar referencias al attachment original

Confirmar que todos los attachments vacios contienen la referencia `Original ID:` en su campo `description`, necesaria para localizar el attachment original:

```sql
SELECT
    cm.name as contrato,
    COUNT(*) as sin_archivo,
    COUNT(CASE WHEN ia.description LIKE '%Original ID:%' THEN 1
        END) as con_referencia_original,
    COUNT(CASE WHEN ia.description NOT LIKE '%Original ID:%'
        OR ia.description IS NULL THEN 1 END) as sin_referencia
FROM contract_document cd
JOIN contract_management cm ON cd.contract_id = cm.id
JOIN ir_attachment ia
    ON ia.res_model = 'contract.document'
    AND ia.res_id = cd.id
    AND ia.res_field = 'file'
WHERE cm.migrated = true
    AND (ia.store_fname IS NULL OR ia.store_fname = '')
GROUP BY cm.name
ORDER BY cm.name;
```

**Resultado:** 2,095 de 2,095 tienen referencia `Original ID:`. Cero sin referencia.

### Paso 3: Verificar que los attachments originales existen

Confirmar que los attachments originales del `hiring.process` existen y tienen `store_fname` valido:

```sql
SELECT
    cm.name as contrato,
    COUNT(*) as total_a_reparar,
    COUNT(CASE WHEN ia_orig.id IS NOT NULL
        AND ia_orig.store_fname IS NOT NULL
        AND ia_orig.store_fname != '' THEN 1 END) as originales_ok,
    COUNT(CASE WHEN ia_orig.id IS NULL THEN 1 END) as original_no_existe,
    COUNT(CASE WHEN ia_orig.id IS NOT NULL
        AND (ia_orig.store_fname IS NULL
        OR ia_orig.store_fname = '') THEN 1 END) as original_sin_archivo
FROM contract_document cd
JOIN contract_management cm ON cd.contract_id = cm.id
JOIN ir_attachment ia_new
    ON ia_new.res_model = 'contract.document'
    AND ia_new.res_id = cd.id
    AND ia_new.res_field = 'file'
LEFT JOIN ir_attachment ia_orig
    ON ia_orig.id = CAST(
        TRIM(SUBSTRING(ia_new.description FROM 'Original ID: ([0-9]+)'))
        AS INTEGER
    )
WHERE cm.migrated = true
    AND (ia_new.store_fname IS NULL OR ia_new.store_fname = '')
GROUP BY cm.name
ORDER BY cm.name;
```

**Resultado:** 2,095 de 2,095 originales existen y tienen archivo. Cero faltantes.

### Paso 4: Vista previa de un contrato de prueba

Antes de ejecutar la reparacion masiva, se verifico con un contrato pequeno (LICO-AAG-2024-001, 4 documentos) que los datos a copiar fueran correctos:

```sql
SELECT
    ia_new.id as att_id_contrato,
    ia_new.name,
    ia_new.store_fname as store_fname_actual,
    ia_orig.id as att_id_original,
    ia_orig.store_fname as store_fname_correcto,
    ia_orig.file_size,
    ia_orig.mimetype
FROM contract_document cd
JOIN contract_management cm ON cd.contract_id = cm.id
JOIN ir_attachment ia_new
    ON ia_new.res_model = 'contract.document'
    AND ia_new.res_id = cd.id
    AND ia_new.res_field = 'file'
JOIN ir_attachment ia_orig
    ON ia_orig.id = CAST(
        TRIM(SUBSTRING(ia_new.description FROM 'Original ID: ([0-9]+)'))
        AS INTEGER
    )
WHERE cm.name = 'LICO-AAG-2024-001'
    AND (ia_new.store_fname IS NULL OR ia_new.store_fname = '')
ORDER BY ia_new.id;
```

**Resultado:** Se confirmo que `store_fname_actual` estaba vacio y `store_fname_correcto` contenia la ruta valida al archivo en el filestore.

### Paso 5: Reparacion del contrato de prueba

Se ejecuto el UPDATE solo para LICO-AAG-2024-001 (4 documentos) como prueba controlada:

```sql
UPDATE ir_attachment ia_new
SET
    store_fname = ia_orig.store_fname,
    file_size = ia_orig.file_size,
    checksum = ia_orig.checksum,
    mimetype = ia_orig.mimetype
FROM ir_attachment ia_orig
WHERE ia_new.id IN (
    SELECT ia_n.id
    FROM contract_document cd
    JOIN contract_management cm ON cd.contract_id = cm.id
    JOIN ir_attachment ia_n
        ON ia_n.res_model = 'contract.document'
        AND ia_n.res_id = cd.id
        AND ia_n.res_field = 'file'
    WHERE cm.name = 'LICO-AAG-2024-001'
        AND (ia_n.store_fname IS NULL OR ia_n.store_fname = '')
)
AND ia_orig.id = CAST(
    TRIM(SUBSTRING(ia_new.description FROM 'Original ID: ([0-9]+)'))
    AS INTEGER
);
```

**Resultado:** `UPDATE 4`. Se verifico en Odoo que los documentos de LICO-AAG-2024-001 ahora se visualizaban correctamente.

### Paso 6: Reparacion masiva de todos los contratos

Con la prueba exitosa, se ejecuto el mismo UPDATE para todos los contratos afectados:

```sql
UPDATE ir_attachment ia_new
SET
    store_fname = ia_orig.store_fname,
    file_size = ia_orig.file_size,
    checksum = ia_orig.checksum,
    mimetype = ia_orig.mimetype
FROM ir_attachment ia_orig
WHERE ia_new.id IN (
    SELECT ia_n.id
    FROM contract_document cd
    JOIN contract_management cm ON cd.contract_id = cm.id
    JOIN ir_attachment ia_n
        ON ia_n.res_model = 'contract.document'
        AND ia_n.res_id = cd.id
        AND ia_n.res_field = 'file'
    WHERE cm.migrated = true
        AND (ia_n.store_fname IS NULL OR ia_n.store_fname = '')
)
AND ia_orig.id = CAST(
    TRIM(SUBSTRING(ia_new.description FROM 'Original ID: ([0-9]+)'))
    AS INTEGER
);
```

**Resultado esperado:** `UPDATE 2091` (2,095 totales menos 4 ya reparados en la prueba).

### Resumen de la reparacion

- **Contratos afectados:** 15
- **Documentos reparados:** 2,095
- **Campos actualizados por documento:** `store_fname`, `file_size`, `checksum`, `mimetype`
- **Datos originales del hiring_process:** No modificados
- **Archivos fisicos en filestore:** No duplicados ni movidos, solo se apunto al mismo `store_fname`
- **Herramienta utilizada:** Query Deluxe en Odoo de produccion
