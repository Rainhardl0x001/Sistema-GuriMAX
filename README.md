<div align="center">

# GuriMAX

**Sistema de punto de venta para pequeños y medianos comercios**

Centraliza catálogo, inventario, ventas, compras, caja, crédito y auditoría
mediante una arquitectura evolutiva y mantenible.

[![CI](https://img.shields.io/github/actions/workflow/status/Rainhardl0x001/Sistema-GuriMAX/ci.yml?branch=main&label=CI&logo=github)](https://github.com/Rainhardl0x001/Sistema-GuriMAX/actions/workflows/ci.yml)
[![Go](https://img.shields.io/badge/Go-1.27.0-00ADD8?logo=go&logoColor=white)](https://go.dev/)
[![MySQL](https://img.shields.io/badge/MySQL-9.7.2-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![SQLC](https://img.shields.io/badge/SQLC-code%20generation-4B8BBE)](https://sqlc.dev/)
[![License: BUSL-1.1](https://img.shields.io/badge/License-BUSL%201.1-informational?logo=gnu&logoColor=white)](#licencia)
[![Last Commit](https://img.shields.io/github/last-commit/Rainhardl0x001/Sistema-GuriMAX)](https://github.com/Rainhardl0x001/Sistema-GuriMAX/commits/main)
[![Issues](https://img.shields.io/github/issues/Rainhardl0x001/Sistema-GuriMAX)](https://github.com/Rainhardl0x001/Sistema-GuriMAX/issues)

</div>

---

> [!NOTE]
> GuriMAX se encuentra en la etapa de **fundación técnica**. MySQL, Docker
> Compose, las migraciones iniciales, SQLC y una API Go mínima están
> preparados. La lógica completa del POS, los casos de uso, los handlers
> HTTP y el frontend Svelte todavía están en desarrollo.

## Tabla de contenidos

- [Descripción](#descripción)
- [Estado actual](#estado-actual)
- [Arquitectura](#arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Ejecutar MySQL](#ejecutar-mysql)
- [Ejecutar el backend](#ejecutar-el-backend)
- [Base de datos y migraciones](#base-de-datos-y-migraciones)
- [SQLC](#sqlc)
- [Validaciones](#validaciones)
- [Estructura](#estructura)
- [Roadmap](#roadmap)
- [Contribución](#contribución)
- [Seguridad](#seguridad)
- [Contribuidores](#contribuidores)
- [Documentación](#documentación)
- [Licencia](#licencia)

---

## Descripción

GuriMAX será una aplicación POS de escritorio con un backend en Go y una
base de datos MySQL. Está diseñada para evolucionar hacia la gestión de
productos, existencias, ventas, compras, caja, clientes, proveedores,
crédito y auditoría.

La aplicación de escritorio no se conectará directamente a MySQL. El
backend será responsable de la API, las reglas de negocio, la
autorización, las transacciones y el acceso a datos.

## Estado actual

| Área | Estado |
|---|---|
| MySQL con Docker Compose | Configurado con volumen persistente, red privada y health check |
| Esquema inicial | `backend/db/migrations/000001_initial_schema.up.sql` |
| Migración inversa | `backend/db/migrations/000001_initial_schema.down.sql` |
| Backend Go | Servidor HTTP mínimo con `GET /health` |
| Dockerfile | Compilación multi-stage y usuario no privilegiado |
| SQLC | Configurado para generar código Go desde SQL |
| Consultas SQL | Separadas en catálogo, operaciones y ventas |
| CI | Validación progresiva de los componentes iniciados |
| Frontend Svelte | Estructura reservada, todavía no inicializada |
| Cliente Wails | Estructura inicial; integración funcional pendiente |
| Casos de uso del POS | Pendientes |
| Autenticación y autorización | Pendientes |

> [!NOTE]
> El CI omite componentes vacíos durante esta etapa. Si un componente
> iniciado contiene errores reales, la validación debe fallar.

## Contribuidores

<a href="https://github.com/Rainhardl0x001/Sistema-GuriMAX/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Rainhardl0x001/Sistema-GuriMAX" alt="Contribuidores de GuriMAX" />
</a>

<br>
<br>

Un enorme agradecimiento a cada persona que ha formado parte de este proyecto. 
Todas las aportaciones, opiniones y sugerencias —sin importar su tamaño— son de
gran valor para seguir mejorando. ¡Gracias por sumar!

## Arquitectura

```text
┌──────────────────────────────┐
│ Wails + Svelte                │
│ Cliente de escritorio         │
└──────────────┬───────────────┘
               │ HTTP / cliente Go
┌──────────────▼───────────────┐
│ API y aplicación Go           │
│ Handlers · casos de uso       │
│ Contratos · validaciones      │
└──────────────┬───────────────┘
               │ repositorios
┌──────────────▼───────────────┐
│ Persistencia                  │
│ database/sql · sqlc           │
│ Migraciones · transacciones   │
└──────────────┬───────────────┘
               │
┌──────────────▼───────────────┐
│ MySQL                         │
│ Docker Compose en desarrollo  │
└──────────────────────────────┘
```

## Stack tecnológico

| Componente | Tecnología |
|---|---|
| Backend | Go `1.27.0` |
| Base de datos | MySQL `9.7.2` |
| Contenedores | Docker y Docker Compose |
| Generación SQL | SQLC |
| Cliente de escritorio | Wails |
| Frontend previsto | Svelte |
| Automatización | GitHub Actions |

[![Go Report Card](https://goreportcard.com/badge/github.com/Rainhardl0x001/Sistema-GuriMAX/backend)](https://goreportcard.com/report/github.com/Rainhardl0x001/Sistema-GuriMAX/backend)

## Requisitos

- Git
- Docker Desktop o Docker Engine con Docker Compose
- Go `1.27.0` para ejecutar el backend fuera del contenedor
- SQLC para generar y validar el código de persistencia
- Node.js y pnpm cuando se inicialice el frontend

```bash
git --version
docker --version
docker compose version
go version
sqlc version
```

## Instalación

```bash
git clone https://github.com/Rainhardl0x001/Sistema-GuriMAX.git
cd Sistema-GuriMAX
cp .env.example .env
```

Edita `.env` y establece una contraseña root no vacía:

```dotenv
MYSQL_ROOT_PASSWORD=define_una_contraseña_local
MYSQL_DATABASE=gurimax_pos
MYSQL_USER=gurimax
MYSQL_PASSWORD=app_dev_password
MYSQL_PORT=3306
```

> [!WARNING]
> `.env` contiene configuración local y no debe subirse. `.env.example`
> documenta las variables sin almacenar secretos reales.

Levanta la base de datos y genera el código de persistencia antes de correr
el backend por primera vez:

```bash
docker compose up -d --wait mysql
cd backend
sqlc generate
```

## Ejecutar MySQL

```bash
docker compose config --quiet
docker compose up -d --wait mysql
docker compose ps
```

Consulta los logs con:

```bash
docker compose logs mysql
```

El puerto se enlaza a `127.0.0.1`. Dentro de la red Compose, el servicio se
llama `mysql` y usa el puerto interno `3306`.

Detener sin borrar datos:

```bash
docker compose down
```

Reiniciar desde una base limpia:

```bash
docker compose down -v
docker compose up -d --wait mysql
```

> [!WARNING]
> `docker compose down -v` elimina el volumen y los datos locales de MySQL.

## Ejecutar el backend

```bash
cd backend
go run ./cmd/api
```

Comprueba la API mínima:

```bash
curl http://localhost:8080/health
```

Respuesta esperada:

```text
OK
```

Construir el binario:

```bash
go build -o bin/api ./cmd/api
```

Construir la imagen Docker desde la raíz:

```bash
docker build -f backend/Dockerfile -t gurimax-api:local ./backend
```

## Base de datos y migraciones

Las migraciones están en `backend/db/migrations/`. La migración inicial se
monta en `/docker-entrypoint-initdb.d/` dentro del contenedor oficial de
MySQL y se ejecuta únicamente cuando el directorio de datos se inicializa
por primera vez.

Si modificas la migración con el volumen ya creado, reinicia el entorno de
desarrollo desde cero:

```bash
docker compose down -v
docker compose up -d --wait mysql
```

Comprueba el esquema:

```bash
docker compose exec mysql \
  mysql --protocol=tcp -h 127.0.0.1 -P 3306 \
  -u gurimax -papp_dev_password gurimax_pos \
  -e "SHOW TABLES;"
```

> [!NOTE]
> La contraseña del comando debe coincidir con `MYSQL_PASSWORD` en `.env`.
> Las migraciones estructurales no deben contener datos operativos
> arbitrarios; esos datos deben cargarse mediante procesos controlados y
> validados.

## SQLC

La configuración se encuentra en `backend/sqlc.yaml`. Utiliza MySQL como
motor, la migración inicial como esquema, `backend/db/queries` como fuente
de consultas y `backend/db/generated/sqlc` como directorio de salida.

Desde `backend`:

```bash
sqlc generate
sqlc vet
```

Las consultas actuales están organizadas en:

```text
backend/db/queries/catalog.sql
backend/db/queries/operations.sql
backend/db/queries/sales.sql
```

## Validaciones

El workflow está en `.github/workflows/ci.yml`. Durante esta etapa valida
progresivamente el backend Go, la construcción Docker, Docker Compose,
MySQL y la migración inicial. El frontend se omite mientras sus archivos no
estén inicializados.

Validaciones locales recomendadas:

```bash
git diff --check
docker compose config --quiet
gofmt -l backend
go -C backend vet ./...
go -C backend test ./...
go -C backend build ./cmd/api
```

## Estructura

```text
Sistema-GuriMAX/
├── .github/workflows/ci.yml
├── backend/
│   ├── cmd/api/main.go
│   ├── contracts/http/
│   ├── db/migrations/
│   ├── db/queries/
│   ├── internal/
│   ├── Dockerfile
│   ├── go.mod
│   └── sqlc.yaml
├── client/
│   ├── frontend/
│   ├── api_client.go
│   ├── app.go
│   ├── go.mod
│   └── wails.json
├── documentation/
├── .env.example
├── .gitignore
├── CLA.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── SECURITY.md
├── docker-compose.yml
└── README.md
```

## Roadmap

### Fundación técnica

- [x] Configurar MySQL, Docker Compose y migraciones iniciales
- [x] Configurar SQLC y organizar consultas por dominio
- [ ] Implementar la conexión MySQL en `internal/platform/mysql`
- [ ] Definir configuración, logging y manejo de errores centralizado

### Backend

- [ ] Implementar contratos HTTP y respuestas consistentes
- [ ] Crear repositorios, transacciones y casos de uso
- [ ] Implementar identidad, catálogo e inventario
- [ ] Implementar autorización contextual y auditoría para operaciones
       sensibles (caja, crédito, inventario)
- [ ] Añadir pruebas unitarias y de integración
- [ ] Construir los endpoints reales del POS

### Cliente y operación

- [ ] Inicializar el frontend Svelte
- [ ] Conectar Wails con la API Go
- [ ] Implementar autenticación, catálogo, inventario, ventas y caja
- [ ] Añadir auditoría, observabilidad, respaldos y restauración
- [ ] Separar configuración de desarrollo, pruebas y producción

## Contribución

GuriMAX sigue Trunk-Based Development ligero: ramas de vida corta,
Pull Requests pequeños hacia `main`, y revisión obligatoria para cambios
que afecten dinero, inventario, caja, crédito, permisos o migraciones.

La guía completa —convención de ramas, política de migraciones, CI
obligatorio y formato de commits— está en [`CONTRIBUTING.md`](CONTRIBUTING.md).

Antes de participar, revisa el [Código de Conducta](CODE_OF_CONDUCT.md).
Al abrir un Pull Request, aceptas los términos del
[Contributor License Agreement](CLA.md), que otorga al Proyecto los
derechos necesarios para operar bajo la Business Source License 1.1
vigente.

> [!WARNING]
> Nunca subas `.env`, contraseñas, tokens ni claves privadas.

## Seguridad

Si encuentras una vulnerabilidad, no abras un issue público. Sigue el
proceso de divulgación privada descrito en [`SECURITY.md`](SECURITY.md).

## Documentación

La carpeta `documentation/` contiene la definición de GuriMAX, el stack
tecnológico, Clean Architecture, la arquitectura evolutiva, la
implementación de la base de datos y la validación de consultas.

## Licencia

GuriMAX se distribuye bajo la **Business Source License 1.1 (BUSL-1.1)**.
En resumen:

- Puedes clonar, modificar y contribuir libremente al código.
- No está permitido el uso en producción ni la explotación comercial del
  Proyecto por parte de terceros sin autorización expresa del Licenciante.
- El **31 de diciembre de 2030**, el código se libera automáticamente bajo
  licencia MIT, quedando completamente abierto.

Consulta el archivo [`LICENSE`](LICENSE) para los términos completos.

> [!NOTE]
> El badge de licencia en la parte superior de este documento refleja el
> identificador detectado por GitHub a partir del archivo `LICENSE`.

## Referencias

- [Documentación oficial de Docker Compose](https://docs.docker.com/compose/)
- [Imagen oficial de MySQL para Docker](https://hub.docker.com/_/mysql)
- [Documentación oficial de Go](https://go.dev/doc/)
- [Documentación oficial de SQLC](https://sqlc.dev/)
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template)
- [sqlc-dev/sqlc](https://github.com/sqlc-dev/sqlc)
- [Documentación de GitHub sobre README](https://docs.github.com/es/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes)

---

<div align="center">

<a href="#gurimax">Volver al inicio</a>

</div>
