# NiuFoods - Prueba de código para manejo de órdenes

## Estructura base definida

- **Framework**: Rails 7.1 / Ruby 3.3.1
- **Base de datos**: PostgreSQL
- **Background jobs**: Sidekiq (configurado vía `config.active_job.queue_adapter = :sidekiq`) + initializer para `REDIS_URL`
- **HTTP**: HTTParty (para simular el despacho a tienda)
- **Gemas base**: `sidekiq ~> 7.3`, `connection_pool ~> 2.4`, `json ~> 2.7`, `httparty`, `bcrypt ~> 3.1.7`, `minitest ~> 5.25` (test)

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
- Configuración en `config/database.yml`. Idealmente dejar credenciales en variables de entorno (revisar archivo .env.example y copiarlo a .env)
- Comandos para inicializar BD correctamente: `bin/rails db:create db:migrate db:seed`

## Cómo ejecutar la aplicación
```bash
bundle install
bin/rails db:create db:migrate db:seed
redis-server        # requerido por Sidekiq
bin/rails s
```