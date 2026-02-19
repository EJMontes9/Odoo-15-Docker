# Seguridad y Permisos

## Introducción

El módulo de Presupuesto Gubernamental implementa un sistema de seguridad multi-nivel que controla el acceso a funcionalidades según roles y responsabilidades de los usuarios.

## Grupos de Seguridad

### Categorías de Seguridad

El módulo define tres categorías principales de seguridad:

<table>
<tr>
<td><b>Categoría</b></td>
<td><b>ID Técnico</b></td>
<td><b>Descripción</b></td>
</tr>
<tr>
<td>Presupuesto</td>
<td>module_category_budget</td>
<td>Permisos generales del módulo de presupuesto</td>
</tr>
<tr>
<td>Garantías</td>
<td>module_category_budget_warranty</td>
<td>Permisos para redistribución de garantías</td>
</tr>
<tr>
<td>Solicitud de Certificación</td>
<td>module_category_request_budget</td>
<td>Permisos para workflow de solicitudes</td>
</tr>
</table>

### Grupos de la Categoría Presupuesto

<tabs>
<tab title="Administrador">
<b>ID Técnico:</b> <code>group_budget_manager</code>

<b>Permisos:</b>
<list>
<li>Acceso total a todas las funcionalidades</li>
<li>Crear, editar y eliminar programas, proyectos y actividades</li>
<li>Aprobar presupuesto inicial</li>
<li>Aprobar redistribuciones</li>
<li>Emitir y cancelar certificaciones</li>
<li>Configurar clasificadores y códigos</li>
<li>Acceso a todos los reportes</li>
</list>

<b>Usuarios Típicos:</b> Director Financiero, Jefe de Presupuesto
</tab>

<tab title="Presupuesto">
<b>ID Técnico:</b> <code>group_budget_presupuesto</code>

<b>Permisos:</b>
<list>
<li>Editar programas, proyectos y actividades en estado waiting/processed</li>
<li>NO puede crear programas, proyectos ni actividades</li>
<li>NO puede modificar campos requeridos</li>
<li>Puede emitir certificaciones</li>
<li>Puede crear redistribuciones</li>
<li>Solo lectura en configuración</li>
</list>

<b>Usuarios Típicos:</b> Analista de Presupuesto
</tab>

<tab title="Planificación">
<b>ID Técnico:</b> <code>group_budget_planificacion</code>

<b>Permisos:</b>
<list>
<li>Control total sobre programas, proyectos y actividades</li>
<li>Crear, editar y eliminar programas/proyectos/actividades</li>
<li>Editar campos requeridos en estos modelos</li>
<li>Solo lectura en el resto de presupuesto</li>
</list>

<b>Usuarios Típicos:</b> Responsable de Planificación POA
</tab>

<tab title="Usuario">
<b>ID Técnico:</b> <code>group_budget_user</code>

<b>Permisos:</b>
<list>
<li>Consulta de información presupuestaria</li>
<li>Crear solicitudes de certificación</li>
<li>Ver el estado de sus solicitudes</li>
<li>Acceso a reportes básicos</li>
</list>

<b>Usuarios Típicos:</b> Jefes de Departamento, Coordinadores
</tab>

<tab title="Lector">
<b>ID Técnico:</b> <code>group_budget_lector</code>

<b>Permisos:</b>
<list>
<li>Solo lectura de toda la información presupuestaria</li>
<li>No puede crear ni modificar registros</li>
<li>Acceso a reportes y consultas</li>
</list>

<b>Usuarios Típicos:</b> Auditores, Consultores
</tab>
</tabs>

### Grupos de Solicitudes de Certificación

<table>
<tr>
<td><b>Grupo</b></td>
<td><b>ID Técnico</b></td>
<td><b>Permisos</b></td>
</tr>
<tr>
<td>Solicitante</td>
<td>group_request_budget_user</td>
<td>Crear y consultar solicitudes propias</td>
</tr>
<tr>
<td>Aprobador</td>
<td>group_request_budget_approver</td>
<td>Revisar y aprobar/rechazar solicitudes</td>
</tr>
<tr>
<td>Administrador</td>
<td>group_request_budget_admin</td>
<td>Gestión completa del workflow de solicitudes</td>
</tr>
</table>

## Matriz de Permisos por Modelo

<table>
<tr>
<td><b>Modelo</b></td>
<td><b>Lector</b></td>
<td><b>Usuario</b></td>
<td><b>Presupuesto</b></td>
<td><b>Planificación</b></td>
<td><b>Administrador</b></td>
</tr>
<tr>
<td>account.analytic.account</td>
<td>Read</td>
<td>Read</td>
<td>Read, Write*</td>
<td>Full</td>
<td>Full</td>
</tr>
<tr>
<td>budget.program</td>
<td>Read</td>
<td>Read</td>
<td>Read</td>
<td>Full</td>
<td>Full</td>
</tr>
<tr>
<td>budget.project</td>
<td>Read</td>
<td>Read</td>
<td>Read</td>
<td>Full</td>
<td>Full</td>
</tr>
<tr>
<td>budget.certification</td>
<td>Read</td>
<td>Read</td>
<td>Full</td>
<td>Read</td>
<td>Full</td>
</tr>
<tr>
<td>budget.initial</td>
<td>Read</td>
<td>Read</td>
<td>Write</td>
<td>Read</td>
<td>Full</td>
</tr>
<tr>
<td>budget.redistribution</td>
<td>Read</td>
<td>Read</td>
<td>Write</td>
<td>Read</td>
<td>Full</td>
</tr>
<tr>
<td>budget.query.deluxe</td>
<td>Read</td>
<td>Read</td>
<td>Read</td>
<td>Read</td>
<td>Read</td>
</tr>
<tr>
<td>budget.classifier</td>
<td>Read</td>
<td>Read</td>
<td>Read</td>
<td>Read</td>
<td>Full</td>
</tr>
</table>

<note>
* Write con limitaciones: solo en estados waiting/processed y sin campos requeridos
</note>

## Reglas de Registro (Record Rules)

Las reglas de registro limitan qué registros puede ver cada usuario:

### Regla: Solicitudes Propias

```xml
<record id="request_budget_own_rule" model="ir.rule">
    <field name="name">Solicitudes Propias</field>
    <field name="model_id" ref="model_request_budget_certification"/>
    <field name="domain_force">[('create_uid', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('group_request_budget_user'))]"/>
</record>
```-->

**Efecto:** Los usuarios con rol "Solicitante" solo ven sus propias solicitudes.

### Regla: Certificaciones por Departamento

```xml
<record id="certification_department_rule" model="ir.rule">
    <field name="name">Certificaciones por Departamento</field>
    <field name="model_id" ref="model_budget_certification"/>
    <field name="domain_force">[
        '|',
        ('responsable_id', '=', user.id),
        ('management_id.user_ids', 'in', [user.id])
    ]</field>
    <field name="groups" eval="[(4, ref('group_budget_user'))]"/>
</record>
```-->

**Efecto:** Los usuarios generales solo ven certificaciones de su departamento o donde son responsables.

### Regla: Todas las Certificaciones (Administradores)

```xml
<record id="certification_manager_rule" model="ir.rule">
    <field name="name">Todas las Certificaciones</field>
    <field name="model_id" ref="model_budget_certification"/>
    <field name="domain_force">[(1, '=', 1)]</field>
    <field name="groups" eval="[
        (4, ref('group_budget_manager')),
        (4, ref('group_budget_presupuesto'))
    ]"/>
</record>
```-->

**Efecto:** Administradores y analistas de presupuesto ven todas las certificaciones.

## Reglas de Acceso a Campos

### Campos Protegidos

Algunos campos solo pueden ser editados por administradores:

<table>
<tr>
<td><b>Modelo</b></td>
<td><b>Campo</b></td>
<td><b>Quién Puede Editar</b></td>
</tr>
<tr>
<td>budget.certification</td>
<td>state</td>
<td>Solo mediante botones de acción</td>
</tr>
<tr>
<td>budget.initial</td>
<td>state</td>
<td>Solo Administrador</td>
</tr>
<tr>
<td>account.analytic.account</td>
<td>code</td>
<td>Solo Administrador y Planificación</td>
</tr>
<tr>
<td>budget.query.deluxe</td>
<td>Todos</td>
<td>Solo lectura (es una vista)</td>
</tr>
</table>

### Implementación en Vistas

```xml
<field name="code" attrs="{'readonly': [
    ('id', '!=', False),
    '|',
    ('planning', 'in', ['active', 'archived']),
    '!'
]}"/>
```-->

## Validaciones de Seguridad en el Código

### Validación de Permisos

```python
def action_approve(self):
    """Aprobar presupuesto inicial - Solo Administradores"""
    if not self.env.user.has_group('budget_gov.group_budget_manager'):
        raise UserError('No tiene permisos para aprobar el presupuesto inicial')

    self.state = 'approved'
```-->

### Validación de Propiedad

```python
@api.constrains('responsable_id')
def _check_responsable(self):
    """Verificar que el usuario puede asignar responsables"""
    for record in self:
        if not self.env.user.has_group('budget_gov.group_budget_manager'):
            if record.responsable_id != self.env.user:
                raise ValidationError(
                    'Solo puede asignarse a sí mismo como responsable'
                )
```-->

## Diagrama de Flujo de Seguridad

<!--```mermaid
flowchart TD
    U[Usuario Intenta Acción] --> A{¿Tiene Grupo<br/>de Seguridad?}
    A -->|No| D1[Acceso Denegado]
    A -->|Sí| B{¿Pasa Regla<br/>de Registro?}
    B -->|No| D1
    B -->|Sí| C{¿Campo<br/>Editable?}
    C -->|No| D2[Campo Solo Lectura]
    C -->|Sí| E{¿Validaciones<br/>de Código?}
    E -->|Falla| D3[Error de Validación]
    E -->|Pasa| F[Acción Permitida]

    style D1 fill:#ffcdd2
    style D2 fill:#ffecb3
    style D3 fill:#ffcdd2
    style F fill:#c8e6c9
```-->

## Mejores Prácticas de Seguridad

<procedure title="Asignación de Permisos">
<step>
<b>Principio de Menor Privilegio</b>
<p>Asignar solo los permisos mínimos necesarios para cada rol</p>
</step>

<step>
<b>Revisión Periódica</b>
<p>Revisar permisos de usuarios trimestralmente</p>
</step>

<step>
<b>Segregación de Funciones</b>
<p>Separar roles de planificación, ejecución y aprobación</p>
</step>

<step>
<b>Auditoría</b>
<p>Activar tracking en modelos críticos para registro de cambios</p>
</step>
</procedure>

<warning>
<b>No otorgar permisos de Administrador indiscriminadamente</b>

El grupo de Administrador tiene acceso total, incluyendo:
<list>
<li>Modificación de presupuesto aprobado</li>
<li>Cancelación de certificaciones adjudicadas</li>
<li>Eliminación de registros históricos</li>
<li>Modificación de configuraciones críticas</li>
</list>
</warning>

## Configuración de Usuarios

### Asignación de Grupos

<procedure title="Asignar Permisos a un Usuario">
<step>Ir a Configuración > Usuarios y Compañías > Usuarios</step>
<step>Seleccionar el usuario</step>
<step>En la pestaña "Derechos de Acceso", buscar la categoría "Presupuesto"</step>
<step>Seleccionar el nivel apropiado: Lector, Usuario, Presupuesto, Planificación o Administrador</step>
<step>Guardar cambios</step>
</procedure>

### Grupos Recomendados por Puesto

<table>
<tr>
<td><b>Puesto</b></td>
<td><b>Grupos Recomendados</b></td>
</tr>
<tr>
<td>Director Financiero</td>
<td>Administrador + Aprobador de Solicitudes</td>
</tr>
<tr>
<td>Jefe de Presupuesto</td>
<td>Administrador</td>
</tr>
<tr>
<td>Analista de Presupuesto</td>
<td>Presupuesto + Admin Solicitudes</td>
</tr>
<tr>
<td>Responsable POA</td>
<td>Planificación + Usuario</td>
</tr>
<tr>
<td>Jefe de Departamento</td>
<td>Usuario + Solicitante</td>
</tr>
<tr>
<td>Coordinador</td>
<td>Usuario + Solicitante</td>
</tr>
<tr>
<td>Auditor</td>
<td>Lector</td>
</tr>
</table>

---

<seealso>
<category ref="related">
<a href="presupuesto-arquitectura.md">Arquitectura y Estructura</a>
<a href="presupuesto-modelos.md">Modelos y Base de Datos</a>
<a href="presupuesto-configuracion.md">Configuración e Instalación</a>
</category>
</seealso>
