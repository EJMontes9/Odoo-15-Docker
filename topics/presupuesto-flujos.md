# Flujos de Trabajo

## Introducción

Este documento describe los flujos de trabajo principales del módulo de Presupuesto Gubernamental, detallando los procesos desde la planificación hasta la ejecución presupuestaria.

## Ciclo de Vida del Presupuesto Anual

<!--```mermaid
stateDiagram-v2
    [*] --> Configuración: Inicio de Año
    Configuración --> Planificación: Estructura Creada
    Planificación --> PresupuestoInicial: Actividades Definidas
    PresupuestoInicial --> Ejecución: Presupuesto Aprobado
    Ejecución --> Ejecución: Durante el Año
    Ejecución --> Cierre: Fin de Año
    Cierre --> [*]

    state Configuración {
        [*] --> Programas
        Programas --> Proyectos
        Proyectos --> Clasificadores
    }

    state Planificación {
        [*] --> Actividades
        Actividades --> HojasActividad
    }

    state PresupuestoInicial {
        [*] --> Borrador
        Borrador --> Aprobado
    }

    state Ejecución {
        [*] --> Certificaciones
        Certificaciones --> Devengados
        Devengados --> Pagos
        Certificaciones --> Redistribuciones
        Redistribuciones --> Certificaciones
    }
```-->

## Flujo 1: Creación de Presupuesto Inicial

<procedure title="Elaboración del Presupuesto Inicial Anual">
<step>
<b>Preparación</b>
<p>El Jefe de Presupuesto crea un nuevo registro de Presupuesto Inicial</p>
<code-block>
Presupuesto > Planificación > Presupuesto Inicial > Crear
</code-block>
</step>

<step>
<b>Ingreso de Datos</b>
<p>Se añaden líneas de detalle por cada actividad y clasificador:</p>
<list>
<li>Seleccionar actividad presupuestaria</li>
<li>Seleccionar clasificador</li>
<li>Ingresar monto asignado</li>
</list>
</step>

<step>
<b>Revisión</b>
<p>El sistema calcula automáticamente el total del presupuesto</p>
<note>El presupuesto debe cuadrar con la asignación global de la institución</note>
</step>

<step>
<b>Aprobación</b>
<p>El Administrador revisa y aprueba el presupuesto inicial</p>
<code-block lang="python">
# Al aprobar, el estado cambia de 'draft' a 'approved'
self.state = 'approved'
self.approval_date = fields.Date.today()
</code-block>
</step>

<step>
<b>Resultado</b>
<p>El presupuesto queda disponible para la ejecución del año fiscal</p>
</step>
</procedure>

### Diagrama de Secuencia

<!--```mermaid
sequenceDiagram
    actor JP as Jefe Presupuesto
    participant BI as budget.initial
    participant AA as Actividades
    actor ADM as Administrador

    JP->>BI: Crear Presupuesto Inicial
    BI->>BI: Estado: draft
    loop Por cada actividad
        JP->>BI: Agregar línea de detalle
        BI->>AA: Validar actividad existe
        AA-->>BI: OK
        BI->>BI: Calcular total
    end
    JP->>BI: Enviar para aprobación
    ADM->>BI: Revisar presupuesto
    ADM->>BI: Aprobar
    BI->>BI: Estado: approved
    BI-->>AA: Actualizar presupuesto inicial
```-->

---

## Flujo 2: Emisión de Certificación Presupuestaria

<!--```mermaid
stateDiagram-v2
    [*] --> Waiting: Crear Certificación
    Waiting --> Admitted: Admitir (validar disponibilidad)
    Waiting --> Canceled: Cancelar
    Admitted --> Awarded: Adjudicar a proveedor
    Admitted --> Canceled: Cancelar
    Awarded --> [*]: Proceso de Contratación
    Canceled --> [*]

    note right of Admitted
        Valida que haya presupuesto
        disponible en las actividades
    end note

    note right of Awarded
        Se vincula al proceso
        de contratación
    end note
```-->

<procedure title="Proceso de Certificación Presupuestaria">
<step>
<b>Solicitud</b>
<p>El usuario (Jefe de Departamento) crea una solicitud de certificación o el analista crea directamente la certificación</p>
</step>

<step>
<b>Creación de Certificación</b>
<p>El Analista de Presupuesto crea la certificación:</p>
<list>
<li>Fecha y descripción</li>
<li>Añadir actividades involucradas</li>
<li>Ingresar monto por actividad</li>
</list>
</step>

<step>
<b>Validación de Disponibilidad</b>
<code-block lang="python">
def action_admit(self):
    """Admite la certificación validando disponibilidad"""
    for activity_line in self.activities_ids:
        available = activity_line.activity_id.get_budget_available(self.year)
        if activity_line.amount > available:
            raise UserError(
                f'Presupuesto insuficiente en {activity_line.activity_id.name}'
                f'\nDisponible: ${available:.2f}'
                f'\nSolicitado: ${activity_line.amount:.2f}'
            )
    self.state = 'admitted'
    self.lote = self._generate_lote_number()
</code-block>
</step>

<step>
<b>Admisión</b>
<p>Si hay disponibilidad, se admite la certificación y se genera el número de lote</p>
</step>

<step>
<b>Proceso de Contratación</b>
<p>La certificación admitida habilita el proceso de contratación pública</p>
</step>

<step>
<b>Adjudicación</b>
<p>Una vez seleccionado el proveedor, se adjudica la certificación</p>
</step>
</procedure>

### Diagrama de Secuencia - Certificación

<!--```mermaid
sequenceDiagram
    actor U as Usuario
    participant BC as budget.certification
    participant BCA as budget.cert.activity
    participant AA as Actividad
    participant QD as Query Deluxe

    U->>BC: Crear Certificación
    BC->>BC: Estado: waiting
    U->>BCA: Agregar actividad 1 ($5,000)
    U->>BCA: Agregar actividad 2 ($3,000)
    BC->>BC: Calcular total: $8,000

    U->>BC: Admitir
    BC->>AA: Validar disponible Act 1
    AA-->>BC: Disponible: $10,000 ✓
    BC->>AA: Validar disponible Act 2
    AA-->>BC: Disponible: $4,000 ✓
    BC->>BC: Estado: admitted
    BC->>BC: Generar lote: CP-2024-001
    BC->>QD: Actualizar comprometido

    U->>BC: Adjudicar a Proveedor X
    BC->>BC: Estado: awarded
```-->

---

## Flujo 3: Redistribución Presupuestaria

<procedure title="Proceso de Redistribución">
<step>
<b>Identificación de Necesidad</b>
<p>Durante el año, se identifica que una actividad requiere más presupuesto</p>
</step>

<step>
<b>Creación de Redistribución</b>
<code-block>
Presupuesto > Ejecución > Redistribuciones > Crear
</code-block>
</step>

<step>
<b>Líneas de Disminución</b>
<p>Especificar actividades que cederán presupuesto (montos negativos)</p>
</step>

<step>
<b>Líneas de Aumento</b>
<p>Especificar actividades que recibirán presupuesto (montos positivos)</p>
</step>

<step>
<b>Validación de Balance</b>
<code-block lang="python">
def validate_balance(self):
    """Valida que aumentos = disminuciones"""
    total_increase = sum(line.amount for line in self.line_ids if line.amount > 0)
    total_decrease = sum(abs(line.amount) for line in self.line_ids if line.amount < 0)

    if round(total_increase, 2) != round(total_decrease, 2):
        raise UserError(
            f'La redistribución no está balanceada:\n'
            f'Aumentos: ${total_increase:.2f}\n'
            f'Disminuciones: ${total_decrease:.2f}'
        )
</code-block>
</step>

<step>
<b>Validación de Tipo de Gasto</b>
<note>No se permite mover presupuesto entre gastos corrientes y de capital</note>
</step>

<step>
<b>Aprobación</b>
<p>El Administrador aprueba la redistribución y se actualizan los presupuestos</p>
</step>
</procedure>

### Restricciones de Redistribución

<!--```mermaid
graph TB
    R[Redistribución] --> V1{¿Balance 0?}
    V1 -->|No| E1[Error: No balanceada]
    V1 -->|Sí| V2{¿Mismo tipo<br/>de gasto?}
    V2 -->|No| E2[Error: No se puede<br/>mover entre<br/>corriente y capital]
    V2 -->|Sí| V3{¿Hay disponible<br/>en disminuciones?}
    V3 -->|No| E3[Error: Presupuesto<br/>insuficiente]
    V3 -->|Sí| OK[Aprobada]

    style E1 fill:#ffcdd2
    style E2 fill:#ffcdd2
    style E3 fill:#ffcdd2
    style OK fill:#c8e6c9
```-->

---

## Flujo 4: Ejecución Presupuestaria (Devengado y Pago)

<!--```mermaid
sequenceDiagram
    participant BC as Certificación
    participant AM as Factura/Asiento
    participant AP as Pago
    participant QD as Cédula Presupuestaria

    Note over BC: Certificación Adjudicada
    BC->>QD: Comprometido +$10,000

    Note over AM: Se recibe factura del proveedor
    AM->>AM: Crear factura
    AM->>BC: Vincular a certificación
    AM->>AM: Validar factura
    AM->>QD: Devengado +$10,000
    QD->>QD: Actualizar estado

    Note over AP: Se autoriza el pago
    AP->>AP: Registrar pago
    AP->>AM: Vincular a factura
    AP->>QD: Pagado +$10,000
    QD->>QD: Actualizar estado
```-->

<procedure title="Registro de Devengado y Pago">
<step>
<b>Recepción de Factura</b>
<p>Se crea una factura de proveedor en el módulo de contabilidad</p>
</step>

<step>
<b>Vinculación a Certificación</b>
<p>Se selecciona la certificación presupuestaria correspondiente</p>
</step>

<step>
<b>Validación de Factura</b>
<p>Al validar la factura, se dispara automáticamente:</p>
<code-block lang="python">
def action_post(self):
    res = super().action_post()
    if self.budget_certification_id:
        self._update_budget_accrued()
    return res
</code-block>
</step>

<step>
<b>Actualización de Devengado</b>
<p>La cédula presupuestaria actualiza el campo "devengado"</p>
</step>

<step>
<b>Registro de Pago</b>
<p>Al registrar el pago, se actualiza el campo "pagado"</p>
</step>
</procedure>

---

## Flujo 5: Consulta de Cédula Presupuestaria

<!--```mermaid
graph LR
    U[Usuario] -->|Accede| QD[Cédula Presupuestaria]
    QD --> F[Aplica Filtros]
    F --> F1[Por Año]
    F --> F2[Por Programa]
    F --> F3[Por Proyecto]
    F --> F4[Por Actividad]
    F --> V[Visualiza]
    V --> V1[Vista Tree]
    V --> V2[Vista Pivot]
    V --> V3[Vista Graph]
    V --> E[Exportar Excel]

    style QD fill:#f3e5f5
    style E fill:#c8e6c9
```-->

<procedure title="Consultar Estado Presupuestario">
<step>Ir a Presupuesto > Reportes y Consultas > Cédula Presupuestaria</step>
<step>Aplicar filtros necesarios (año, programa, proyecto)</step>
<step>Visualizar información en tiempo real:
<list>
<li>Presupuesto Codificado</li>
<li>Comprometido (certificaciones)</li>
<li>Devengado (facturas)</li>
<li>Pagado</li>
<li>Disponible</li>
</list>
</step>
<step>Opcionalmente, cambiar a vista Pivot o Graph para análisis</step>
<step>Exportar a Excel si es necesario usando el wizard especializado</step>
</procedure>

---

## Flujo 6: Solicitud y Aprobación de Certificación

<!--```mermaid
stateDiagram-v2
    [*] --> Borrador: Crear Solicitud
    Borrador --> EnRevisión: Enviar
    EnRevisión --> Aprobada: Aprobar
    EnRevisión --> Rechazada: Rechazar
    EnRevisión --> Borrador: Devolver para corrección
    Rechazada --> [*]
    Aprobada --> Certificación: Generar Certificación
    Certificación --> [*]
```-->

<procedure title="Workflow de Solicitud">
<step>
<b>Creación por Usuario</b>
<p>Jefe de Departamento crea solicitud de certificación</p>
</step>

<step>
<b>Envío para Revisión</b>
<p>Notificación automática al Aprobador</p>
</step>

<step>
<b>Revisión</b>
<p>El Aprobador revisa la solicitud y puede:</p>
<list>
<li>Aprobar: Genera certificación automáticamente</li>
<li>Rechazar: Termina el proceso con justificación</li>
<li>Devolver: Regresa al solicitante para correcciones</li>
</list>
</step>

<step>
<b>Generación de Certificación</b>
<p>Si se aprueba, se crea automáticamente la certificación presupuestaria</p>
</step>
</procedure>

---

## Flujo 7: Cierre de Año Fiscal

<procedure title="Proceso de Cierre de Año">
<step>
<b>Revisión Final</b>
<p>Verificar que todos los procesos del año estén completos</p>
</step>

<step>
<b>Archivar Actividades</b>
<p>Archivar actividades que no continuarán en el siguiente año</p>
</step>

<step>
<b>Generar Reportes Finales</b>
<list>
<li>Ejecución Presupuestaria Anual</li>
<li>Cédula Presupuestaria Consolidada</li>
<li>Certificaciones Emitidas</li>
<li>Redistribuciones Realizadas</li>
</list>
</step>

<step>
<b>Wizard de Cierre de Año</b>
<p>Ejecutar wizard especializado que:</p>
<code-block>
Presupuesto > Herramientas > Cierre de Año Fiscal
</code-block>
<list>
<li>Valida que no hayan procesos pendientes</li>
<li>Genera saldos de cierre</li>
<li>Prepara estructura para nuevo año</li>
</list>
</step>

<step>
<b>Inicio de Nuevo Año</b>
<p>Crear nuevo Presupuesto Inicial para el año siguiente</p>
</step>
</procedure>

---

<seealso>
<category ref="related">
<a href="presupuesto-modelos.md">Modelos y Base de Datos</a>
<a href="presupuesto-vistas.md">Vistas e Interfaz de Usuario</a>
<a href="presupuesto-casos-uso.md">Casos de Uso Prácticos</a>
</category>
</seealso>
