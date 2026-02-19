# Módulo Presupuesto Gubernamental - Visión General

<show-structure for="chapter,procedure" depth="2"/>

<tldr>
<p><b>Versión:</b> 15.0.1</p>
<p><b>Propósito:</b> Gestión integral de presupuestos para instituciones públicas</p>
<p><b>Autor:</b> Manexware S.A.</p>
<p><b>Estado:</b> Producción</p>
</tldr>

## Descripción General

El módulo **Presupuesto Gubernamental** (budget_gov) es un sistema completo para la administración y control de presupuestos en instituciones del sector público. Diseñado específicamente para cumplir con las normativas de presupuesto gubernamental ecuatoriano, este módulo permite la gestión del ciclo de vida completo del presupuesto: desde la planificación inicial hasta la ejecución y control presupuestario.

## Propósito y Alcance

Este módulo ha sido desarrollado para:

- **Planificación Presupuestaria**: Creación y gestión del presupuesto inicial anual
- **Control Presupuestario**: Certificaciones presupuestarias para comprometer recursos
- **Modificaciones**: Redistribuciones y reformas presupuestarias
- **Seguimiento**: Consultas en tiempo real del estado de ejecución presupuestaria
- **Reportes**: Generación de reportes presupuestarios requeridos por entes de control
- **Cumplimiento Normativo**: Adherencia a las normas de presupuesto público ecuatoriano

## Características Principales

<deflist>
<def title="Presupuesto Inicial">
Registro y aprobación del presupuesto anual por programa, proyecto, actividad y clasificador presupuestario.
</def>

<def title="Certificaciones Presupuestarias">
Generación de certificaciones para comprometer presupuesto antes de realizar contrataciones o compromisos de pago.
</def>

<def title="Redistribuciones">
Movimientos presupuestarios entre diferentes partidas, respetando las restricciones normativas (corriente/capital).
</def>

<def title="Cédula Presupuestaria (Query Deluxe)">
Vista consolidada en tiempo real del estado presupuestario con:
- Presupuesto Codificado
- Compromisos (Certificaciones)
- Devengado
- Pagado
- Disponible
- Exportación a Excel con formato oficial
</def>

<def title="Integración Contable">
Sincronización automática con el módulo de contabilidad para registrar devengados y pagos en la ejecución presupuestaria.
</def>

<def title="Gestión de Actividades">
Control de actividades presupuestarias con estados de planificación, activo y archivado.
</def>

<def title="Solicitudes de Certificación">
Flujo de aprobación para solicitudes de certificación presupuestaria con workflow de estados.
</def>

<def title="Reportes Especializados">
- Cédula Presupuestaria
- Certificaciones por Actividad
- Liberaciones Individuales
- Liberaciones Comprensivas
- Pagos por Actividad
- Actividades Codificadas
- Comprometidos
- Modificaciones Presupuestarias
</def>
</deflist>

## Tecnologías Utilizadas

<table>
<tr>
<td>Framework</td>
<td>Odoo 15.0</td>
</tr>
<tr>
<td>Lenguaje</td>
<td>Python 3.8+</td>
</tr>
<tr>
<td>Base de Datos</td>
<td>PostgreSQL (con vistas SQL)</td>
</tr>
<tr>
<td>Frontend</td>
<td>XML/QWeb, JavaScript (Odoo Web Framework)</td>
</tr>
<tr>
<td>Reportes</td>
<td>QWeb Reports, XlsxWriter (Excel)</td>
</tr>
</table>

## Dependencias

El módulo depende de los siguientes módulos de Odoo:

- **mail**: Funcionalidad de mensajería y seguimiento
- **account_ec**: Contabilidad ecuatoriana
- **account_report_ec**: Reportes contables para Ecuador
- **account_einvoice**: Facturación electrónica
- **import_move**: Importación de movimientos contables

<warning>
Todas las dependencias deben estar instaladas y configuradas correctamente antes de instalar el módulo de presupuesto.
</warning>

## Versión y Compatibilidad

<table>
<tr>
<td>Versión del Módulo</td>
<td>15.0.1</td>
</tr>
<tr>
<td>Versión de Odoo</td>
<td>15.0</td>
</tr>
<tr>
<td>Compatibilidad PostgreSQL</td>
<td>10.0+</td>
</tr>
<tr>
<td>Licencia</td>
<td>LGPL-3</td>
</tr>
</table>

## Mapa Conceptual del Módulo

<code-block lang="mermaid">
mindmap
  root((Presupuesto<br/>Gubernamental))
    Configuración
      Programas
      Proyectos
      Clasificadores
      Fuentes de Financiamiento
      Ubicaciones
      Grupos de Trabajo
    Planificación
      Actividades
      Presupuesto Inicial
      Hojas de Actividad
    Ejecución
      Certificaciones
        Solicitud de Certificación
        Aprobación
        Emisión
      Redistribuciones
        Aumentos
        Disminuciones
        Validación
    Control
      Cédula Presupuestaria
        Codificado
        Comprometido
        Devengado
        Pagado
        Disponible
      Reportes
        Por Actividad
        Por Clasificador
        Modificaciones
    Integración
      Contabilidad
        Devengados
        Pagos
      Compras/Contratos
        Certificaciones
</code-block>

## Flujo General del Módulo

<code-block lang="mermaid">
graph TB
    A[Configuración Inicial] --> B[Creación de Actividades]
    B --> C[Presupuesto Inicial]
    C --> D{Durante el Año Fiscal}
    D --> E[Solicitud de Certificación]
    E --> F{Aprobación}
    F -->|Aprobado| G[Emisión de Certificación]
    F -->|Rechazado| E
    G --> H[Proceso de Contratación/Compra]
    H --> I[Registro Contable]
    I --> J[Devengado]
    J --> K[Pago]
    D --> L[Redistribuciones]
    L --> C
    K --> M[Cédula Presupuestaria]
    J --> M
    G --> M

    style A fill:#e1f5ff
    style C fill:#fff4e1
    style G fill:#e8f5e9
    style M fill:#f3e5f5
</code-block>

## Principales Usuarios del Módulo

<table>
<tr>
<td><b>Rol</b></td>
<td><b>Responsabilidades</b></td>
<td><b>Grupo de Seguridad</b></td>
</tr>
<tr>
<td>Administrador de Presupuesto</td>
<td>Configuración completa del módulo, creación de programas, proyectos, actividades</td>
<td>group_budget_manager</td>
</tr>
<tr>
<td>Analista de Presupuesto</td>
<td>Gestión de presupuesto inicial, redistribuciones, emisión de certificaciones</td>
<td>group_budget_presupuesto</td>
</tr>
<tr>
<td>Usuario General</td>
<td>Consulta de información presupuestaria, solicitudes de certificación</td>
<td>group_budget_user</td>
</tr>
<tr>
<td>Lector</td>
<td>Solo lectura de información presupuestaria</td>
<td>group_budget_lector</td>
</tr>
<tr>
<td>Planificación</td>
<td>Gestión de programas, proyectos y actividades</td>
<td>group_budget_planificacion</td>
</tr>
</table>

## Beneficios Clave

<list>
<li><b>Transparencia</b>: Visibilidad completa del estado presupuestario en tiempo real</li>
<li><b>Control</b>: Prevención de sobregiros mediante certificaciones obligatorias</li>
<li><b>Trazabilidad</b>: Registro completo de todas las operaciones presupuestarias</li>
<li><b>Cumplimiento</b>: Adherencia a normativas de presupuesto público</li>
<li><b>Eficiencia</b>: Automatización de cálculos y reportes</li>
<li><b>Integración</b>: Sincronización automática con contabilidad y otros módulos</li>
<li><b>Reporting</b>: Generación rápida de reportes para entes de control</li>
</list>

## Limitaciones Conocidas

<warning>
<list>
<li>Las redistribuciones no pueden mover presupuesto entre gastos corrientes y gastos de capital (restricción normativa)</li>
<li>Una certificación no puede exceder el presupuesto disponible de una actividad</li>
<li>Las actividades archivadas no pueden recibir nuevas certificaciones</li>
<li>El presupuesto inicial solo se puede modificar mediante redistribuciones formales</li>
</list>
</warning>

## Próximos Pasos

<procedure title="Para comenzar a usar el módulo">
<step>Revisar la <a href="presupuesto-arquitectura.md">Arquitectura y Estructura</a> del módulo</step>
<step>Comprender los <a href="presupuesto-modelos.md">Modelos y Base de Datos</a></step>
<step>Estudiar los <a href="presupuesto-flujos.md">Flujos de Trabajo</a> principales</step>
<step>Seguir la guía de <a href="presupuesto-configuracion.md">Configuración e Instalación</a></step>
<step>Revisar los <a href="presupuesto-casos-uso.md">Casos de Uso</a> prácticos</step>
</procedure>

<seealso>
<category ref="related">
<a href="presupuesto-arquitectura.md">Arquitectura y Estructura</a>
<a href="presupuesto-modelos.md">Modelos y Base de Datos</a>
<a href="presupuesto-flujos.md">Flujos de Trabajo</a>
</category>
</seealso>
