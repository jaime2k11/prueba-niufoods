# NiuFoods - Prueba de código para manejo de órdenes

## Estructura base definida

- **Framework**: Rails 7.1 / Ruby 3.3.1
- **Base de datos**: PostgreSQL
- **Background jobs**: Sidekiq (configurado vía `config.active_job.queue_adapter = :sidekiq`) + initializer para `REDIS_URL`
- **HTTP**: HTTParty (para despacho a tienda)
- **Gemas base**: `sidekiq ~> 7.3`, `connection_pool ~> 2.4`, `json ~> 2.7`, `httparty`, `bcrypt ~> 3.1.7`, `dotenv-rails` (dev/test), `minitest ~> 5.25` (test)

## Autenticación (método simple)
- **Tipo**: Basada en sesión/cookies, pensada para autenticación en dashboard web, sin auth para API
- **Modelo**: `User` con `has_secure_password` (`bcrypt`)
- **Flujo**: Si hay usuario logueado, se permite acceder al listado/detalle de órdenes (`/orders`); en caso contrario, se redirige a `/login`
- **Rutas**: `GET/POST /login`, `DELETE /logout`
- **Sin roles/permisos** por ahora. Sólo es necesario iniciar sesión

## Seeds
- Ejecutar: `bin/rails db:seed`
- Crea usuarios iniciales: `admin@niufoods.cl` / `test@niufoods.cl` (password: `password123`)

## Base de datos
- Configuración en `config/database.yml` lee variables desde `.env` (`DATABASE_HOST/PORT/USERNAME/PASSWORD/DATABASE_NAME`) sin hardcodear credenciales
- Crear `.env` desde `.env.example` y completar valores
- Comandos para inicializar BD correctamente: `bin/rails db:create db:migrate db:seed`

## Componentes para despacho

### Servicio Rack para simular recepción de órdenes por parte de la tienda
Ubicado en `store_simulator/config.ru`. Simula dos casos con probabilidad configurable:

1. **Error de servidor instantáneo** (por defecto 20%): responde `500` con `{"status":"error", ...}`
2. **Demora de respuesta** (por defecto 20%): espera aleatoriamente entre 10 y 40 segundos antes de responder `200`

Variables configurables:
```bash
STORE_ERROR_PROB=0.20 STORE_DELAY_PROB=0.20 STORE_DELAY_MIN=10 STORE_DELAY_MAX=40
```

Levantar:
```bash
bundle exec rackup store_simulator/config.ru -p 3001
```

### Job asíncrono para despacho (app principal)
- `app/jobs/dispatch_order_job.rb` usa `Stores::DispatchClient` para enviar la orden al simulador de tienda
- Se encola con `DispatchOrderJob.perform_later(order.id)`
- Reintentos con backoff ante errores de conexión/timeout o respuestas no exitosas
- Actualiza `dispatch_status` a `sent` o `error` cuando corresponda

### Sidekiq + Redis
- Configurado en `config/application.rb` (`config.active_job.queue_adapter = :sidekiq`)
- Inicializador en `config/initializers/sidekiq.rb` lee `REDIS_URL` (por defecto `redis://localhost:6379/0`)
- **Importante**: usar el **mismo** `REDIS_URL` en `bin/rails s` y `bin/sidekiq`

## Cómo levantar todo el sistema
```bash
# 0) Preparar entorno
cp .env.example .env  # completar credenciales
bundle install
bin/rails db:create db:migrate db:seed

# 1) Redis
redis-server

# 2) API + Dashboard (mismo REDIS_URL)
REDIS_URL=redis://localhost:6379/0 STORE_URL=http://localhost:3001 bin/rails s

# 3) Worker Sidekiq (mismo REDIS_URL)
REDIS_URL=redis://localhost:6379/0 STORE_URL=http://localhost:3001 bin/sidekiq -q default

# 4) Servicio simulador de tienda
STORE_URL=http://localhost:3001  # por defecto
bundle exec rackup store_simulator/config.ru -p 3001
```

## Arquitectura y modelo de datos
Ver [docs/architecture.md](docs/architecture.md) para diagrama de flujo, ER y decisiones de diseño.

**Modelos principales:** `Restaurant`, `Product`, `Order`, `OrderItem`. 
- Catálogo global de productos.
- `OrderItem` guarda `unit_price_cents` (snapshot) al crear el item.
- `Order.total_cents` se calcula en servidor desde los items.
- `User` solo para autenticación del dashboard.
