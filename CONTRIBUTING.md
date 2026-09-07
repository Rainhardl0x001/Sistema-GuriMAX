# Guía de contribución

Gracias por tu interés en contribuir a GuriMAX. Este documento describe
cómo está organizado el trabajo, qué se espera de un Pull Request, y las
reglas especiales para cambios sensibles (dinero, inventario, caja,
crédito, permisos y migraciones).

Antes de contribuir, revisa también el [Código de Conducta](CODE_OF_CONDUCT.md)
y el [Contributor License Agreement](CLA.md). Al abrir un Pull Request,
aceptas los términos de ambos.

## Estrategia de ramificación

GuriMAX usa **Trunk-Based Development ligero con `main` protegida**. El
equipo es pequeño, el producto es un monolito modular, y se prioriza la
integración frecuente sobre ramas de larga duración. No se usa Git Flow
clásico ni una rama `develop` permanente: duplicaría el punto de
integración y retrasaría la detección de conflictos.

**Regla central:** todo cambio se integra a `main` mediante un Pull
Request pequeño, revisado y con CI aprobado. No se permiten pushes
directos a `main`.

### Ramas permanentes

| Rama | Propósito | Regla |
|---|---|---|
| `main` | Única rama de integración y código potencialmente desplegable | Protegida; no se permiten pushes directos |
| `release/vX.Y.Z` | Preparar una versión candidata cuando llegue un hito | Temporal; solo correcciones, documentación y ajustes de configuración |

### Ramas temporales

Usa nombres breves asociados a una tarea o caso de uso, representando un
**slice vertical funcional**, no una capa técnica:

```text
feature/identity-login
feature/catalog-product-crud
feature/sales-complete-sale
fix/sale-idempotency
fix/return-stock-adjustment
chore/ci-quality-gates
refactor/sales-transaction-boundary
```

Es preferible `feature/sales-complete-sale` —que incluya dominio, caso de
uso, API, persistencia, migración, interfaz y pruebas necesarias— a
separar el trabajo en `backend-sales` y `frontend-sales`.

### Flujo recomendado

1. Crea la rama desde la última versión de `main`.
2. Implementa un cambio pequeño, completo y demostrable.
3. Ejecuta localmente formato, análisis estático, pruebas y validación de
   migraciones.
4. Abre un Pull Request hacia `main`.
5. Solicita revisión de otro colaborador del proyecto, especialmente para
   cambios que afecten dinero, inventario, caja, crédito, permisos o
   migraciones.
6. Fusiona preferiblemente con **Squash and merge**, dejando un commit
   equivalente a una unidad funcional completa.
7. Elimina la rama después del merge.
8. Etiqueta los hitos importantes (por ejemplo `v0.1.0-foundation`,
   `v0.2.0-pilot`, `v1.0.0`).

El Pull Request debe poder responder claramente:

- ¿Qué flujo habilita?
- ¿Qué reglas de negocio protege?
- ¿Cómo se prueba?
- ¿Modifica el esquema de datos?

### Política especial para migraciones y cambios sensibles

Las migraciones SQL deben viajar en el **mismo** Pull Request que el
código que las utiliza. Nunca se integra primero la aplicación dejando el
esquema para después. Cada migración debe ser versionada, aplicable desde
una base vacía, y comprobada en CI.

Para cambios de alto riesgo —completar una venta, cierre de caja,
movimientos de inventario, crédito, devoluciones, permisos y respaldos— se
exige:

| Control | Requisito |
|---|---|
| Revisión | Aprobación de otro colaborador del proyecto |
| Pruebas | Unitarias y de integración; pruebas de rollback cuando corresponda |
| Datos | Validar importes en DOP sin `float32` ni `float64` |
| Trazabilidad | Auditoría y movimientos compensatorios, nunca edición silenciosa |
| Compatibilidad | Confirmar contrato de API y migración |
| Operación | Verificar idempotencia y reintentos en comandos con efectos |

### CI obligatorio para `main`

Un Pull Request se bloquea si falla cualquiera de estas verificaciones:

```text
gofmt -l .
go vet ./...
go test ./...
pnpm install --frozen-lockfile
pnpm run check
pnpm run lint
pnpm run test
validación de migraciones desde cero
build del cliente Wails y de la API Go
```

El pipeline también verifica que no existan credenciales expuestas, que el
esquema pueda levantarse con Docker Compose, y que las pruebas
transaccionales cubran el caso de uso modificado.

### Releases, piloto y hotfixes

Para un piloto técnico se usa un tag como `v0.1.0-pilot`. Si necesita
estabilizarse sin detener el desarrollo, se crea temporalmente
`release/v0.1.x`; las correcciones se aplican primero ahí y luego se
sincronizan con `main` mediante otro Pull Request.

Los errores críticos en producción salen de una rama `hotfix/<incidente>`
creada desde el tag o commit desplegado. Después de fusionarla en `main`,
se crea un nuevo tag de parche (por ejemplo `v1.0.1`). No se corrige
directamente sobre el servidor ni se mantiene una línea de desarrollo
separada por mucho tiempo.

### Resumen

```text
main                          ← integración protegida
├── feature/<slice-vertical>  ← trabajo normal, vida corta
├── fix/<problema>            ← corrección no productiva
├── refactor/<alcance>        ← refactorización controlada
├── chore/<mantenimiento>     ← CI, dependencias, documentación
├── release/vX.Y.Z            ← solo durante preparación de entrega
└── hotfix/<incidente>        ← solo incidentes productivos
```

## Convención de mensajes de commit

Cada commit fusionado a `main` (idealmente vía Squash and merge) sigue el
formato de **Conventional Commits**, con un título corto y, cuando aporte
información, un cuerpo con contexto y una lista de cambios.

**Formato del título:**

```text
tipo(alcance): descripción breve en imperativo
```

Tipos usados en este proyecto: `feat`, `fix`, `docs`, `chore`, `refactor`,
`ci`, `build`, `test`. El alcance identifica el módulo o área afectada
(por ejemplo `readme`, `db`, `workflow`, `legal`, `docker`).

**Cuerpo (opcional, según el caso):** no todo commit necesita descripción
y bullets. Usa tu criterio:

- Un cambio simple y autoexplicativo puede llevar solo el título.
- Un cambio con varios puntos concretos se beneficia de una descripción
  breve del motivo, seguida de bullets con el detalle.
- Un cambio sensible (dinero, caja, inventario, crédito, migraciones)
  debe llevar contexto completo y bullets detallados, para que quede
  trazable en el historial.

**Ejemplo:**

```text
fix(db): resolve schema constraint conflict and stabilize mysql healthcheck

Resolve MySQL ERROR 3823 (HY000) by removing the CHECK constraint on the
audit_log table that conflicted with a FOREIGN KEY, delegating this
specific logic validation to the Go application layer.

- Remove 'chk_audit_log_actor_or_system' constraint from 001_initial_schema.sql.
- Refactor MySQL healthcheck in docker-compose.yml to use a direct CMD ping.
- Add a 90s start_period to the healthcheck.
```

## Antes de abrir un Pull Request

```bash
git status
git diff --check
docker compose config --quiet
go -C backend test ./...
```

Nunca subas `.env`, contraseñas, tokens ni claves privadas.

## ¿Dudas?

Si algo de este documento no queda claro, abre un issue con la etiqueta
`pregunta` antes de empezar a trabajar en un cambio grande — es más
barato resolver una duda antes que revertir un Pull Request completo.
