# Planificacion - Cambios 2026-02-11

Registro de cambios realizados el 11 de febrero de 2026 en el modulo **planification**.

## 1. Sistema de trazabilidad de techos presupuestarios

**Tipo:** Nueva funcionalidad

**Problema que resuelve:**
No existia forma de rastrear los movimientos que afectaban los techos presupuestarios por departamento. Cuando se realizaban transferencias entre departamentos, aplicaciones de techos temporales al principal, o generaciones desde la matriz POA, no quedaba registro historico del cambio.

**Que se hizo:**

Se creo el nuevo modelo `poa.department.budget.log` que registra todos los movimientos sobre los techos presupuestarios. Cada registro almacena:

- Departamento afectado y departamento contraparte (en transferencias)
- Tipo de accion: transferencia saliente/entrante, aplicacion temp a principal, reseteo, generacion desde POA, edicion manual
- Monto del movimiento
- Valores **antes** y **despues** tanto de `budget_amount` como de `temp_budget_amount`
- Referencia a la solicitud de reforma y matriz POA que origino el movimiento
- Usuario y fecha

Se integro el registro de logs en los metodos existentes:

- `transfer_temp_budget()` - Registra transferencia saliente y entrante
- `apply_temp_to_principal()` - Registra aplicacion de techo temporal al principal
- `reset_temp_budget()` - Registra reseteo de techo temporal
- `action_generate_department_budgets()` en `poa.matrix` - Registra generacion/actualizacion

Ademas se agrego:

- Vistas tree, form y search para el modelo de logs con decoraciones de color por tipo
- Smart button en el formulario de techo presupuestario para ver el historial
- Tab "Historial de Movimientos" en el formulario de techo
- Menu "Movimientos de Techos" en la seccion de presupuesto

**Archivos creados:**
- `planification/models/poa_department_budget_log.py`
- `planification/views/poa_department_budget_log_views.xml`

**Archivos modificados:**
- `planification/models/poa_department_budget.py` - Parametro `reform_request` en transfer/apply/reset, campo `log_ids`, `log_count`, `action_view_logs()`
- `planification/models/poa_matrix.py` - Logging en `action_generate_department_budgets()`
- `planification/wizard/poa_budget_transfer_wizard.py` - Pasa `reform_request` a `transfer_temp_budget()`
- `planification/models/poa_matrix_reform_request.py` - Pasa `reform_request=self` en `_apply_budget_transfers()`
- `planification/views/poa_department_budget_views.xml` - Smart button, tab historial, campo `temp_budget_amount`
- `planification/views/menu_actions.xml` - Menu "Movimientos de Techos"
- `planification/models/__init__.py` - Import del nuevo modelo
- `planification/__manifest__.py` - Registro de la nueva vista
- `planification/security/ir.model.access.csv` - Permisos: user (lectura), configurator (lectura+creacion), admin (completo)

**Nota tecnica:** Se uso `_rec_name = 'log_name'` con un campo custom `log_name` en lugar de `display_name` porque en Odoo 15 `display_name` es un campo reservado y causa conflictos.

---

## 2. Boton Revertir Ultimo Movimiento

**Tipo:** Nueva funcionalidad

**Problema que resuelve:**
Cuando se aplica una reforma con una transferencia incorrecta y se retrocede a borrador, los techos presupuestarios ya fueron modificados. No habia forma de deshacer el movimiento sin intervencion directa en la base de datos.

**Que se hizo:**

Se agrego el metodo `action_revert_last_movement()` en `poa.department.budget` que:

1. Busca el ultimo log del techo presupuestario
2. Restaura `budget_amount` y `temp_budget_amount` a los valores previos (`budget_before`, `temp_budget_before`)
3. Si el movimiento fue una transferencia, busca y revierte tambien el movimiento en el departamento contraparte
4. Crea un log de tipo `manual_edit` documentando la reversion
5. Elimina el log revertido
6. Publica mensaje en el chatter

El boton solo es visible para usuarios con rol `group_poa_matrix_admin` y tiene dialogo de confirmacion.

**Archivos modificados:**
- `planification/models/poa_department_budget.py` - Metodo `action_revert_last_movement()`
- `planification/views/poa_department_budget_views.xml` - Boton con `groups`, `confirm`, visible cuando `log_count > 0`

---

## 3. Fix: Wizard de transferencia aparecia con $0 disponible

**Tipo:** Correccion de error

**Problema:**
El wizard de transferencia de presupuesto entre departamentos aparecia incluso cuando el departamento tenia $0.00 disponible. Esto se debia a residuos de precision de punto flotante (por ejemplo, 0.0000000001 > 0 evaluaba como True).

**Que se hizo:**

Se cambio la condicion en `action_approve()` de:
```python
# Antes (problematico)
if self.department_budget_available > 0:
```
a:
```python
# Despues (correcto)
from odoo.tools import float_compare
if float_compare(self.department_budget_available, 0.0, precision_digits=2) > 0:
```

**Archivos modificados:**
- `planification/models/poa_matrix_reform_request.py` - Linea en `action_approve()`

---

## 4. Fix: Error `year_id` en wizard de transferencia

**Tipo:** Correccion de error

**Problema:**
Al intentar transferir presupuesto entre departamentos, se obtenia el error:
```
AttributeError: 'poa.matrix' object has no attribute 'year_id'
```
El modelo `poa.matrix` tiene un campo `year` (Selection), no `year_id` (Many2one).

**Que se hizo:**

Se corrigio la referencia en el wizard:
```python
# Antes (incorrecto)
year_id = self.reform_request_id.matrix_id.year_id.id

# Despues (correcto)
year = self.reform_request_id.matrix_id.year
```
Y el dominio de busqueda correspondiente.

**Archivos modificados:**
- `planification/wizard/poa_budget_transfer_wizard.py` - Linea 77 y dominio de search

---

## 5. Fix: Doble conteo en calculo de presupuesto usado

**Tipo:** Correccion de error

**Problema:**
Al aplicar una reforma que creaba lineas nuevas en la matriz POA, el calculo de `department_budget_used` contaba doble:
1. Las nuevas lineas ya existentes en la matriz (aplicadas)
2. Las lineas temporales de la reforma (que seguian con `is_new=True`)

Esto inflaba el presupuesto usado y mostraba un excedente inexistente, especialmente al retroceder la reforma a borrador despues de aplicar.

**Que se hizo:**

Dos cambios:

**Cambio A - En `_apply_temp_lines_to_matrix()`:**
Despues de crear una nueva linea en la matriz desde una linea temporal, se actualiza la linea temporal para que apunte a la nueva linea original:
```python
temp_line.write({
    'original_line_id_int': new_original_line.id,
    'is_new': False,
})
```
Esto convierte la linea temporal de "nueva" a "vinculada a original", evitando el doble conteo futuro.

**Cambio B - En `_compute_department_budget_used()`:**
Se cambio el filtro de sustraccion de:
```python
# Antes: solo restaba lineas no-nuevas
temp_lines.filtered(lambda l: not l.is_new)
```
a:
```python
# Despues: resta cualquier linea que tenga original vinculado
temp_lines.filtered(lambda l: l.original_line_id_int)
```
Esto cubre reformas ya aplicadas con el codigo anterior donde `original_line_id_int` se habia guardado via inverse pero `is_new` no se habia actualizado.

**Archivos modificados:**
- `planification/models/poa_matrix_reform_request.py` - Metodo `_apply_temp_lines_to_matrix()` y metodo `_compute_department_budget_used()`

---

## 6. Metodo Sincronizar Lineas Aplicadas

**Tipo:** Nueva funcionalidad

**Problema que resuelve:**
Para reformas que ya fueron aplicadas en produccion con el codigo anterior al fix del doble conteo, las lineas temporales nuevas aun tienen `is_new=True`. Esto causa doble conteo pero el usuario no puede recargar las lineas porque perderia el contenido de la reforma.

**Que se hizo:**

Se creo el metodo `action_sync_applied_temp_lines()` que:

1. Busca lineas temporales con `is_new=True` que no estan marcadas para eliminar
2. **Caso 1:** Si `original_line_id_int` ya tiene valor (la inverse funciono durante el apply), solo cambia `is_new = False`
3. **Caso 2:** Si `original_line_id_int` es 0, busca coincidencia en la matriz por actividad + departamento (y proyecto si hay multiples coincidencias)
4. Actualiza `original_line_id_int` e `is_new = False` sin modificar los valores de la reforma
5. Publica un resumen en el chatter

Se agrego boton "Sincronizar Lineas Aplicadas" en el header de la reforma, visible solo para admin en estado borrador/enviado, con dialogo de confirmacion.

**Archivos modificados:**
- `planification/models/poa_matrix_reform_request.py` - Metodo `action_sync_applied_temp_lines()`
- `planification/views/poa_matrix_reform_request_views.xml` - Boton en header

---

## 7. Fix: Duplicacion de lineas de Estimacion Presupuestaria

**Tipo:** Correccion de error

**Problema:**
Al aplicar una reforma, las lineas de "Estimacion Presupuestaria 2026" aparecian duplicadas en la programacion financiera. Por ejemplo, una linea con valor $9,660.00 aparecia dos veces, mostrando un total de $19,320.00.

**Causa raiz:**
El modelo `poa.years` tiene un override de `create()` que automaticamente crea un `poa.financial.program` cada vez que se crea un ano. Al aplicar la reforma:
1. `_apply_temp_financial_to_original_line()` creaba el financial program (primera vez)
2. `_apply_temp_years_to_original_line()` creaba el `poa.years`, cuyo `create()` auto-creaba otro financial program identico (segunda vez)

**Que se hizo:**

Se agrego un flag de contexto `skip_auto_financial_program`:

**En `poa.years` (create y write):**
```python
if self.env.context.get('skip_auto_financial_program'):
    return records  # No auto-crear financial programs
```

**En `_apply_temp_years_to_original_line()`:**
```python
PoaYears = self.env['poa.years'].with_context(skip_auto_financial_program=True)
```

Esto previene la doble creacion porque `_apply_temp_financial_to_original_line()` ya maneja correctamente la creacion/actualizacion de financial programs.

**Archivos modificados:**
- `planification/models/poa_years.py` - Context flag en `create()` y `write()`
- `planification/models/poa_matrix_reform_request.py` - Context en `_apply_temp_years_to_original_line()`

---

## 8. Fix: `temp_budget_amount` no se sincronizaba con `budget_amount`

**Tipo:** Correccion de error

**Problema:**
Al asignar o cambiar el presupuesto de un departamento (`budget_amount`), el techo temporal (`temp_budget_amount`) no se actualizaba porque el compute tenia una condicion restrictiva:
```python
if not record.temp_budget_amount:  # Solo actualizaba si era 0
    record.temp_budget_amount = record.budget_amount
```
Como resultado, la reforma mostraba el techo antiguo en lugar del presupuesto recien asignado.

**Que se hizo:**

Se elimino la condicion para que el compute siempre sincronice:
```python
record.temp_budget_amount = record.budget_amount
```

Esto funciona correctamente porque:
- Las transferencias escriben directamente a `temp_budget_amount` sin tocar `budget_amount`, por lo que el compute no se dispara y los valores de transferencia persisten
- Solo cuando el usuario cambia `budget_amount` explicitamente, el compute se dispara y sincroniza `temp_budget_amount`

**Archivos modificados:**
- `planification/models/poa_department_budget.py` - Metodo `_compute_temp_budget_amount()`

---

## 9. Fix: Actividades nuevas se creaban con programa/año fiscal incorrecto

**Tipo:** Correccion de error

**Problema:**
Al aplicar una reforma y crear nuevas actividades, estas se vinculaban al programa del año fiscal incorrecto. Por ejemplo, si la matriz era del 2026, las actividades podian crearse con el programa "1 - 2024_PROGRAMA 1: FORTALECIMENTO INSTITUCIONAL" en lugar de "43 - 2026_FORTALECIMIENTO INSTITUCIONAL". Esto causaba que la actividad tuviera año fiscal 2024 y se atara a procesos del año incorrecto.

**Causas raiz identificadas:**

1. **Onchange incompleto:** Al cambiar el `program_id` en la linea temporal, el onchange solo limpiaba `project_id` pero NO limpiaba `activity_id`. Si la actividad anterior pertenecia a otro programa, quedaba seleccionada invisiblemente.

2. **Falta de validacion de año fiscal:** No existia validacion que comparara el año fiscal del programa seleccionado con el año de la matriz POA. Si el usuario (o la carga de datos) asignaba un programa de otro año, el sistema lo aceptaba sin cuestionarlo.

3. **`_apply_activity_name_change` incompleto:** Al crear una nueva actividad por cambio de nombre, solo se actualizaba `activity_id` en la linea original pero NO `project_id` ni `program_id`, dejando la linea POA apuntando al proyecto viejo (del programa incorrecto).

**Que se hizo:**

**Cambio A - En `_onchange_program_id()`:**
Se agrego limpieza de `activity_id` cuando no pertenece al nuevo programa:
```python
if self.activity_id and self.activity_id.project_id.program_id != self.program_id:
    self.activity_id = False
```

**Cambio B - En `_create_activity_from_temp_name()`:**
Se agrego validacion del año fiscal del programa contra el año de la matriz. Si el programa seleccionado pertenece a un año fiscal distinto al de la matriz, se registra una advertencia en el chatter para que el usuario lo verifique. Se usa directamente el programa que el usuario selecciono en la reforma (no se autocorrige) ya que la seleccion del usuario es la fuente de verdad.

**Cambio C - En `_apply_activity_name_change()`:**
Al crear la nueva actividad, ahora tambien actualiza `project_id` y `program_id` en la linea original:
```python
update_vals = {
    'activity_id': new_activity.id,
    'project_id': new_activity.project_id.id,
}
if new_activity.project_id and new_activity.project_id.program_id:
    update_vals['program_id'] = new_activity.project_id.program_id.id
temp_line.original_line_id.write(update_vals)
```

**Archivos modificados:**

- `planification/models/poa_matrix_reform_request.py`:
  - `_onchange_program_id()` - Limpia activity_id si no pertenece al nuevo programa
  - `_create_activity_from_temp_name()` - Validacion de año fiscal con advertencia en chatter
  - `_apply_activity_name_change()` - Actualiza project_id y program_id en linea original

---

## 10. Fix: Codigos secuenciales de proyectos y actividades no incrementaban correctamente

**Tipo:** Correccion de error

**Problema:**
Al aplicar una reforma que creaba multiples actividades nuevas, todos los proyectos se creaban con codigo "10" y todas las actividades con codigo "001". El secuencial no incrementaba correctamente, generando codigos duplicados.

**Causa raiz:**
El campo `short_code` en `budget.project` y `account.analytic.account` es de tipo `Char`. La busqueda usaba `order='short_code desc', limit=1` para encontrar el ultimo codigo, pero el ordenamiento de un campo Char es **lexicografico**, no numerico.

Ejemplo con codigos existentes "1", "2", "3", "9", "10":

- Orden lexicografico desc: "9", "8", "3", "2", "10", "1"
- El sistema tomaba "9" como maximo, generaba "10"
- La proxima vez, "9" seguia siendo el "maximo" lexicografico, volviendo a generar "10"

Esto causaba que todos los proyectos nuevos tuvieran el mismo codigo.

Para actividades, el efecto era diferente: como cada actividad se crea dentro de un proyecto recien creado (0 actividades existentes), siempre caia al default "001".

**Que se hizo:**

Se reemplazo la busqueda con `order='short_code desc', limit=1` por una busqueda de todos los registros del programa/proyecto, iterando para encontrar el maximo **numerico** real:

```python
# Antes (lexicografico - bug)
existing_projects = ProjectModel.search([
    ('program_id', '=', program_id.id)
], order='short_code desc', limit=1)

# Despues (numerico - correcto)
existing_projects = ProjectModel.search([
    ('program_id', '=', program_id.id)
])
max_code = 0
for proj in existing_projects:
    if proj.short_code:
        try:
            code_int = int(proj.short_code)
            if code_int > max_code:
                max_code = code_int
        except ValueError:
            pass
new_project_code = str(max_code + 1)
```

Se aplico la misma correccion para actividades con `zfill(3)` para mantener padding de 3 digitos (001, 002, ..., 010).

**Archivos modificados:**

- `planification/models/poa_matrix_reform_request.py` - Metodo `_create_activity_from_temp_name()`: correccion de generacion de `short_code` para proyectos y actividades
