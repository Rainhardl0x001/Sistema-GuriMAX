# Implementación de la base de datos de GuriMAX

**Proyecto:** Sistema POS e inventario para Provisiones Gurima  
**Fecha:** 27 de agosto de 2026  
**Alcance de esta intervención:** persistencia inicial, migraciones SQL, consultas sqlc y entorno local de MySQL.

## 1. Criterios aplicados

La implementación se realizó sobre el repositorio existente, que se encontraba en una etapa de estructura inicial: el backend, los módulos de Clean Architecture y el cliente contenían principalmente archivos de preservación de carpetas, sin lógica de negocio implementada. Por ese motivo, se limitaron los cambios al área de persistencia y a la documentación técnica de la intervención.

El modelo sigue el baseline aprobado: **MySQL centralizado**, acceso desde Go mediante `database/sql`, generación de código con **sqlc** y migraciones SQL versionadas para `golang-migrate`. La base de datos no se expone al cliente Wails; en la arquitectura prevista, únicamente la API Go tendrá las credenciales y el acceso a MySQL.[^1] [^2]

Los importes monetarios se almacenan como enteros en centavos (`*_cents`) para evitar errores de redondeo binario. La moneda operativa queda restringida a `DOP` en las entidades financieras principales. Las fechas técnicas usan `DATETIME(6)` y las fechas de negocio que requieren semántica propia, como la fecha de caja o de compra, se modelan en columnas separadas.

## 2. Archivos agregados o modificados

| Ruta | Tipo de cambio | Propósito |
|---|---|---|
| `backend/db/migrations/000001_initial_schema.up.sql` | Nuevo | Crea el esquema completo, restricciones, índices y datos maestros iniciales. |
| `backend/db/migrations/000001_initial_schema.down.sql` | Nuevo | Revierte la migración en orden inverso para ambientes de desarrollo o pruebas. |
| `backend/db/queries/catalog.sql` | Nuevo | Consultas tipadas para búsqueda de productos, mínimos y vencimientos. |
| `backend/db/queries/sales.sql` | Nuevo | Consultas tipadas para ventas, líneas, pagos y reportes por período. |
| `backend/db/queries/operations.sql` | Nuevo | Consultas tipadas para caja, cuentas por pagar, crédito y auditoría. |
| `backend/sqlc.yaml` | Nuevo | Configuración de sqlc v1.31.1 para MySQL y salida en `db/generated/sqlc`. |
| `backend/db/generated/sqlc/` | Nuevo | Código Go generado automáticamente por sqlc; no debe editarse manualmente. |
| `backend/docker-compose.yml` | Modificado | Añade MySQL 9.7.3, volumen persistente, healthcheck y ejecución inicial de la migración. |
| `backend/db/generated/slqc/.gitkeep` | Eliminado | Se corrige la carpeta existente con el typo `slqc`; la ruta correcta es `sqlc`. |
| `documentation/Implementacion_Base_Datos.md` | Nuevo | Registro técnico de la intervención y de sus validaciones. |

No se modificaron el cliente, los módulos de dominio, los adaptadores HTTP, `main.go`, `go.mod` ni la configuración de Wails porque todavía no contienen implementaciones que requieran adaptación para esta entrega.

## 3. Modelo de datos implementado

El esquema se organiza por capacidades de negocio, no como un conjunto de tablas aisladas. Las relaciones permiten que la API implemente posteriormente casos de uso transaccionales sin convertir el modelo de persistencia en el modelo de dominio.

| Área | Tablas principales | Responsabilidad |
|---|---|---|
| Identidad | `roles`, `permissions`, `role_permissions`, `users`, `sessions` | Cuentas individuales, roles, permisos y sesiones revocables. |
| Catálogo | `categories`, `units`, `products`, `product_barcodes`, `product_suppliers`, `product_price_history`, `product_lots`, `suppliers` | Productos, precios, costos, códigos, proveedores, lotes y vencimientos. |
| Clientes y crédito | `customers`, `credit_accounts`, `credit_entries` | Límites, bloqueo, saldos, cargos, abonos y vencimientos. |
| POS | `sales`, `sale_lines`, `sale_payments` | Venta, instantánea de datos del producto, pagos múltiples, cambio e idempotencia. |
| Caja | `cash_registers`, `cash_sessions`, `cash_movements` | Caja física, turnos, fondo inicial, cobros, retiros, cierres y diferencias. |
| Inventario | `inventory_balances`, `stock_movements`, `inventory_counts`, `inventory_count_lines` | Existencias, reservas, movimientos trazables, conteos y ajustes aprobables. |
| Compras | `purchases`, `purchase_lines`, `purchase_receipts`, `purchase_receipt_lines`, `purchase_incidents` | Compras, recepción parcial, lotes, costos e incidencias. |
| Cuentas por pagar | `payables`, `payable_payments` | Obligaciones con proveedores, abonos y saldos pendientes. |
| Devoluciones | `sales_returns`, `sales_return_lines`, `refunds` | Solicitudes, aprobación, condición del producto y reembolsos. |
| Facturación | `tax_policies`, `billing_sequences`, `billing_documents`, `billing_document_lines` | Políticas fiscales parametrizables, secuencias y comprobantes digitales. |
| Operación y control | `idempotency_keys`, `audit_log`, `migration_batches`, `backup_jobs`, `system_settings` | Reintentos seguros, auditoría, migración, respaldos y configuración operativa. |

## 4. Reglas de integridad incluidas

La base de datos impide duplicar usuarios, roles, permisos, SKU, códigos de barras, proveedores con el mismo RNC, clientes con la misma identificación, números de documentos e idempotency keys dentro de su ámbito. Las claves foráneas mantienen la relación entre las operaciones y sus actores; cuando una referencia histórica puede sobrevivir a la desactivación de un usuario, se utiliza `ON DELETE SET NULL` en lugar de borrar el registro operativo.

Las cantidades de líneas, conteos, lotes y recepciones tienen restricciones de positividad o no negatividad. Las líneas de recepción no pueden superar la cantidad solicitada, de manera que una recepción parcial debe registrar únicamente lo recibido y la diferencia debe quedar en `purchase_incidents`. Las modificaciones de inventario se representan mediante `stock_movements`, conservando cantidad anterior, delta, cantidad posterior, costo, referencia y motivo.

La tabla `cash_sessions` utiliza una columna generada y una clave única para impedir dos sesiones activas (`OPEN` o `REOPENED`) para la misma caja y fecha de negocio. Las diferencias de cierre se conservan en `expected_cash_cents`, `counted_cash_cents` y `difference_cents`; no se corrige silenciosamente la operación original.

Las operaciones que pueden repetirse por reintentos del cliente incluyen una clave de idempotencia única, por ejemplo ventas, recepciones, abonos, devoluciones y movimientos. La API deberá comprobar además que una clave reutilizada corresponde al mismo contenido de solicitud antes de devolver una respuesta previamente registrada.

La auditoría es append-only a nivel de diseño: `audit_log` registra actor, rol, acción, entidad, motivo, autorización relacionada, valores anteriores, valores posteriores y correlación. La aplicación deberá evitar operaciones de actualización o borrado sobre el historial, y deberá registrar un movimiento compensatorio cuando una operación de negocio deba corregirse.

## 5. Datos maestros iniciales

La migración inserta únicamente datos maestros seguros y no inventa productos, clientes, saldos históricos ni existencias. Incluye los roles `ADMIN` y `OPERATOR`, permisos base, unidades `UNIT`, `KG`, `L`, `PACK`, una caja principal, una política fiscal exenta y secuencias iniciales para comprobantes. También registra parámetros operativos iniciales: moneda DOP, plazo de crédito de 30 días, devolución no perecedera de 7 días y alerta de vencimiento de 30 días.

Los datos históricos del cuaderno de fiados, el inventario inicial y los productos deberán cargarse mediante un proceso de migración validado y aprobado, no mediante esta migración estructural. Esto respeta el requisito de revisar duplicados, saldos inconsistentes, productos incompletos y códigos repetidos antes de activar producción.[^2]

## 6. sqlc y consultas

`backend/sqlc.yaml` configura el motor MySQL, usa la migración inicial como esquema, toma las consultas desde `backend/db/queries` y genera el paquete `sqlc` en `backend/db/generated/sqlc`. El código generado importa únicamente `database/sql` y expone `Queries` y `WithTx`, por lo que puede utilizarse dentro de las transacciones de los casos de uso sin hacer que el dominio dependa de los tipos generados.

Las consultas se agrupan por intención: catálogo, ventas y operaciones. Los handlers HTTP y los casos de uso todavía no fueron creados porque esa parte no formaba parte del estado existente ni del alcance solicitado. Cuando se implementen, los repositorios deberán mapear los modelos sqlc hacia entidades o modelos de aplicación, tal como establece la arquitectura limpia.[^3]

## 7. Entorno local

`backend/docker-compose.yml` define MySQL 9.7.3 con un volumen persistente `mysql_data`, zona horaria `America/Santo_Domingo`, healthcheck y una red privada de Compose. El puerto se enlaza a `127.0.0.1`, por lo que no se publica en interfaces externas del equipo de desarrollo. La migración `000001_initial_schema.up.sql` se ejecuta automáticamente por la imagen oficial cuando el volumen se inicializa por primera vez.

Las contraseñas del Compose son valores de desarrollo configurables por variables de entorno y no deben reutilizarse en producción. En producción, la API Go debe conectarse a la instancia MySQL centralizada a través de la red privada y las migraciones deben ejecutarse mediante el mecanismo versionado seleccionado para el despliegue.

## 8. Validaciones ejecutadas

| Validación | Resultado |
|---|---|
| `sqlc generate` con sqlc v1.31.1 | Correcta; se generaron `db.go`, `models.go`, `catalog.sql.go`, `sales.sql.go` y `operations.sql.go`. |
| `sqlc vet` | Correcta; no reportó errores sobre el esquema ni las consultas. |
| Parseo del esquema de migración por sqlc | Correcto; se aceptaron tablas, relaciones, restricciones y tipos MySQL utilizados. |
| Revisión de estado Git | Correcta; los cambios quedan limitados a persistencia, configuración local y documentación de esta intervención. |
| `git diff --check` | Sin errores de espacios; Git únicamente informa la normalización esperada de LF/CRLF del archivo Compose en Windows. |
| Ejecución de Docker Compose en el equipo remoto | No ejecutada: Docker Desktop no está instalado o no está disponible en el PATH del equipo conectado. |
| `go test`, `go vet` y compilación del backend | No ejecutados: el backend actual no tiene implementación Go ni el comando `go` disponible en el equipo remoto. |

La validación de sqlc es especialmente relevante porque revisa simultáneamente la compatibilidad del esquema con las consultas y genera el código que consumirá la futura infraestructura MySQL. La prueba de arranque real de MySQL queda pendiente de ejecutarse en un equipo con Docker Desktop o en un servidor de desarrollo habilitado.

## 9. Próximos pasos técnicos

La siguiente entrega debería implementar la conexión técnica en `internal/platform/mysql`, el gestor de transacciones, la configuración segura y la aplicación de migraciones con `golang-migrate`. Después conviene implementar primero identidad, autorización, catálogo e inventario; las ventas y las compras deberán coordinar varios repositorios dentro de una sola transacción. Finalmente deben añadirse pruebas de integración con MySQL para rollback, restricciones, bloqueo de caja, recepción parcial, crédito, devolución y auditoría.

[^1]: [Stack tecnológico aprobado](Stack_Tecnologico.pdf)
[^2]: [Definición del proyecto y requisitos](Definicion_Proyecto_GuriMAX.pdf)
[^3]: [Clean Architecture](Clean_Architecture.pdf) y [Explicación de la estructura](Explicacion_Clean_Architecture.pdf)
