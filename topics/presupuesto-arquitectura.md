# Arquitectura y Estructura del Módulo Presupuesto {switcher-key="Presupuesto v1.0"}

<show-structure for="chapter,procedure" depth="2"/>

## Introducción

El módulo de Presupuesto Gubernamental sigue la arquitectura MVC (Modelo-Vista-Controlador) de Odoo, con una organización clara de responsabilidades entre las capas de datos, lógica de negocio y presentación.

## Diagrama de Arquitectura de Capas

<code-block lang="mermaid">
graph TB
    subgraph "Capa de Presentación"
        V1[Vistas XML/QWeb]
        V2[Wizards]
        V3[Reportes]
        V4[JavaScript/Assets]
    end

    subgraph "Capa de Lógica de Negocio"
        M1[Modelos de Dominio]
        M2[Métodos de Negocio]
        M3[Validaciones]
        M4[Workflows]
    end

    subgraph "Capa de Datos"
        D1[Tablas PostgreSQL]
        D2[Vistas SQL]
        D3[ORM Odoo]
        D4[Reglas de Acceso]
    end

    subgraph "Integraciones"
        I1[Módulo Contabilidad]
        I2[Módulo Planificación]
        I3[Módulo Contratos]
        I4[API Externa]
    end

    V1 --> M1
    V2 --> M2
    V3 --> M1
    V4 --> M1

    M1 --> D1
    M2 --> D3
    M3 --> D1
    M4 --> D3

    D3 --> D1
    D3 --> D2
    D4 --> D1

    M1 -.-> I1
    M1 -.-> I2
    M1 -.-> I3
    M2 -.-> I4

    style V1 fill:#e3f2fd
    style M1 fill:#fff3e0
    style D1 fill:#f3e5f5
    style I1 fill:#e8f5e9
</code-block>

## Estructura de Directorios

</code-block>
budget_gov/
├── __init__.py                 # Inicialización del módulo
├── __manifest__.py             # Metadatos y dependencias
│
├── data/                       # Datos iniciales y de demostración
│   ├── budget_type_code_data.xml
│   ├── cp_type_data.xml
│   ├── budget_workgroup_data.xml
│   ├── lote_sequence.xml
│   ├── budget_codes_data.xml
│   ├── request_budget_template.xml
│   └── request_budget_certification.xml
│
├── models/                     # Modelos de datos (Capa de Negocio)
│   ├── __init__.py
│   ├── account_move.py         # Extensión de facturas/asientos
│   ├── account_move_line.py    # Líneas de asientos contables
│   ├── account_payment.py      # Extensión de pagos
│   ├── analytic_account.py     # Actividades presupuestarias
│   ├── analytic_account_line.py
│   ├── budget_certification.py # Certificaciones presupuestarias
│   ├── budget_certification_activity.py
│   ├── budget_classifier.py    # Clasificadores presupuestarios
│   ├── budget_codes.py
│   ├── budget_inicial.py       # Presupuesto inicial anual
│   ├── budget_redistribution.py # Redistribuciones
│   ├── budget_program.py       # Programas
│   ├── budget_project.py       # Proyectos
│   ├── budget_query_deluxe.py  # Vista SQL: Cédula presupuestaria
│   ├── budget_management.py
│   ├── budget_activity_sheet.py
│   └── ... (30+ archivos de modelos)
│
├── views/                      # Vistas de interfaz de usuario
│   ├── menu.xml                # Estructura de menús
│   ├── analytic_account_views.xml
│   ├── budget_certification_views.xml
│   ├── budget_initial_views.xml
│   ├── budget_redistribution_views.xml
│   ├── budget_query_deluxe_views.xml
│   ├── budget_classifier_views.xml
│   ├── budget_program_views.xml
│   ├── budget_project_views.xml
│   └── ... (25+ archivos de vistas)
│
├── wizard/                     # Asistentes y reportes interactivos
│   ├── __init__.py
│   ├── wizard_export_query_deluxe.xml
│   ├── wizard_report_payment_activity.xml
│   ├── wizard_report_activity_certifications.xml
│   ├── wizard_report_comprehensive_release.xml
│   ├── wizard_modification_report.xml
│   └── ... (10+ wizards)
│
├── report/                     # Reportes PDF/QWeb
│   ├── budget_certification.xml
│   └── reports.xml
│
├── security/                   # Seguridad y permisos
│   ├── security.xml            # Grupos de seguridad
│   ├── ir.model.access.csv     # Reglas de acceso a modelos
│   └── budget_record_rules.xml # Reglas de registro
│
└── static/                     # Recursos estáticos
    ├── description/
    │   └── icon.png
    ├── img/
    └── src/
        └── js/
            └── file_name.js    # JavaScript personalizado
</code-block>

## Patrones de Diseño Utilizados

### 1. Patrón MVC (Modelo-Vista-Controlador)

<deflist>
<def title="Modelo (Model)">
Representado por las clases Python en <code>models/</code>. Contienen la lógica de negocio y la definición de datos.
</def>

<def title="Vista (View)">
Archivos XML en <code>views/</code> que definen la interfaz de usuario (tree, form, search, pivot, graph).
</def>

<def title="Controlador (Controller)">
Métodos en los modelos que procesan acciones del usuario y coordinan entre modelo y vista.
</def>
</deflist>

### 2. Patrón ORM (Object-Relational Mapping)

Odoo proporciona un ORM completo que abstrae las operaciones de base de datos:

```python
# Ejemplo de uso del ORM
budget = self.env['budget.initial'].create({
    'name': 'Presupuesto 2024',
    'year': 2024,
    'amount': 1000000.00
})

certifications = self.env['budget.certification'].search([
    ('state', '=', 'approved'),
    ('year', '=', 2024)
])
</code-block>

### 3. Patrón Wizard para Procesos Complejos

Los wizards en `wizard/` implementan procesos multi-paso:

```python
class WizardExportQueryDeluxe(models.TransientModel):
    _name = 'wizard.export.query.deluxe'
    _description = 'Asistente para exportar Cédula Presupuestaria'

    # Campos del wizard
    year = fields.Integer('Año')

    # Método de acción
    def action_export(self):
        # Lógica de exportación
        pass
</code-block>

### 4. Patrón Herencia para Extensibilidad

Odoo permite tres tipos de herencia:

<tabs>
<tab title="Herencia Clásica (_inherit)">
<code-block lang="python">
class AccountMove(models.Model):
    _inherit = 'account.move'

    # Añade campos y métodos al modelo existente
    budget_certification_id = fields.Many2one('budget.certification')
</code-block>
</tab>

<tab title="Herencia por Delegación (_inherits)">
<code-block lang="python">
# No usado en este módulo
</code-block>
</tab>

<tab title="Herencia Abstracta (_abstract)">
<code-block lang="python">
# No usado en este módulo
</code-block>
</tab>
</tabs>

## Diagrama de Componentes

<code-block lang="mermaid">
graph TB
    subgraph "Módulo Presupuesto Gubernamental"
        subgraph "Configuración"
            C1[Clasificadores]
            C2[Programas]
            C3[Proyectos]
            C4[Códigos PAC]
            C5[Fuentes]
        end

        subgraph "Planificación"
            P1[Actividades]
            P2[Presupuesto Inicial]
            P3[Hojas de Actividad]
        end

        subgraph "Ejecución"
            E1[Solicitudes]
            E2[Certificaciones]
            E3[Redistribuciones]
        end

        subgraph "Control"
            CO1[Query Deluxe]
            CO2[Reportes]
        end

        subgraph "Integración"
            I1[Account Move]
            I2[Account Payment]
        end
    end

    C1 --> P1
    C2 --> P1
    C3 --> P1
    C4 --> P1
    C5 --> P1

    P1 --> P2
    P2 --> E2
    P1 --> E1
    E1 --> E2
    E2 --> E3

    P2 --> CO1
    E2 --> CO1
    E3 --> CO1

    CO1 --> CO2

    E2 --> I1
    I1 --> I2

    style C1 fill:#e1f5fe
    style P1 fill:#fff9c4
    style E2 fill:#c8e6c9
    style CO1 fill:#f8bbd0
</code-block>

## Integración con Otros Módulos

### Módulo de Contabilidad (account_ec)

<procedure title="Flujo de Integración Contable">
<step>
<b>Certificación Presupuestaria</b>
<p>Se crea una certificación que reserva presupuesto</p>
</step>

<step>
<b>Creación de Factura/Asiento Contable</b>
<p>Se registra un gasto en el módulo de contabilidad vinculado a la certificación</p>
</step>

<step>
<b>Actualización Automática de Devengado</b>
<p>Al validar la factura, se actualiza automáticamente el monto devengado en la cédula presupuestaria</p>
</step>

<step>
<b>Registro de Pago</b>
<p>Al registrar el pago, se actualiza el monto pagado</p>
</step>
</procedure>

<code-block lang="mermaid">
sequenceDiagram
    participant U as Usuario
    participant BC as Budget Certification
    participant AM as Account Move
    participant AP as Account Payment
    participant QD as Query Deluxe

    U->>BC: Crear Certificación
    BC->>BC: Validar disponibilidad
    BC->>QD: Actualizar Comprometido

    U->>AM: Crear Factura
    AM->>BC: Vincular a Certificación
    AM->>AM: Validar Factura
    AM->>QD: Actualizar Devengado

    U->>AP: Registrar Pago
    AP->>AM: Vincular a Factura
    AP->>QD: Actualizar Pagado
</code-block>

### Módulo de Planificación (planification)

Las actividades presupuestarias (`account.analytic.account`) se crean desde el módulo de planificación POA y se integran con el presupuesto.

### Módulo de Contratos (contratos)

Las certificaciones presupuestarias son requeridas antes de crear contratos o procesos de contratación.

## Arquitectura de Base de Datos

### Tablas Principales

<table>
<tr>
<td><b>Tabla</b></td>
<td><b>Descripción</b></td>
<td><b>Tipo</b></td>
</tr>
<tr>
<td>account_analytic_account</td>
<td>Actividades presupuestarias</td>
<td>Tabla</td>
</tr>
<tr>
<td>budget_initial</td>
<td>Presupuesto inicial por año</td>
<td>Tabla</td>
</tr>
<tr>
<td>detail_budget_initial</td>
<td>Detalle del presupuesto inicial</td>
<td>Tabla</td>
</tr>
<tr>
<td>budget_certification</td>
<td>Certificaciones presupuestarias</td>
<td>Tabla</td>
</tr>
<tr>
<td>budget_certification_activity</td>
<td>Detalle de certificaciones por actividad</td>
<td>Tabla</td>
</tr>
<tr>
<td>budget_redistribution</td>
<td>Redistribuciones presupuestarias</td>
<td>Tabla</td>
</tr>
<tr>
<td>budget_query_deluxe</td>
<td>Cédula presupuestaria consolidada</td>
<td>Vista SQL</td>
</tr>
<tr>
<td>budget_classifier</td>
<td>Clasificadores presupuestarios</td>
<td>Tabla</td>
</tr>
<tr>
<td>budget_program</td>
<td>Programas presupuestarios</td>
<td>Tabla</td>
</tr>
<tr>
<td>budget_project</td>
<td>Proyectos presupuestarios</td>
<td>Tabla</td>
</tr>
</table>

### Vistas SQL Materializadas

El módulo utiliza **vistas SQL** para optimizar consultas complejas:

#### budget_query_deluxe

Esta vista consolida información de múltiples tablas para mostrar la cédula presupuestaria:

```sql
CREATE OR REPLACE VIEW budget_query_deluxe AS
SELECT
    -- Identificación única
    ROW_NUMBER() OVER () as id,

    -- Estructura presupuestaria
    aa.id as activity_id,
    aa.code as activity_code,
    aa.name as activity_name,
    bp.name as program_name,
    bpr.name as project_name,
    bc.name as classifier_name,

    -- Montos presupuestarios
    COALESCE(bi.amount, 0) as initial_amount,
    COALESCE(redistribution.amount, 0) as redistribution_amount,
    COALESCE(bi.amount, 0) + COALESCE(redistribution.amount, 0) as codified_amount,
    COALESCE(cert.amount, 0) as committed_amount,
    COALESCE(invoiced.amount, 0) as accrued_amount,
    COALESCE(paid.amount, 0) as paid_amount,

    -- Disponible
    (COALESCE(bi.amount, 0) + COALESCE(redistribution.amount, 0)) -
    COALESCE(cert.amount, 0) as available_amount

FROM account_analytic_account aa
LEFT JOIN budget_program bp ON aa.program_id = bp.id
LEFT JOIN budget_project bpr ON aa.project_id = bpr.id
LEFT JOIN budget_classifier bc ON aa.classifier_id = bc.id
-- ... joins adicionales para cálculos
</code-block>

<note>
La vista SQL se regenera automáticamente cuando se instala o actualiza el módulo.
</note>

## Capas de Seguridad

<code-block lang="mermaid">
graph TB
    U[Usuario] --> G{Grupo de Seguridad}
    G -->|Administrador| A1[Acceso Total]
    G -->|Presupuesto| A2[Edición Limitada]
    G -->|Usuario| A3[Consulta y Solicitudes]
    G -->|Lector| A4[Solo Lectura]

    A1 --> R1[Record Rules]
    A2 --> R1
    A3 --> R1
    A4 --> R1

    R1 --> M[Modelo/Registro]

    style G fill:#fff3e0
    style R1 fill:#f3e5f5
    style M fill:#e8f5e9
</code-block>

Las reglas de seguridad se implementan en tres niveles:

1. **Grupos de seguridad** (security.xml)
2. **Reglas de acceso a modelos** (ir.model.access.csv)
3. **Reglas de registro** (budget_record_rules.xml)

<seealso>
<category ref="related">
<a href="presupuesto-overview.md">Visión General</a>
<a href="presupuesto-modelos.md">Modelos y Base de Datos</a>
<a href="presupuesto-seguridad.md">Seguridad y Permisos</a>
</category>
</seealso>
