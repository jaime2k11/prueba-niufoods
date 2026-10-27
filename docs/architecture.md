# Arquitectura y diseño de base de datos

## Flujo de una orden (alto nivel)

```mermaid
flowchart TD
  A[Cliente / Script simulate_orders.rb] --> B[API Rails POST /api/v1/orders]
  B --> C[Api::BaseController + Idempotency-Key]
  C --> D[Orders::CreateOrder - validación + transacción]
  D --> E[PostgreSQL - Order + OrderItems]
  E --> F[Sidekiq/Redis - enqueue]
  F --> G[DispatchOrderJob - idempotente]
  G --> H[Stores::DispatchClient - Idempotency-Key]
  H --> I[Simulador tienda /stores/:code/orders - idempotente]
  I -->|200 OK| J[dispatch_status = sent]
  I -->|5xx/timeouts/red| K[dispatch_status = error + retry]
  E --> L[Dashboard /orders HAML]
```

## Diseño de base de datos (ER)

```mermaid
erDiagram
  RESTAURANTS ||--o{ ORDERS : "recibe"
  ORDERS ||--|{ ORDER_ITEMS : "contiene"
  PRODUCTS ||--o{ ORDER_ITEMS : "snapshot en"
  ORDERS ||--o{ IDEMPOTENCY_KEYS : "respuestas cacheadas"
  USERS ||..o{ ORDERS : "auth dashboard (sin FK)"

  RESTAURANTS {
    bigint id PK
    string code UK "PROV/LCON/NUNO"
    string name
    datetime created_at
    datetime updated_at
  }

  PRODUCTS {
    bigint id PK
    string sku UK "SKU-001..SKU-010"
    string name
    bigint price_cents "CLP entero"
    datetime created_at
    datetime updated_at
  }

  ORDERS {
    bigint id PK
    bigint restaurant_id FK
    integer order_type "0=pickup 1=delivery"
    string customer_name
    string customer_phone
    string delivery_address
    bigint total_cents "calculado servidor"
    integer dispatch_status "0=pending 1=sent 2=error"
    integer dispatch_attempts "default 0"
    datetime dispatched_at
    datetime last_dispatched_at
    text dispatch_error
    datetime created_at
    datetime updated_at
  }

  ORDER_ITEMS {
    bigint id PK
    bigint order_id FK
    bigint product_id FK
    integer quantity "> 0"
    bigint unit_price_cents "copia precio producto"
  }

  USERS {
    bigint id PK
    string email UK
    string password_digest
    datetime created_at
    datetime updated_at
  }

  IDEMPOTENCY_KEYS {
    bigint id PK
    string key UK
    string request_hash
    bigint order_id FK
    integer status_code
    text response_body
    datetime expires_at
    datetime created_at
    datetime updated_at
  }
```

## Explicación de tablas

- **restaurants**: Tiendas destino. `code` único (usado por el simulador).
- **products**: Catálogo global compartido entre restaurantes.
- **orders**: Cabecera de orden. `total_cents` siempre calculado desde `order_items` (nunca se confía en lo que envíe el cliente). `dispatch_status` controla el envío a tienda. `dispatch_attempts` y `last_dispatched_at` para trazabilidad.
- **order_items**: Detalle con `unit_price_cents` copiado al crear el item (snapshot). Garantiza integridad histórica.
- **users**: Solo para autenticación del dashboard por sesión/cookies. No se relaciona con órdenes.
- **idempotency_keys**: Cache de respuestas para peticiones idempotentes a la API (header `Idempotency-Key`), con hash del request y TTL.

## Decisiones clave

- **Snapshot de precio**: Evita que cambios futuros de precio afecten órdenes ya registradas.
- **Cálculo server-side**: Crítico para integridad (criterio "Integridad").
- **Enums con prefijo**: `order_type_*` / `dispatch_status_*` evitan colisiones.
- **Catálogo global**: Más simple para este dataset; se puede evolucionar a menú por tienda si fuera necesario.
- **User auth-only**: La API es pública según el enunciado.
- **Servicio transaccional**: `Orders::CreateOrder` encapsula creación de orden+items en transacción, cálculo de total y encolado.
- **Idempotencia**: API con `Idempotency-Key` (cacheo + validación de hash), cliente HTTP y job evitan reenvíos duplicados, simulador de tienda idempotente por `order_id`.
- **Reintentos controlados**: Solo ante errores transitorios (red/5xx/timeouts). No se reintenta ante 4xx. Backoff polinómico con `retry_on`.
- **Dashboard con HAML**: Vistas clásicas Rails con badges, paginación `limit/offset`, `includes` para evitar N+1.
- **Simulador de órdenes**: Script Ruby con HTTParty, soporte `API_URL`, `--list`, `--verbose` para generar y enviar órdenes aleatorias.
- **Store headers compatibles con Rack 3**: Headers no congelados, claves en minúsculas.
