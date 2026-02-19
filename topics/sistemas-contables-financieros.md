# Sistemas contables y financieros en Odoo (AAG)

Este documento enumera los módulos/sistemas contables y financieros utilizados en la instalación de Odoo y describe, a nivel funcional, los procesos que se ejecutan en cada uno de ellos.

## Contabilidad general 
Descripción: Gestión integral de la contabilidad de la entidad: catálogo de cuentas, diarios, asientos, conciliaciones, estados financieros y reportes.

Procesos principales:
- Configuración contable
  - Definición del plan de cuentas y cuentas por defecto (impuestos, cuentas puente, etc.).
  - Creación y parametrización de diarios (banco, efectivo, compras, ventas, misceláneos).
- Registro de operaciones
  - Generación de asientos contables a partir de documentos fuente (facturas, pagos, gastos) y asientos manuales.
  - Gestión de impuestos y retenciones según normativa vigente.
- Conciliación bancaria
  - Importación de extractos bancarios y conciliación automática / manual.
  - Manejo de partidas abiertas y diferencias.
- Cuentas por pagar y por cobrar
  - Control de facturas de proveedores y clientes, notas de crédito/débito y vencimientos.
  - Enlaces con pagos y cobranzas.
- Cierre contable y reportes
  - Cierres mensuales/anuales, asientos de ajuste y reclasificaciones.
  - Generación de estados financieros (Balance General, Estado de Resultados) y reportes auxiliares.

## Presupuesto institucional 
Descripción: Planificación, aprobación, ejecución y control de la disponibilidad presupuestaria.

Procesos principales:
- Formulación del presupuesto
  - Carga de líneas presupuestarias por partida/centro de costo y periodo.
  - Versionamiento y aprobación del presupuesto inicial y reformulaciones.
- Compromisos y devengados
  - Registro de compromisos (reservas) al aprobar solicitudes/órdenes con impacto presupuestario.
  - Devengo al recibir bienes/servicios o registrar la obligación.
- Ejecución y control
  - Verificación de disponibilidad presupuestaria en tiempo real.
  - Reportes de ejecución: comprometido, devengado, pagado, saldo.

## Activos fijos 
Descripción: Administración del ciclo de vida de los activos fijos: alta, depreciación, revalorizaciones, bajas y reportes.

Procesos principales:
- Altas
  - Creación de activos a partir de compras o altas manuales; clasificación por categorías con reglas de depreciación.
- Depreciación
  - Cálculo periódico automático según vida útil y método; generación de asientos contables.
- Movimientos y cambios
  - Transferencias entre ubicaciones/unidades, mejoras y revalorizaciones.
- Bajas
  - Baja por venta, siniestro o retiro; asientos de pérdida/ganancia.
- Control y auditoría
  - Etiquetado, inventario físico y conciliación contable.

## Gastos y reembolsos 
Descripción: Gestión de reportes de gastos de empleados y su reembolso, integrados a contabilidad y presupuesto.

Procesos principales:
- Registro y flujo de aprobación
  - Captura de gastos con soportes; validación por jefatura/finanzas.
- Liquidación y pago
  - Contabilización automática y generación de pagos o nómina según política.
- Reglas y políticas
  - Límites, impuestos aplicables y centros de costo.

## Viáticos y movilizaciones 
Descripción: Gestión de viáticos nacionales y su liquidación, cumpliendo con normativas internas.

Procesos principales:
- Solicitud y aprobación
  - Cálculo de viáticos según destino, días y tablas; aprobación por niveles.
- Anticipos y liquidación
  - Entrega de anticipos, rendición con soportes y reintegros/diferencias.
- Integración
  - Impacto presupuestario y asientos contables asociados.

## Proceso de pagos a proveedores 
Descripción: Orquestación del ciclo de pago de obligaciones a proveedores y otros beneficiarios.

Procesos principales:
- Bandeja de obligaciones
  - Consolidación de obligaciones devengadas y aprobadas para pago.
- Programación de pagos
  - Priorización por vencimiento, monto, fuente de financiamiento y disponibilidad.
- Ejecución
  - Generación de lotes de pago (transferencias, cheques) y asiento contable de pago.
- Conciliación
  - Conciliación con extractos bancarios y cierre de partidas.

## Fideicomiso 
Descripción: Administración de operaciones vinculadas a fideicomisos: ingresos, egresos, rendimientos y reportes.

Procesos principales:
- Registro de operaciones
  - Ingresos/aportes, pagos desde el fideicomiso y gastos asociados.
- Conciliación y reportes
  - Conciliación de estados del fideicomiso y reportes para auditoría/seguimiento.

## Nómina y obligaciones laborales 
Descripción: Cálculo de nómina y sus asientos contables, incluyendo provisiones y obligaciones patronales.

Procesos principales:
- Cálculo y validación
  - Procesamiento de nómina por periodo; aprobación por RR. HH. y Finanzas.
- Contabilización
  - Generación de asientos de sueldos, aportes, provisiones y pagos.

