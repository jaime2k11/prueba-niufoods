# NiuFoods - Prueba de código para manejo de órdenes

## Estructura base definida

- **Framework**: Rails 7.1 / Ruby 3.3.1
- **Base de datos**: PostgreSQL
- **Background jobs**: Sidekiq (configurado vía `config.active_job.queue_adapter = :sidekiq`) + initializer para `REDIS_URL`
- **HTTP**: HTTParty (para despacho a tienda)
- **Vistas**: HAML (haml-rails)
- **Gemas base**: `sidekiq ~> 7.3`, `connection_pool ~> 2.4`, `json ~> 2.7`, `httparty`, `bcrypt ~> 3.1.7`, `dotenv-rails` (dev/test), `minitest ~> 5.25` (test), `haml-rails`

## Autenticación (método simple)
- **Tipo**: Basada en sesión/cookies, pensada para autenticación en dashboard web, sin auth para API
- **Modelo**: `User` con `has_secure_password` (`bcrypt`)
- **Flujo**: Si hay usuario logueado, se permite acceder al listado/detalle de órdenes (`/orders`); en caso contrario, se redirige a `/login`
- **Rutas**: `GET/POST /login`, `DELETE /logout`
- **Sin roles/permisos** por ahora. Sólo es necesario iniciar sesión

## Dataset y seeds
- Ejecutar: `bin/rails db:seed`
- Crea usuarios iniciales: `admin@niufoods.cl` / `test@niufoods.cl` (password: `password123`)
- Crea restaurantes: PROV (Niu Foods Providencia), LCON (Niu Foods Las Condes), NUNO (Niu Foods Ñuñoa)
- Crea 10 productos con SKUs SKU-001 a SKU-010 y precios en CLP

## Base de datos
- Configuración en `config/database.yml` lee variables desde `.env` (`DATABASE_HOST/PORT/USERNAME/PASSWORD/DATABASE_NAME` u opciones PG*)
- Crear `.env` desde `.env.example` y completar valores
- Comandos para inicializar BD correctamente: `bin/rails db:create db:migrate db:seed`

## Modelos principales
- `Restaurant` (code único, has_many orders)
- `Product` (sku único, catálogo global, has_many order_items)
- `Order` (belongs_to restaurant, has_many order_items, enums order_type/dispatch_status, totales calculados server-side)
- `OrderItem` (snapshot de precio unit_price_cents, cantidad > 0)
- `User` (auth solo para dashboard)
- `IdempotencyKey` (cacheo de respuestas idempotentes para API)

## API
**Endpoint:** `POST /api/v1/orders`

**Payload de ejemplo:**
```json
{
  "restaurant_id": 1,
  "order_type": "delivery",
  "customer": {
    "name": "Ana Pérez",
    "phone": "+56912345678"
  },
  "delivery_address": "Av. Providencia 1234, Santiago",
  "items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 5, "quantity": 1 }
  ]
}
```

**Notas API:**
- Usa `Orders::CreateOrder` (transaccional). Total calculado desde precios de BD, se ignora total enviado por cliente.
- Idempotencia: enviar header `Idempotency-Key`. Si misma key con mismo body retorna respuesta cacheada. Si mismo key con body distinto retorna `409 Conflict`. TTL 24h.
- Respuestas: `201` con orden + items, `422` errores de validación, `400` JSON inválido/parámetros faltantes.
- Al crear exitosamente se encola `DispatchOrderJob.perform_later(order.id)`.

## Componentes para despacho

### Servicio Rack para simular recepción de órdenes por parte de la tienda
Ubicado en `store_simulator/config.ru`. Idempotente por `order_id` (responde `200` con `duplicate: true` en reintentos). Simula dos casos con probabilidad configurable:

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
- `app/jobs/dispatch_order_job.rb` usa `Stores::DispatchClient` para enviar la orden al simulador
- Se encola con `DispatchOrderJob.perform_later(order.id)`
- No reenvía si ya está `sent`. Incrementa `dispatch_attempts` y actualiza `last_dispatched_at`
- Reintentos con backoff polinómico ante errores transitorios (red/timeouts/5xx). No reintenta ante 4xx
- Actualiza `dispatch_status` a `sent` o `error`

### Sidekiq + Redis
- Configurado en `config/application.rb` (`config.active_job.queue_adapter = :sidekiq`)
- Inicializador en `config/initializers/sidekiq.rb` lee `REDIS_URL` (por defecto `redis://localhost:6379/0`)
- **Importante**: usar el **mismo** `REDIS_URL` en `bin/rails s` y `bin/sidekiq`

## Simulador de órdenes (script)
`script/simulate_orders.rb` genera órdenes aleatorias usando el dataset de BD y las envía al API.

```bash
# Listar IDs reales de restaurantes y productos
bundle exec ruby script/simulate_orders.rb --list

# Enviar 5 órdenes (por defecto)
bundle exec ruby script/simulate_orders.rb

# Enviar 20 órdenes a URL específica
bundle exec ruby script/simulate_orders.rb 20 http://localhost:3000

# Usando variable de entorno
API_URL=http://localhost:3000 bundle exec ruby script/simulate_orders.rb 10

# Modo verbose (muestra payload y respuesta completa)
bundle exec ruby script/simulate_orders.rb 5 --verbose
```

Genera 1+ productos, cantidades variables, distintos restaurantes, ambos tipos (pickup/delivery). Usa `HTTParty`. Maneja respuestas exitosas/errores y excepciones.

## Dashboard web
Accesible en `/orders` (requiere sesión iniciada). Muestra: ID orden, restaurante/tienda, tipo de pedido (Retiro/Delivery con badge), monto total, estado de despacho (pendiente/enviado/error con badge), fecha/hora creación. En detalle se muestran cliente, dirección (si delivery), items con cantidades/precios/subtotales e información de despacho.

Vistas en HAML con estilos CSS simples tipo bootstrap-like. Paginación con `limit/offset`.

## Cómo levantar todo el sistema
```bash
# 0) Preparar entorno (Ejecución una sola vez)
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
bundle exec rackup store_simulator/config.ru -p 3001
```

## Tests
```bash
bin/rails test
bin/rails test test/models/order_test.rb
bin/rails test test/controllers/api/v1/orders_controller_test.rb
```

## Arquitectura y modelo de datos
Ver [docs/architecture.md](docs/architecture.md) para diagrama de flujo, ER y decisiones de diseño.

**Modelos principales:** `Restaurant`, `Product`, `Order`, `OrderItem`, `User`, `IdempotencyKey`. 
- Catálogo global de productos.
- `OrderItem` guarda `unit_price_cents` (snapshot) al crear el item.
- `Order.total_cents` se calcula en servidor desde los items.
- `User` solo para autenticación del dashboard.
- Idempotencia en API y despacho hacia tienda.
