# Política de seguridad

GuriMAX maneja datos financieros, de inventario y de crédito de comercios
reales. Tomamos en serio cualquier reporte de vulnerabilidad y agradecemos
a quien invierta tiempo en reportarla de forma responsable.

## Cómo reportar una vulnerabilidad

**No abras un issue público para reportar una vulnerabilidad de
seguridad.** Un issue público expone el problema a cualquiera antes de que
exista una corrección.

En su lugar, usa uno de estos dos canales privados:

1. **Correo electrónico:** [rainhardl0x001@proton.me](mailto:rainhardl0x001@proton.me)
2. **GitHub Private Vulnerability Reporting:** desde la pestaña
   [Security](../../security/advisories/new) de este repositorio, puedes abrir un aviso privado directamente en GitHub sin
   necesidad de correo.

Incluye, en la medida de lo posible:

- Una descripción clara del problema y su impacto potencial.
- Pasos para reproducirlo, o una prueba de concepto.
- La versión o el commit específico donde lo identificaste.
- Cualquier mitigación temporal que hayas identificado.

## Compromiso de respuesta

Nos comprometemos a:

- Confirmar la recepción de tu reporte dentro de **5 días hábiles**.
- Darte una evaluación inicial (severidad y siguientes pasos) dentro de
  **10 días hábiles** a partir de la confirmación.
- Mantenerte informado del progreso hasta que el problema se resuelva o se
  descarte, con una justificación en este último caso.

Estos plazos son un compromiso, no una garantía absoluta; el proyecto es
mantenido por un equipo pequeño. Si no recibes respuesta dentro del plazo
indicado, es válido reenviar el reporte o marcarlo como urgente en el
asunto del correo.

## Versiones soportadas

GuriMAX todavía no tiene versiones estables publicadas.

| Versión | Soportada |
|---|:---:|
| `main` (rama de integración) | ✅ |
| Cualquier rama de trabajo (`feature/*`, `fix/*`, etc.) | ❌ |

Una vez existan releases etiquetados (por ejemplo `v1.0.0`), esta tabla se
actualizará para reflejar qué versiones reciben parches de seguridad y por
cuánto tiempo.

## Alcance

Esta política cubre el código de este repositorio: backend en Go, cliente
Wails/Svelte, migraciones SQL y configuración de infraestructura incluida
aquí (Docker, CI). No cubre servicios de terceros que el proyecto pueda
usar en el futuro (proveedores de correo, pasarelas de pago, etc.); esos
tendrán su propio canal de reporte cuando se integren.

## Divulgación coordinada

Pedimos no divulgar públicamente una vulnerabilidad hasta que exista una
corrección disponible y se haya coordinado contigo una fecha de
publicación. Con gusto acreditamos a quien reporta el problema, salvo que
prefiera permanecer anónimo.
