# Contratos - Cambios 2026-02-13

Registro de cambios realizados el 13 de febrero de 2026 en el modulo **contratos**.

## 1. Fix: Wizard de migracion no completaba actividades en procesos ya migrados

**Tipo:** Correccion de error

**Problema que resuelve:**
El wizard de migracion marcaba procesos como "ya migrados" y los omitia sin verificar si la migracion estaba completa. Procesos como LCC-AAG-2023-004 quedaban sin la actividad "Objeto de contratacion".

**Que se hizo:**
Se modifico el bloque de verificacion de procesos ya migrados en `action_migrate()` para detectar migraciones incompletas (sin `contract_object`) e intentar completarlas automaticamente.

Se agrego distincion entre `migrated` y `migration_complete`:
- `migrated=True` indica que se creo el contrato
- `migration_complete=True` indica que todo (actividad + documentos) fue verificado

**Archivos modificados:**
- `contratos/wizards/migration_hiring_process_wizard.py`

---

## 2. Actividades de migracion con codigo historico 000

**Tipo:** Mejora

**Que se hizo:**
Todas las actividades de presupuesto creadas durante la migracion ahora reciben `short_code='000'` para identificarlas como registros historicos.

**Archivos modificados:**
- `contratos/wizards/migration_hiring_process_wizard.py` (metodo `_create_migration_activity`)

---

## 3. Validacion de completitud: documentos y actividad

**Tipo:** Mejora

**Que se hizo:**
Se implementaron dos mejoras de validacion:

1. **Conteo de documentos**: La migracion no se marca como completa si la cantidad de documentos en el contrato no coincide con la cantidad en el hiring process original.
2. **Filtro en seleccion manual**: Los procesos con `migration_complete=True` ya no aparecen en la lista de seleccion manual del wizard, evitando re-procesamiento innecesario.

**Cambios tecnicos:**
- `_compute_pending_info()` filtra por `migration_complete=True` en lugar de `migrated=True`
- Modo `next_batch` usa el mismo filtro
- Se agrego campo `pending_process_ids` a la vista para filtrar la seleccion manual con dominio `[('id', 'in', pending_process_ids)]`

**Archivos modificados:**
- `contratos/wizards/migration_hiring_process_wizard.py`
- `contratos/wizards/migration_hiring_process_wizard_views.xml`
