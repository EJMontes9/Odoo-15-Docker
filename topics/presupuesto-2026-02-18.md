# Presupuesto - Cambios 2026-02-18

Registro de cambios realizados el 18 de febrero de 2026 en el módulo **budget_gov** (Sistema de Presupuesto Gubernamental).

## 1. NUEVO: Cédula Presupuestaria Interactiva (budget.query.deluxe)

**Tipo:** Nueva funcionalidad

**Propósito:**
Reemplazar el wizard transitorio antiguo de Cédula Presupuestaria con una solución moderna e interactiva similar al "Libro Mayor" de contabilidad. Proporciona una vista de análisis presupuestario en tiempo real con múltiples perspectivas (lista, pivot, gráficos) y exportación a Excel.

**Características principales:**

1. **Vista SQL de solo lectura** - No editable, optimizada para rendimiento
2. **Múltiples vistas de análisis:**
   - Vista Lista - Detalle línea por línea
   - Vista Pivot - Tabla dinámica para análisis multidimensional
   - Vista Gráfico - Visualización de datos presupuestarios
3. **Filtros avanzados en tiempo real:**
   - Por fechas (desde/hasta)
   - Por años fiscales
   - Por organización (unidad ejecutora)
   - Por saldos (con saldo, sin saldo)
   - Por naturaleza del gasto (corriente/capital)
4. **Exportación a Excel personalizada** con un clic
5. **Campos mostrados:**
   - **Presupuestos:** Inicial, Modificado, Codificado
   - **Ejecución:** Certificado, Comprometido, Devengado, Pagado
   - **Saldos calculados:** Por Certificar, Por Devengar, Por Pagar
6. **Agrupaciones dinámicas por:**
   - Año Fiscal
   - Organización (Unidad Ejecutora)
   - Programa Presupuestario
   - Proyecto Presupuestario
   - Área Administrativa
   - Naturaleza del Gasto (Corriente/Capital)

### Archivos creados

**Modelo:**
- `models/budget_query_deluxe.py`
  - Modelo: `budget.query.deluxe`
  - Tipo: SQL View (`_auto = False`)
  - Campos: 20+ campos incluyendo todos los montos presupuestarios y sus saldos

**Vistas:**
- `views/budget_query_deluxe_views.xml`
  - Vista tree (lista detallada)
  - Vista pivot (tabla dinámica)
  - Vista graph (gráficos de barras/líneas/circular)
  - Vista search (filtros y agrupaciones)
  - Acción de ventana
  - Item de menú: "Presupuesto > Cédula Presupuestaria" (secuencia: 5)

**Wizard de exportación:**
- `wizard/wizard_export_query_deluxe.py`
  - Wizard: `wizard.export.query.deluxe`
  - Exporta los datos ya filtrados en la vista a Excel
- `wizard/wizard_export_query_deluxe.xml`
  - Formulario del wizard (confirmar exportación)

**Reporte Excel:**
- `report/report_query_deluxe_excel.py`
  - Clase: `QueryDeluxeExcelReport`
  - Hereda de: `report_xlsx.abstract`
  - Genera Excel con formato profesional
- `report/reports.xml`
  - Registro del reporte: `report_query_deluxe_xlsx`

### Fuentes de datos consolidadas

La vista SQL realiza LEFT JOINS sobre las siguientes tablas:

| Tabla | Propósito |
|-------|-----------|
| `account.analytic.account.line` | Base principal - Líneas de actividad por año fiscal |
| `account.analytic.account` | Actividades presupuestarias |
| `budget.classifier` | Clasificadores presupuestarios (partidas) |
| `budget_initial_line` | Presupuesto inicial asignado |
| `budget_redistribution_destination` | Modificaciones recibidas (aumentos) |
| `budget_redistribution_origin` | Modificaciones enviadas (disminuciones) |
| `budget_certification_activity` | Certificaciones emitidas |
| `account_move_line` | Devengados (facturas publicadas) y pagos |

### Cálculo de campos presupuestarios

```python
# Presupuesto Inicial
initial = SUM(budget_initial_line.amount)

# Presupuesto Modificado
modified = SUM(redistribution_destination.amount) - SUM(redistribution_origin.amount)

# Presupuesto Codificado
codified = initial + modified

# Certificado (compromisos admitidos/adjudicados)
certified = SUM(budget_certification_activity.amount WHERE state='adjudicated')

# Comprometido (certificaciones adjudicadas)
committed = certified  # Mismo valor

# Devengado (facturas publicadas)
accrued = SUM(account_move_line.debit WHERE move.state='posted')

# Pagado (facturas marcadas como pagadas)
paid = SUM(account_move_line.debit WHERE move.state='posted' AND move.payment_state='paid')

# Saldos
balance_to_certify = codified - certified
balance_to_accrue = certified - accrued
balance_to_pay = accrued - paid
```

### Permisos de seguridad

Acceso de **lectura** para todos los roles de presupuesto:

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_budget_query_deluxe_manager,budget.query.deluxe manager,model_budget_query_deluxe,group_budget_manager,1,0,0,0
access_budget_query_deluxe_presupuesto,budget.query.deluxe presupuesto,model_budget_query_deluxe,group_budget_presupuesto,1,0,0,0
access_budget_query_deluxe_lector,budget.query.deluxe lector,model_budget_query_deluxe,group_budget_lector,1,0,0,0
access_wizard_export_query_deluxe,wizard.export.query.deluxe,model_wizard_export_query_deluxe,group_budget_presupuesto,1,1,1,1
```

### Ubicación en el menú

**Menú principal:**
- Presupuesto > Cédula Presupuestaria (secuencia: 5)

**Acción:**
- Modo de vista por defecto: `tree,pivot,graph`
- Vista inicial: tree (lista)

### Flujo de trabajo del usuario

**Antes (wizard antiguo):**
1. Usuario abre wizard "Cédula Presupuestaria (Vista)"
2. Selecciona filtros en formulario
3. Presiona botón "Ver datos"
4. Datos se muestran en formulario estático
5. No hay exportación directa
6. Para cambiar filtros debe cerrar y reabrir wizard

**Ahora (vista interactiva moderna):**
1. Usuario abre "Cédula Presupuestaria" desde menú principal
2. Aplica filtros en tiempo real (año, fechas, organización, naturaleza, saldos)
3. Visualiza datos interactivamente en vista lista
4. Cambia a vista Pivot para análisis multidimensional
5. Cambia a vista Gráfico para visualización
6. Agrupa/desagrupa dinámicamente por cualquier dimensión
7. Exporta a Excel con un solo clic manteniendo los filtros aplicados
8. Los filtros persisten y se pueden ajustar en cualquier momento

---

## 2. ELIMINADO: Wizard transitorio antiguo de Cédula Presupuestaria

**Tipo:** Eliminación de código obsoleto

**Justificación:**
El wizard transitorio (`wizard.cedula.presupuestaria`) fue reemplazado completamente por el nuevo modelo `budget.query.deluxe` que ofrece mejor experiencia de usuario, rendimiento optimizado y capacidades de análisis interactivo.

### Archivos eliminados

**Modelo wizard:**
- `models/budget_cedula_presupuestaria.py`
  - Modelo: `wizard.cedula.presupuestaria` (transitorio)
  - Modelo: `wizard.cedula.presupuestaria.line` (transitorio)

**Vistas del wizard:**
- `views/budget_cedula_presupuestaria_views.xml`
  - Vista form del wizard
  - Vista tree de líneas
  - Acción de ventana

### Reglas de seguridad eliminadas

De `security/ir.model.access.csv`:

```csv
# ELIMINADO:
access_wizard_cedula_presupuestaria
access_wizard_cedula_presupuestaria_line
```

### Limitaciones del wizard antiguo

El wizard antiguo tenía las siguientes limitaciones que justificaron su reemplazo:

1. **Modelo transitorio** - Los datos se perdían al cerrar la ventana
2. **No persistente** - No se podían guardar filtros favoritos
3. **Interfaz estática** - Una vez generados los datos, no se podían reordenar o reagrupar
4. **Sin vistas múltiples** - Solo vista lista, sin pivot ni gráficos
5. **Exportación limitada** - No había opción de exportar a Excel
6. **Rendimiento** - Cargaba todos los datos en memoria (ORM)
7. **UX deficiente** - Requería cerrar y reabrir para cambiar filtros

---

## 3. MODIFICADO: Renombrado de menús de reportes Excel

**Tipo:** Mejora de UX

**Objetivo:**
Evitar confusión entre la nueva vista interactiva "Cédula Presupuestaria" y los reportes Excel existentes que generan archivos descargables sin vista previa.

### Cambios en el menú "Informes"

**Archivo modificado:** `views/menu.xml`

| Nombre anterior | Nombre nuevo |
|----------------|--------------|
| Cédula presupuestaria por actividad | **Excel:** Cédula presupuestaria por actividad |
| Cédula Presupuestaria | **Excel:** Cédula Presupuestaria |

**Razón del cambio:**
Ahora existen dos formas de acceder a la información de cédula presupuestaria:

1. **Cédula Presupuestaria** (menú principal) - Vista interactiva con análisis en tiempo real
2. **Excel: Cédula Presupuestaria** (menú Informes) - Descarga directa de archivo Excel

El prefijo "Excel:" aclara que estos reportes generan archivos descargables, no vistas interactivas.

---

## 4. MODIFICADO: Configuración del módulo

**Tipo:** Actualización de configuración

### Archivos modificados

**models/__init__.py:**
```python
# ELIMINADO:
# from . import budget_cedula_presupuestaria

# AÑADIDO:
from . import budget_query_deluxe
```

**wizard/__init__.py:**
```python
# AÑADIDO:
from . import wizard_export_query_deluxe
```

**report/__init__.py:**
```python
# AÑADIDO:
from . import report_query_deluxe_excel
```

**__manifest__.py:**
```python
'data': [
    # ... otros archivos ...

    # AÑADIDO:
    'wizard/wizard_export_query_deluxe.xml',
    'views/budget_query_deluxe_views.xml',

    # MODIFICADO (renombrados):
    'views/menu.xml',
],
```

**security/ir.model.access.csv:**
```csv
# ELIMINADO:
access_wizard_cedula_presupuestaria,wizard.cedula.presupuestaria,model_wizard_cedula_presupuestaria,group_budget_presupuesto,1,1,1,1
access_wizard_cedula_presupuestaria_line,wizard.cedula.presupuestaria.line,model_wizard_cedula_presupuestaria_line,group_budget_presupuesto,1,1,1,1

# AÑADIDO:
access_budget_query_deluxe_manager,budget.query.deluxe manager,model_budget_query_deluxe,group_budget_manager,1,0,0,0
access_budget_query_deluxe_presupuesto,budget.query.deluxe presupuesto,model_budget_query_deluxe,group_budget_presupuesto,1,0,0,0
access_budget_query_deluxe_lector,budget.query.deluxe lector,model_budget_query_deluxe,group_budget_lector,1,0,0,0
access_wizard_export_query_deluxe,wizard.export.query.deluxe,model_wizard_export_query_deluxe,group_budget_presupuesto,1,1,1,1
```

**report/reports.xml:**
```xml
<!-- AÑADIDO: -->
<record id="report_query_deluxe_xlsx" model="ir.actions.report">
    <field name="name">Exportar Cédula Presupuestaria</field>
    <field name="model">wizard.export.query.deluxe</field>
    <field name="report_type">xlsx</field>
    <field name="report_name">budget_gov.report_query_deluxe_excel</field>
    <field name="report_file">Cedula_Presupuestaria</field>
    <field name="binding_model_id" ref="model_wizard_export_query_deluxe"/>
    <field name="binding_type">report</field>
</record>
```

---

## 5. Tecnologías y patrones utilizados

### SQL Views en Odoo

**Patrón:** Modelo de solo lectura con SQL personalizado

```python
class BudgetQueryDeluxe(models.Model):
    _name = 'budget.query.deluxe'
    _description = 'Cédula Presupuestaria'
    _auto = False  # No crear tabla, usar SQL view
    _rec_name = 'activity_name'
    _order = 'fiscal_year_id desc, activity_name'

    def init(self):
        tools.drop_view_if_exists(self.env.cr, self._table)
        self.env.cr.execute("""
            CREATE OR REPLACE VIEW %s AS (
                SELECT ... FROM ...
            )
        """ % self._table)
```

**Ventajas:**
- Rendimiento óptimo (query SQL directa)
- No duplicación de datos
- Actualización en tiempo real
- Menor uso de memoria

### Reportes Excel con report_xlsx

**Patrón:** Herencia de clase abstracta para generación de Excel

```python
from odoo.addons.report_xlsx.report.report_xlsx import ReportXlsxAbstract

class QueryDeluxeExcelReport(models.AbstractModel):
    _name = 'report.budget_gov.report_query_deluxe_excel'
    _inherit = 'report.report_xlsx.abstract'

    def generate_xlsx_report(self, workbook, data, objects):
        # Crear hoja de cálculo
        sheet = workbook.add_worksheet('Cédula Presupuestaria')

        # Definir formatos
        header_format = workbook.add_format({...})
        number_format = workbook.add_format({...})

        # Escribir encabezados y datos
        # ...
```

**Características del reporte:**
- Encabezados con formato profesional
- Números con formato monetario ($ 1,234.56)
- Totales calculados
- Anchos de columna ajustados automáticamente
- Nombre de archivo descriptivo con fecha

### Wizard de exportación

**Patrón:** Wizard transitorio para confirmar acción

```python
class WizardExportQueryDeluxe(models.TransientModel):
    _name = 'wizard.export.query.deluxe'
    _description = 'Exportar Cédula Presupuestaria a Excel'

    # Campos para capturar IDs de registros filtrados
    query_ids = fields.Many2many('budget.query.deluxe', string='Registros')

    def action_export_excel(self):
        # Generar y descargar Excel con los IDs recibidos
        return self.env.ref('budget_gov.report_query_deluxe_xlsx').report_action(self)
```

**Flujo:**
1. Usuario aplica filtros en vista `budget.query.deluxe`
2. Usuario presiona botón "Exportar a Excel"
3. Se abre wizard con los IDs de los registros filtrados
4. Usuario confirma exportación
5. Se genera y descarga archivo Excel

### Filtros y agrupaciones en vistas

**Vista search con múltiples filtros:**

```xml
<search string="Buscar Cédula Presupuestaria">
    <!-- Filtros predefinidos -->
    <filter name="has_balance" string="Con saldo" domain="[('balance_to_pay', '>', 0)]"/>
    <filter name="no_balance" string="Sin saldo" domain="[('balance_to_pay', '=', 0)]"/>
    <filter name="corriente" string="Corriente" domain="[('nature', '=', 'corriente')]"/>
    <filter name="capital" string="Capital" domain="[('nature', '=', 'capital')]"/>

    <!-- Agrupaciones dinámicas -->
    <group expand="0" string="Agrupar por">
        <filter name="group_fiscal_year" string="Año Fiscal" context="{'group_by': 'fiscal_year_id'}"/>
        <filter name="group_organization" string="Organización" context="{'group_by': 'organization_id'}"/>
        <filter name="group_program" string="Programa" context="{'group_by': 'program_id'}"/>
        <!-- ... más agrupaciones ... -->
    </group>
</search>
```

---

## 6. Estructura completa del módulo budget_gov después de los cambios

```
addons/Aeroportuaria_ERP/budget/budget_gov/
├── models/
│   ├── __init__.py                           [MODIFICADO]
│   ├── budget_query_deluxe.py               [NUEVO]
│   ├── budget_cedula_presupuestaria.py      [ELIMINADO]
│   └── ... (otros modelos existentes)
├── views/
│   ├── budget_query_deluxe_views.xml        [NUEVO]
│   ├── budget_cedula_presupuestaria_views.xml [ELIMINADO]
│   ├── menu.xml                             [MODIFICADO]
│   └── ... (otras vistas existentes)
├── wizard/
│   ├── __init__.py                          [MODIFICADO]
│   ├── wizard_export_query_deluxe.py        [NUEVO]
│   ├── wizard_export_query_deluxe.xml       [NUEVO]
│   └── ... (otros wizards existentes)
├── report/
│   ├── __init__.py                          [MODIFICADO]
│   ├── report_query_deluxe_excel.py         [NUEVO]
│   ├── reports.xml                          [MODIFICADO]
│   └── ... (otros reportes existentes)
├── security/
│   └── ir.model.access.csv                  [MODIFICADO]
├── __init__.py
└── __manifest__.py                          [MODIFICADO]
```

---

## 7. Guía de uso para el usuario final

### Acceder a la Cédula Presupuestaria

1. Navegar a: **Presupuesto > Cédula Presupuestaria**
2. Se abre vista lista con todos los registros presupuestarios

### Aplicar filtros

**Filtros rápidos (barra superior):**
- "Con saldo" - Muestra solo partidas con saldo por pagar > 0
- "Sin saldo" - Muestra solo partidas sin saldo
- "Corriente" - Solo gastos de naturaleza corriente
- "Capital" - Solo gastos de naturaleza capital

**Búsqueda avanzada (icono de embudo):**
- Filtrar por rango de fechas
- Filtrar por año fiscal específico
- Filtrar por organización (unidad ejecutora)
- Combinar múltiples filtros con AND/OR

### Cambiar vista de análisis

**Vista Lista (por defecto):**
- Detalle línea por línea
- Todos los campos visibles
- Ordenamiento por columna

**Vista Pivot (tabla dinámica):**
- Click en icono de tabla
- Arrastrar y soltar dimensiones
- Rotar filas/columnas
- Expandir/colapsar jerarquías

**Vista Gráfico:**
- Click en icono de gráfico
- Tipos: Barras, Líneas, Circular
- Seleccionar medida (Codificado, Devengado, Pagado, etc.)
- Seleccionar dimensión (Año, Programa, Proyecto, etc.)

### Agrupar datos

1. Click en "Agrupar por" en barra de búsqueda
2. Seleccionar dimensión: Año Fiscal, Organización, Programa, Proyecto, Área, Naturaleza
3. Los datos se agrupan automáticamente
4. Click en grupo para expandir/colapsar

### Exportar a Excel

1. Aplicar todos los filtros y agrupaciones deseadas
2. Click en botón **"Exportar a Excel"** (barra superior)
3. Se abre ventana de confirmación
4. Click en **"Generar Excel"**
5. El archivo se descarga automáticamente con nombre: `Cedula_Presupuestaria_YYYY-MM-DD.xlsx`

**Nota:** El Excel exportado respeta todos los filtros y agrupaciones aplicados en la vista.

---

## 8. Impacto en usuarios

### Beneficios

1. **Análisis en tiempo real** - No necesita esperar generación de reportes
2. **Flexibilidad** - Múltiples vistas para diferentes necesidades
3. **Interactividad** - Cambiar filtros y agrupaciones al instante
4. **Exportación rápida** - Excel generado con los datos exactos que ve en pantalla
5. **Mejor UX** - Interfaz moderna similar a otras vistas de Odoo
6. **Rendimiento** - SQL View optimizado, más rápido que wizard transitorio

### Cambios visibles

1. **Menú principal** - Nuevo item "Cédula Presupuestaria"
2. **Menú Informes** - Reportes Excel ahora tienen prefijo "Excel:"
3. **Wizard antiguo** - Ya no aparece en el sistema

### Migración de workflow

Los usuarios que usaban el wizard antiguo deben:
1. Usar el nuevo menú "Presupuesto > Cédula Presupuestaria"
2. Aplicar filtros con la barra de búsqueda (en lugar de formulario del wizard)
3. Exportar con el botón "Exportar a Excel" (en lugar de generar wizard)

**No se requiere capacitación extensa** - La nueva interfaz es más intuitiva y sigue patrones estándar de Odoo.

---

## Resumen de cambios

| Tipo | Cantidad | Archivos |
|------|----------|----------|
| **AÑADIDO** | 6 archivos | `budget_query_deluxe.py`, `budget_query_deluxe_views.xml`, `wizard_export_query_deluxe.py`, `wizard_export_query_deluxe.xml`, `report_query_deluxe_excel.py`, entrada en `reports.xml` |
| **ELIMINADO** | 2 archivos | `budget_cedula_presupuestaria.py`, `budget_cedula_presupuestaria_views.xml` |
| **MODIFICADO** | 6 archivos | `models/__init__.py`, `wizard/__init__.py`, `report/__init__.py`, `__manifest__.py`, `security/ir.model.access.csv`, `views/menu.xml` |

**Líneas de código:**
- Añadidas: ~800 líneas (modelo + vistas + wizard + reporte)
- Eliminadas: ~400 líneas (wizard antiguo)
- Neto: +400 líneas

**Impacto en base de datos:**
- Nueva vista SQL: `budget_query_deluxe` (no ocupa espacio, es virtual)
- Modelo wizard eliminado: sin impacto (era transitorio)
- Sin migración de datos requerida

---

## Próximos pasos recomendados

1. **Capacitación básica** - Video corto (5 min) mostrando nuevo workflow
2. **Feedback de usuarios** - Recopilar opiniones después de 1 semana de uso
3. **Optimización SQL** - Revisar performance con datos de producción
4. **Documentación de usuario** - Actualizar manual de usuario del módulo Presupuesto
5. **Exportación personalizada** - Considerar agregar más opciones de formato Excel si lo requieren

---

## Notas técnicas adicionales

### Rendimiento

La vista SQL incluye múltiples LEFT JOINS. En bases de datos grandes (>100,000 líneas presupuestarias), considerar:
- Crear índices en columnas de join (`account_analytic_account_line.analytic_account_id`, `account_analytic_account_line.fiscal_year_id`)
- Usar filtros por año fiscal en lugar de cargar todos los años
- Monitorear query plan con `EXPLAIN ANALYZE` si hay lentitud

### Mantenimiento

Si se agregan campos al modelo `account.analytic.account.line` o `budget_classifier`, recordar:
1. Actualizar SQL en `budget_query_deluxe.init()`
2. Agregar campos correspondientes en el modelo Python
3. Actualizar vistas XML para mostrar nuevos campos
4. Actualizar reporte Excel si aplica

### Extensibilidad

Para agregar nuevas columnas calculadas (ejemplo: % de ejecución):
1. Agregar campo en el SELECT de la vista SQL
2. Definir campo en el modelo Python
3. Agregar columna en las vistas tree/pivot
4. Agregar columna en el reporte Excel

Ejemplo:
```python
# En budget_query_deluxe.py
execution_percentage = fields.Float('% Ejecución', readonly=True)

# En init() SQL
SELECT
    ...,
    CASE
        WHEN COALESCE(codified_sum, 0) = 0 THEN 0
        ELSE (COALESCE(accrued_sum, 0) / COALESCE(codified_sum, 0)) * 100
    END as execution_percentage
FROM ...
```
