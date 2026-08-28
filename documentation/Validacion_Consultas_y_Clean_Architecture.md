# Validación de consultas SQL y siguiente capa de Clean Architecture

**Proyecto:** Sistema POS e inventario GuriMAX  
**Fecha:** 27 de agosto de 2026  
**Alcance:** `backend/db/queries/catalog.sql`, `backend/db/queries/sales.sql` y diseño de repositorios/casos de uso.

## 1. Conclusión ejecutiva

Las consultas de catálogo y ventas son correctas como **consultas de lectura**, se validan con sqlc v1.31.1 y ya exponen la información necesaria para construir pantallas de búsqueda, detalle de venta y reportes básicos. Sin embargo, no pueden cubrir por sí solas todas las reglas del negocio: las reglas críticas de GuriMAX requieren comandos de escritura, transacciones, bloqueos, autorización, idempotencia y coordinación con inventario, caja, crédito, facturación y auditoría.

La separación recomendada es la siguiente:

> **SQL consulta y persiste; el repositorio traduce; el caso de uso decide; el dominio valida invariantes; la transacción garantiza atomicidad; el adaptador HTTP transporta la solicitud.**

La revisión también produjo ajustes puntuales. `catalog.sql` ahora devuelve categoría, unidad, existencia disponible y estado de producto, admite filtrar por categoría y restringe las alertas de vencimiento a productos perecederos activos. `sales.sql` ahora devuelve contexto de cliente y caja, desglose financiero, estado de cancelación, clave de idempotencia, filtros opcionales para reportes y una consulta específica para detectar reintentos de la misma operación.

## 2. Validación de `catalog.sql`

| Consulta | Cobertura actual | Resultado | Brecha que no debe resolverse en el `SELECT` |
|---|---|---|---|
| `GetProductByBarcode` | Busca un código único, solo retorna productos activos y entrega precio, costo, impuestos, categoría, unidad, existencia, reserva y existencia disponible. | **Adecuada para lectura POS.** | La unicidad del código se garantiza en `product_barcodes`; la disponibilidad definitiva y la reserva deben validarse dentro de una transacción. |
| `SearchProducts` | Busca por nombre, SKU o código; filtra por categoría; retorna datos de venta, impuestos, unidad, estado de inventario, reserva y paginación. | **Adecuada para búsqueda de catálogo.** | La autorización de precios/descuentos, el control de unidades fraccionarias y la disponibilidad final pertenecen al caso de uso. |
| `ListLowStockProducts` | Compara existencia disponible contra mínimo configurado y expone si el producto permite inventario negativo. | **Adecuada para alerta de mínimos.** | La decisión de reabastecer, alertar por correo o permitir venta negativa pertenece a aplicación/operaciones. |
| `GetExpiringLots` | Filtra lotes con existencia, vencimiento dentro del rango y productos activos perecederos. | **Adecuada para alertas de vencimiento.** | El rango de 30 días debe ser leído desde `system_settings`; la política de bloqueo o merma requiere un caso de uso. |

La consulta de catálogo no modifica existencias. Esto es correcto y respeta la regla de que una venta no debe confiar en una lectura previa para descontar inventario. El caso de uso de venta deberá volver a cargar o bloquear el balance correspondiente, comprobar la cantidad disponible y registrar un `stock_movement` dentro de la misma transacción.

Un detalle relevante para la futura capa de repositorio es que MySQL `DECIMAL` se genera como `string` o `sql.NullString` en Go. Los repositorios deben convertir esos valores a un objeto de valor de cantidad, validar precisión y rechazar datos inválidos. No se deben filtrar los tipos generados por sqlc hacia el dominio.

## 3. Validación de `sales.sql`

| Consulta | Cobertura actual | Resultado | Brecha que debe resolver la aplicación |
|---|---|---|---|
| `GetSaleByID` | Retorna cabecera, desglose de importes, cliente, caja, fecha de negocio, usuario, idempotencia, cancelación y timestamps. | **Adecuada para detalle de venta.** | El repositorio debe ensamblar líneas y pagos y mapear estados a tipos de dominio. |
| `GetSaleByIdempotencyKey` | Permite comprobar si un comando ya fue confirmado con la misma clave. | **Necesaria para reintentos seguros.** | La API debe comparar también el hash de la solicitud y rechazar reutilización con payload distinto. |
| `ListSaleLines` | Retorna cantidades, instantáneas del producto, precios, descuentos, impuestos, total de línea y lote. | **Adecuada para detalle histórico.** | No calcula ni corrige totales; el caso de uso debe tratar la venta persistida como inmutable. |
| `ListSalePayments` | Retorna pagos mixtos, estado, referencia externa y verificación. | **Adecuada para consulta de cobros.** | La suma compatible con el total, el cambio y la aprobación de transferencias se validan en aplicación. |
| `ListSalesByDate` | Filtra por intervalo técnico, estado, sesión de caja y usuario; retorna desglose financiero, cliente, fecha de caja y cantidad de líneas. | **Adecuada para reporte básico.** | Para reportes completos aún se necesitan agregados por medio de pago, producto, categoría, cajero y margen. |

Las consultas no cubren por sí solas la finalización de una venta. El caso `CompleteSale` debe recalcular precios, descuentos, impuestos y totales desde el servidor; verificar la caja; comprobar crédito; registrar pagos; descontar inventario; crear el asiento de crédito cuando corresponda; reservar o emitir el comprobante; registrar auditoría y confirmar todo en una sola transacción.

## 4. Qué reglas no deben implementarse en SQL de lectura

| Regla de negocio | Responsable recomendado |
|---|---|
| Una venta debe tener líneas y cantidades positivas. | Entidad/agregado `Sale` y caso de uso. |
| Los totales se calculan en el servidor. | Servicio de dominio o política de precios/impuestos. |
| El descuento fuera del límite requiere autorización. | Política de autorización en aplicación. |
| Una venta a crédito respeta límite, vencimiento y bloqueo. | Agregado `CustomerAccount` y caso de uso `CompleteSale`. |
| La venta actualiza caja, inventario, crédito y auditoría de forma atómica. | `TransactionManager`/`UnitOfWork`. |
| La existencia negativa es explícita y reportable. | Política de inventario y `stock_movements`. |
| Una transferencia queda pendiente hasta ser verificada. | Caso de uso de verificación y estado `sale_payments`. |
| Una devolución repone solo producto vendible. | Caso de uso `ProcessReturn` y módulo `returns`. |
| La misma solicitud no puede generar dos ventas. | `idempotency_keys`, restricción única y caso de uso. |
| Una acción sensible requiere actor, motivo y aprobador. | Autorización contextual y `audit_log`. |

## 5. Implementación de repositorios

Los repositorios deben vivir en la infraestructura de cada módulo, mientras que las interfaces deben declararse en la capa de aplicación. Así el caso de uso conoce una intención de negocio, no una tabla ni `*sql.Tx`.

La estructura propuesta es:

```text
backend/
├── internal/
│   ├── platform/
│   │   ├── mysql/
│   │   ├── transaction/
│   │   ├── clock/
│   │   └── id/
│   ├── modules/
│   │   ├── catalog/
│   │   │   ├── domain/
│   │   │   ├── application/ports/
│   │   │   └── infrastructure/mysql/
│   │   ├── sales/
│   │   │   ├── domain/
│   │   │   ├── application/commands/
│   │   │   ├── application/queries/
│   │   │   ├── application/ports/
│   │   │   └── infrastructure/mysql/
│   │   ├── inventory/
│   │   └── cash/
│   └── shared/domain/
└── db/
    ├── queries/
    └── generated/sqlc/
```

### 5.1 Puertos de aplicación

Los puertos deben ser pequeños y orientados al caso de uso. Un ejemplo de lectura de catálogo sería:

```go
package ports

import "context"

type ProductSearch struct {
    Text       string
    CategoryID *string
    Limit      int32
    Offset     int32
}

type ProductReader interface {
    ByBarcode(ctx context.Context, barcode string) (Product, error)
    Search(ctx context.Context, filter ProductSearch) ([]Product, error)
    LowStock(ctx context.Context) ([]StockAlert, error)
    ExpiringLots(ctx context.Context, from, to time.Time) ([]ExpiringLot, error)
}
```

Para ventas, el puerto de lectura debe ensamblar el agregado sin devolver tipos sqlc:

```go
package ports

type SaleReader interface {
    ByID(ctx context.Context, id SaleID) (SaleDetail, error)
    ByIdempotencyKey(ctx context.Context, key string) (SaleReceipt, error)
    List(ctx context.Context, filter SaleFilter) ([]SaleSummary, error)
}

type SaleWriter interface {
    CreateDraft(ctx context.Context, sale *Sale) error
    SaveCompleted(ctx context.Context, sale *Sale) error
}
```

Los puertos que coordinan módulos deben expresar capacidades, no acceder a tablas ajenas:

```go
package ports

type InventoryGateway interface {
    ReserveOrValidate(ctx context.Context, items []SaleItemRequest) error
    RegisterSaleMovement(ctx context.Context, items []SaleItemRequest, saleID SaleID) error
}

type CashGateway interface {
    EnsureOpen(ctx context.Context, sessionID string) error
    RegisterSalePayments(ctx context.Context, saleID SaleID, payments []PaymentRequest) error
}

type CreditGateway interface {
    CheckCredit(ctx context.Context, customerID string, amountCents int64) error
    RegisterCharge(ctx context.Context, customerID string, saleID SaleID, amountCents int64) error
}
```

En la implementación final, estos puertos deben compartir una unidad transaccional. Una opción práctica es que `TransactionManager` ejecute una función con repositorios construidos sobre el mismo `*sql.Tx`; otra opción es que cada repositorio reciba una interfaz `DBTX`, compatible tanto con `*sql.DB` como con `*sql.Tx`, como ya permite el código generado por sqlc mediante `WithTx`.

### 5.2 Mapeadores explícitos

Cada repositorio debe convertir filas sqlc a tipos de aplicación o dominio. El mapeo debe validar identificadores, cantidades `DECIMAL`, estados y valores opcionales.

```go
func mapProduct(row sqlc.SearchProductsRow) (catalog.Product, error) {
    quantity, err := money.ParseQuantity(row.StockQuantity)
    if err != nil {
        return catalog.Product{}, fmt.Errorf("stock de producto %s: %w", row.ID, err)
    }

    return catalog.Product{
        ID:               catalog.ProductID(row.ID),
        SKU:              row.Sku,
        Name:             row.Name,
        SalePrice:        money.FromCents(row.SalePriceCents),
        CostPrice:        money.FromCents(row.CostPriceCents),
        AvailableStock:   quantity,
        AllowNegative:    row.AllowNegativeStock,
        IsPerishable:     row.IsPerishable,
        CategoryID:       row.CategoryID,
        CategoryName:     row.CategoryName,
        UnitCode:         row.UnitCode,
    }, nil
}
```

Este mapeo evita que el dominio dependa de `sql.NullString`, `sql.NullTime`, `uint64` o de la forma física de las tablas. También es el punto correcto para convertir errores como `sql.ErrNoRows` en errores de aplicación como `ErrProductNotFound` o `ErrSaleNotFound`.

## 6. Casos de uso prioritarios

| Orden | Caso de uso | Motivo |
|---:|---|---|
| 1 | `Login` | Sin identidad y sesión no existe seguridad confiable. |
| 2 | `SearchProducts` | Habilita lectura del catálogo sin exponer SQL al cliente. |
| 3 | `OpenCashSession` | Una venta necesita una caja activa y fondo inicial. |
| 4 | `CompleteSale` | Es el flujo de mayor riesgo financiero y transaccional. |
| 5 | `ReceivePurchase` | Alimenta existencias, lotes, costos e incidencias. |
| 6 | `ApproveInventoryAdjustment` | Protege las diferencias del inventario físico. |
| 7 | `RegisterCreditPayment` | Mantiene saldos y abonos trazables. |
| 8 | `ProcessReturn` | Coordina reembolso, inventario vendible y merma. |
| 9 | `CloseCashSession` | Calcula esperado, contado, diferencia y aprobación. |
| 10 | `GetSalesReport` | Proporciona consulta CQRS de lectura sin mutar estado. |

## 7. Flujo recomendado de `CompleteSale`

El caso de uso debe ejecutar los siguientes pasos dentro de una transacción MySQL:

1. Autenticar al usuario y verificar autorización contextual.
2. Comprobar la clave de idempotencia; si ya existe, devolver el recibo original cuando el hash coincida.
3. Verificar caja activa y cargar productos desde el servidor.
4. Bloquear o validar balances de inventario en orden determinista para reducir carreras y deadlocks.
5. Recalcular precio, descuento, impuesto, subtotal, total, pagos y cambio.
6. Validar límite, plazo y bloqueo si existe crédito.
7. Insertar cabecera y líneas de venta con instantáneas históricas.
8. Insertar pagos y movimientos de caja.
9. Insertar movimientos de inventario y actualizar la proyección `inventory_balances`.
10. Registrar el cargo de crédito, generar o reservar comprobante y guardar auditoría.
11. Confirmar la transacción. Ante cualquier error, ejecutar rollback completo.

El repositorio de ventas no debe llamar directamente a un repositorio de inventario concreto. El caso de uso coordina puertos, y la composición de dependencias en `cmd/api/main.go` decide qué adaptadores concretos se utilizan.

## 8. Manejo de transacciones y bloqueos

Las operaciones de escritura que modifican venta, caja, inventario, crédito o auditoría deben abrir una transacción de lectura/escritura y usar `WithTx` en las consultas generadas. Para validar disponibilidad concurrente, se deben añadir consultas específicas de escritura con `SELECT ... FOR UPDATE` o actualizaciones condicionales atómicas, por ejemplo sobre `inventory_balances`.

Las consultas actuales son de lectura y no deben transformarse artificialmente en comandos. La siguiente ampliación de `db/queries` debería crear archivos separados, por ejemplo `catalog_commands.sql`, `sales_commands.sql`, `inventory_commands.sql` y `cash_commands.sql`, con operaciones como `CreateSale`, `InsertSaleLine`, `InsertSalePayment`, `LockInventoryBalance`, `InsertStockMovement` y `InsertAuditEntry`.

## 9. Resultado de validación

| Validación | Resultado |
|---|---|
| `sqlc generate` v1.31.1 sobre esquema y consultas actuales | Correcta. |
| `sqlc vet` sobre esquema y consultas actuales | Correcta, sin errores. |
| Regeneración tras ampliar catálogo y ventas | Correcta. |
| Tipos opcionales en filtros (`sql.NullString`) | Confirmados en código generado. |
| Cantidades `DECIMAL` expuestas como texto | Confirmado; requieren mapeo a objetos de valor. |
| Integración real con MySQL/Docker | Pendiente en un entorno con Docker Desktop o servidor MySQL disponible. |
| Pruebas de casos de uso | Pendientes porque la capa de aplicación aún no existe en el repositorio. |

## Referencias

[^1]: [Stack tecnológico aprobado](Stack_Tecnologico.pdf).
[^2]: [Definición del proyecto y requisitos](Definicion_Proyecto_GuriMAX.pdf).
[^3]: [Clean Architecture](Clean_Architecture.pdf) y [Explicación de la estructura](Explicacion_Clean_Architecture.pdf).
[^4]: [sqlc: Getting started with MySQL](https://docs.sqlc.dev/en/latest/tutorials/getting-started-mysql.html).
[^5]: [MySQL 9.7: InnoDB Transaction Model](https://dev.mysql.com/doc/refman/9.7/en/innodb-transaction-model.html).
[^6]: [MySQL 9.7: START TRANSACTION, COMMIT, and ROLLBACK](https://dev.mysql.com/doc/en/commit.html).
