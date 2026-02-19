# Modelos y Base de Datos

<show-structure for="chapter,procedure" depth="2"/>

## Introducción

El módulo de Presupuesto Gubernamental define más de 30 modelos de datos que representan la estructura presupuestaria y sus operaciones. Esta documentación describe los modelos principales y sus relaciones.

## Diagrama de Entidad-Relación (ERD)

<code-block lang="mermaid">
erDiagram
    budget_program ||--o{ budget_project : contiene
    budget_project ||--o{ account_analytic_account : contiene
    account_analytic_account ||--o{ budget_initial : tiene
    account_analytic_account ||--|| budget_classifier : clasifica
    account_analytic_account ||--o{ budget_certification_activity : recibe
    budget_certification ||--|{ budget_certification_activity : detalla
    budget_redistribution ||--o{ budget_redistribution_line : contiene
    account_analytic_account ||--o{ account_move_line : ejecuta
    budget_certification ||--o{ account_move_line : compromete

    budget_program {
        integer id PK
        char code
        char name
        integer sequence
    }

    budget_project {
        integer id PK
        char code
        char name
        integer program_id FK
    }

    account_analytic_account {
        integer id PK
        char code
        char name
        integer program_id FK
        integer project_id FK
        integer classifier_id FK
        selection planning
        date archived_date
    }

    budget_classifier {
        integer id PK
        char code
        char name
        selection type
    }

    budget_certification {
        integer id PK
        char lote
        date date
        selection state
        float total
        integer year
    }

    budget_certification_activity {
        integer id PK
        integer certification_id FK
        integer activity_id FK
        float amount
    }

    budget_initial {
        integer id PK
        integer activity_id FK
        integer classifier_id FK
        float amount
        integer year
    }

    budget_redistribution {
        integer id PK
        char name
        date date
        selection state
        integer year
    }
</code-block>

## Modelos Principales

### 1. account.analytic.account (Actividades Presupuestarias)

<warning>
Este es el modelo central del sistema presupuestario. Representa las actividades donde se asigna y ejecuta el presupuesto.
</warning>

**Nombre técnico:** `account.analytic.account`
**Descripción:** Actividades presupuestarias vinculadas a programas y proyectos
**Hereda de:** Modelo estándar de Odoo (extensión)

#### Campos Principales

<table>
<tr>
<td><b>Campo Técnico</b></td>
<td><b>Tipo</b></td>
<td><b>Descripción</b></td>
<td><b>Requerido</b></td>
</tr>
<tr>
<td>code</td>
<td>Char</td>
<td>Código único de la actividad</td>
<td>Sí</td>
</tr>
<tr>
<td>name</td>
<td>Char</td>
<td>Nombre descriptivo de la actividad</td>
<td>Sí</td>
</tr>
<tr>
<td>program_id</td>
<td>Many2one</td>
<td>Programa al que pertenece</td>
<td>Sí</td>
</tr>
<tr>
<td>project_id</td>
<td>Many2one</td>
<td>Proyecto al que pertenece</td>
<td>Sí</td>
</tr>
<tr>
<td>classifier_id</td>
<td>Many2one</td>
<td>Clasificador presupuestario</td>
<td>Sí</td>
</tr>
<tr>
<td>planning</td>
<td>Selection</td>
<td>Estado: planning, active, archived</td>
<td>Sí</td>
</tr>
<tr>
<td>archived_date</td>
<td>Date</td>
<td>Fecha de archivado (si aplica)</td>
<td>No</td>
</tr>
<tr>
<td>company_id</td>
<td>Many2one</td>
<td>Compañía</td>
<td>Sí</td>
</tr>
</table>

#### Métodos Principales

<code-block lang="python">
def get_budget_available(self, year):
    """
    Calcula el presupuesto disponible de la actividad para un año dado

    Args:
        year (int): Año fiscal

    Returns:
        float: Monto disponible
    """
    pass

def archive_activity(self):
    """
    Archiva la actividad y actualiza archived_date
    """
    pass
</code-block>

#### Restricciones

- El código de actividad debe ser único
- No se puede eliminar una actividad con presupuesto ejecutado
- Las actividades archivadas no pueden recibir nuevas certificaciones

---

### 2. budget.certification (Certificaciones Presupuestarias)

**Nombre técnico:** `budget.certification`
**Descripción:** Certificaciones que comprometen presupuesto antes de realizar compras
**Hereda de:** `mail.thread` (para seguimiento)

#### Campos Principales

<table>
<tr>
<td><b>Campo Técnico</b></td>
<td><b>Tipo</b></td>
<td><b>Descripción</b></td>
<td><b>Ejemplo</b></td>
</tr>
<tr>
<td>lote</td>
<td>Char</td>
<td>Número de certificación (auto-generado)</td>
<td>CP-2024-001</td>
</tr>
<tr>
<td>state</td>
<td>Selection</td>
<td>Estado: waiting, admitted, awarded, canceled</td>
<td>admitted</td>
</tr>
<tr>
<td>date</td>
<td>Date</td>
<td>Fecha de emisión</td>
<td>2024-03-15</td>
</tr>
<tr>
<td>year</td>
<td>Selection</td>
<td>Año fiscal</td>
<td>2024</td>
</tr>
<tr>
<td>description</td>
<td>Char</td>
<td>Descripción de la certificación</td>
<td>Compra de equipos informáticos</td>
</tr>
<tr>
<td>supplier_id</td>
<td>Many2one</td>
<td>Proveedor (si ya está seleccionado)</td>
<td>-</td>
</tr>
<tr>
<td>total</td>
<td>Float</td>
<td>Monto total (computado)</td>
<td>5000.00</td>
</tr>
<tr>
<td>activities_ids</td>
<td>One2many</td>
<td>Actividades involucradas</td>
<td>-</td>
</tr>
<tr>
<td>move_line_ids</td>
<td>One2many</td>
<td>Líneas contables vinculadas</td>
<td>-</td>
</tr>
</table>

#### Estados del Workflow

<code-block lang="mermaid">
stateDiagram-v2
    [*] --> waiting: Crear
    waiting --> admitted: Admitir
    waiting --> canceled: Cancelar
    admitted --> awarded: Adjudicar
    admitted --> canceled: Cancelar
    awarded --> [*]
    canceled --> [*]
</code-block>

#### Métodos Principales

<code-block lang="python">
@api.depends('activities_ids', 'activities_ids.amount')
def _compute_total(self):
    """Calcula el total de la certificación sumando actividades"""
    pass

def action_admit(self):
    """Admite la certificación y valida disponibilidad presupuestaria"""
    pass

def action_award(self):
    """Adjudica la certificación a un proveedor"""
    pass

def action_cancel(self):
    """Cancela la certificación y libera presupuesto"""
    pass
</code-block>

#### Validaciones

<warning>
<list>
<li>El monto total no puede exceder el disponible en las actividades</li>
<li>No se puede admitir una certificación sin actividades</li>
<li>No se puede adjudicar sin estar en estado "admitida"</li>
<li>Las certificaciones canceladas no se pueden reactivar</li>
</list>
</warning>

---

### 3. budget.certification.activity (Detalle de Certificaciones)

**Nombre técnico:** `budget.certification.activity`
**Descripción:** Líneas de detalle que especifican el monto por actividad en una certificación

#### Campos Principales

<table>
<tr>
<td><b>Campo</b></td>
<td><b>Tipo</b></td>
<td><b>Descripción</b></td>
</tr>
<tr>
<td>certification_id</td>
<td>Many2one</td>
<td>Certificación padre</td>
</tr>
<tr>
<td>activity_id</td>
<td>Many2one</td>
<td>Actividad presupuestaria</td>
</tr>
<tr>
<td>amount</td>
<td>Float</td>
<td>Monto asignado a esta actividad</td>
</tr>
<tr>
<td>initial_budget</td>
<td>Float</td>
<td>Presupuesto inicial de la actividad</td>
</tr>
<tr>
<td>available_budget</td>
<td>Float</td>
<td>Presupuesto disponible (computado)</td>
</tr>
</table>

---

### 4. budget.initial (Presupuesto Inicial)

**Nombre técnico:** `budget.initial`
**Descripción:** Registro del presupuesto inicial anual por actividad y clasificador

#### Campos Principales

<table>
<tr>
<td><b>Campo</b></td>
<td><b>Tipo</b></td>
<td><b>Descripción</b></td>
</tr>
<tr>
<td>name</td>
<td>Char</td>
<td>Nombre del presupuesto inicial</td>
</tr>
<tr>
<td>year</td>
<td>Selection</td>
<td>Año fiscal</td>
</tr>
<tr>
<td>state</td>
<td>Selection</td>
<td>Estado: draft, approved</td>
</tr>
<tr>
<td>detail_ids</td>
<td>One2many</td>
<td>Líneas de detalle del presupuesto</td>
</tr>
<tr>
<td>total_amount</td>
<td>Float</td>
<td>Monto total (computado)</td>
</tr>
</table>

#### detail_budget_initial (Detalle del Presupuesto Inicial)

Líneas individuales del presupuesto inicial:

<table>
<tr>
<td><b>Campo</b></td>
<td><b>Descripción</b></td>
</tr>
<tr>
<td>budget_id</td>
<td>Presupuesto inicial padre</td>
</tr>
<tr>
<td>activity_id</td>
<td>Actividad presupuestaria</td>
</tr>
<tr>
<td>classifier_id</td>
<td>Clasificador presupuestario</td>
</tr>
<tr>
<td>amount</td>
<td>Monto asignado</td>
</tr>
</table>

---

### 5. budget.redistribution (Redistribuciones Presupuestarias)

**Nombre técnico:** `budget.redistribution`
**Descripción:** Movimientos de presupuesto entre actividades durante el año fiscal

#### Campos Principales

<table>
<tr>
<td><b>Campo</b></td>
<td><b>Tipo</b></td>
<td><b>Descripción</b></td>
</tr>
<tr>
<td>name</td>
<td>Char</td>
<td>Número de redistribución</td>
</tr>
<tr>
<td>date</td>
<td>Date</td>
<td>Fecha de la redistribución</td>
</tr>
<tr>
<td>year</td>
<td>Selection</td>
<td>Año fiscal</td>
</tr>
<tr>
<td>state</td>
<td>Selection</td>
<td>Estado: draft, approved, canceled</td>
</tr>
<tr>
<td>line_ids</td>
<td>One2many</td>
<td>Líneas de aumento/disminución</td>
</tr>
<tr>
<td>description</td>
<td>Text</td>
<td>Justificación de la redistribución</td>
</tr>
</table>

#### Restricciones Importantes

<note>
<b>Regla de Gastos Corrientes vs Capital:</b>
Las redistribuciones NO pueden mover presupuesto entre gastos corrientes y gastos de capital. Solo se permiten movimientos dentro del mismo tipo de gasto.
</note>

<code-block lang="python">
def validate_redistribution(self):
    """
    Valida que:
    1. Los aumentos y disminuciones sean iguales
    2. No se mezclen gastos corrientes y de capital
    3. No se excedan los disponibles
    """
    pass
</code-block>

---

### 6. budget.query.deluxe (Cédula Presupuestaria)

**Nombre técnico:** `budget.query.deluxe`
**Descripción:** Vista SQL consolidada con el estado presupuestario en tiempo real
**Tipo:** Vista SQL (no es una tabla física)

<warning>
Este modelo es una VISTA SQL, no una tabla. Se regenera automáticamente al actualizar el módulo.
</warning>

#### Campos Calculados

<table>
<tr>
<td><b>Campo</b></td>
<td><b>Descripción</b></td>
<td><b>Fórmula</b></td>
</tr>
<tr>
<td>initial_amount</td>
<td>Presupuesto inicial</td>
<td>Suma de budget_initial</td>
</tr>
<tr>
<td>redistribution_amount</td>
<td>Redistribuciones netas</td>
<td>Suma de aumentos - disminuciones</td>
</tr>
<tr>
<td>codified_amount</td>
<td>Presupuesto codificado</td>
<td>initial_amount + redistribution_amount</td>
</tr>
<tr>
<td>committed_amount</td>
<td>Comprometido (certificaciones)</td>
<td>Suma de certificaciones admitidas</td>
</tr>
<tr>
<td>accrued_amount</td>
<td>Devengado</td>
<td>Suma de facturas validadas</td>
</tr>
<tr>
<td>paid_amount</td>
<td>Pagado</td>
<td>Suma de pagos registrados</td>
</tr>
<tr>
<td>available_amount</td>
<td>Disponible</td>
<td>codified_amount - committed_amount</td>
</tr>
</table>

#### Exportación a Excel

El modelo incluye un wizard especializado para exportar la cédula presupuestaria a Excel con formato oficial:

<code-block lang="python">
class WizardExportQueryDeluxe(models.TransientModel):
    _name = 'wizard.export.query.deluxe'

    def action_export_excel(self):
        """
        Exporta la cédula presupuestaria a Excel con:
        - Formato oficial del gobierno
        - Filtros por año, programa, proyecto
        - Agrupaciones jerárquicas
        - Totales y subtotales
        """
        pass
</code-block>

---

### 7. budget.classifier (Clasificadores Presupuestarios)

**Nombre técnico:** `budget.classifier`
**Descripción:** Clasificador presupuestario gubernamental (partidas presupuestarias)

#### Campos Principales

<table>
<tr>
<td><b>Campo</b></td>
<td><b>Tipo</b></td>
<td><b>Descripción</b></td>
<td><b>Ejemplo</b></td>
</tr>
<tr>
<td>code</td>
<td>Char</td>
<td>Código del clasificador</td>
<td>5.1.01.05</td>
</tr>
<tr>
<td>name</td>
<td>Char</td>
<td>Descripción del clasificador</td>
<td>Remuneraciones Unificadas</td>
</tr>
<tr>
<td>type</td>
<td>Selection</td>
<td>Tipo: corriente, capital, aplicacion</td>
<td>corriente</td>
</tr>
<tr>
<td>active</td>
<td>Boolean</td>
<td>Activo/Inactivo</td>
<td>True</td>
</tr>
</table>

---

### 8. budget.program (Programas)

**Nombre técnico:** `budget.program`
**Descripción:** Nivel superior de la estructura presupuestaria

#### Campos

<table>
<tr>
<td>code</td>
<td>Código del programa</td>
<td>P01</td>
</tr>
<tr>
<td>name</td>
<td>Nombre del programa</td>
<td>Gestión Aeroportuaria</td>
</tr>
<tr>
<td>sequence</td>
<td>Orden de visualización</td>
<td>1</td>
</tr>
</table>

---

### 9. budget.project (Proyectos)

**Nombre técnico:** `budget.project`
**Descripción:** Nivel intermedio de la estructura presupuestaria

#### Campos

<table>
<tr>
<td>code</td>
<td>Código del proyecto</td>
<td>PRY-001</td>
</tr>
<tr>
<td>name</td>
<td>Nombre del proyecto</td>
<td>Modernización de Infraestructura</td>
</tr>
<tr>
<td>program_id</td>
<td>Programa al que pertenece</td>
<td>P01</td>
</tr>
</table>

---

## Extensiones a Modelos Estándar de Odoo

### account.move (Facturas/Asientos Contables)

**Campos añadidos:**

<code-block lang="python">
budget_certification_id = fields.Many2one(
    'budget.certification',
    string='Certificación Presupuestaria'
)
</code-block>

### account.move.line (Líneas de Asientos)

**Campos añadidos:**

<code-block lang="python">
cp_id = fields.Many2one('budget.certification', 'Certificación')
activity_id = fields.Many2one('account.analytic.account', 'Actividad')
</code-block>

**Métodos sobrescritos:**

<code-block lang="python">
def write(self, vals):
    """
    Al validar una factura, actualiza automáticamente el devengado
    en la cédula presupuestaria
    """
    result = super().write(vals)
    if 'parent_state' in vals and vals['parent_state'] == 'posted':
        self._update_budget_accrued()
    return result
</code-block>

### account.payment (Pagos)

**Campos añadidos:**

<code-block lang="python">
budget_certification_id = fields.Many2one(
    'budget.certification',
    string='Certificación'
)
</code-block>

**Métodos sobrescritos:**

<code-block lang="python">
def action_post(self):
    """
    Al registrar un pago, actualiza el monto pagado
    en la cédula presupuestaria
    """
    result = super().action_post()
    self._update_budget_paid()
    return result
</code-block>

---

## Relaciones Entre Modelos

### Jerarquía Estructural

<code-block>
budget.program (Programa)
    └── budget.project (Proyecto)
            └── account.analytic.account (Actividad)
                    └── budget.classifier (Clasificador)
</code-block>

### Flujo de Datos Presupuestarios

<code-block lang="mermaid">
graph LR
    A[budget.initial] -->|asigna presupuesto| B[account.analytic.account]
    C[budget.redistribution] -->|modifica presupuesto| B
    B -->|recibe certificación| D[budget.certification.activity]
    E[budget.certification] -->|contiene| D
    E -->|compromete| F[account.move.line]
    F -->|devenga| G[budget.query.deluxe]
    H[account.payment] -->|paga| G

    style B fill:#fff3e0
    style E fill:#e8f5e9
    style G fill:#f3e5f5
</code-block>

---

## Índices y Optimización

<tip>
El módulo implementa índices en campos clave para optimizar consultas:

<list>
<li><code>activity_id</code> en budget_certification_activity</li>
<li><code>year</code> en budget_certification</li>
<li><code>state</code> en budget_certification</li>
<li><code>code</code> en account_analytic_account</li>
</list>
</tip>

---

<seealso>
<category ref="related">
<a href="presupuesto-arquitectura.md">Arquitectura y Estructura</a>
<a href="presupuesto-vistas.md">Vistas e Interfaz de Usuario</a>
<a href="presupuesto-flujos.md">Flujos de Trabajo</a>
</category>
</seealso>
