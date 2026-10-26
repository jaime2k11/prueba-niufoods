#!/usr/bin/env ruby
# Script para simular la generación de órdenes hacia la API
# Uso: bundle exec ruby script/simulate_orders.rb [cantidad] [base_url]
#       bundle exec ruby script/simulate_orders.rb --list
#       bundle exec ruby script/simulate_orders.rb --help
#       API_URL=http://localhost:3000 bundle exec ruby script/simulate_orders.rb 10

require_relative '../config/environment'
require 'httparty'
require 'json'

CLIENT_NAMES = [
  'Ana Pérez', 'Juan González', 'María López', 'Pedro Silva', 'Camila Rojas',
  'Diego Martínez', 'Valentina Torres', 'Matías Fuentes', 'Fernanda Vega', 'Ignacio Morales'
].freeze

CLIENT_PHONES = [
  '+56912345678', '+56923456789', '+56934567890', '+56945678901', '+56956789012',
  '+56967890123', '+56978901234', '+56989012345', '+56990123456', '+56911223344'
].freeze

DELIVERY_ADDRESSES = [
  'Av. Providencia 1234, Santiago',
  'Av. Apoquindo 4500, Las Condes',
  'Av. Irarrázaval 2820, Ñuñoa',
  'Calle Suecia 0142, Providencia',
  'Av. Las Condes 12451, Las Condes'
].freeze

class OrderSimulator
  class << self
    def print_help
      puts <<~HELP
        Simulador de órdenes para NiuFoods

        Uso:
          bundle exec ruby script/simulate_orders.rb [cantidad] [base_url]
          bundle exec ruby script/simulate_orders.rb --list
          bundle exec ruby script/simulate_orders.rb --help
          API_URL=http://localhost:3000 bundle exec ruby script/simulate_orders.rb 10 --verbose

        Argumentos:
          cantidad    Número de órdenes a generar (por defecto: 5)
          base_url    URL base de la API (por defecto: http://localhost:3000 o API_URL)

        Opciones:
          -l, --list    Muestra IDs reales de restaurantes y productos desde la BD
          -v, --verbose Muestra el payload completo enviado y respuesta completa
          -h, --help    Muestra esta ayuda

        Ejemplos:
          bundle exec ruby script/simulate_orders.rb
          bundle exec ruby script/simulate_orders.rb 10
          bundle exec ruby script/simulate_orders.rb 20 http://localhost:3000
          bundle exec ruby script/simulate_orders.rb --list
          API_URL=http://localhost:3000 bundle exec ruby script/simulate_orders.rb 5 --verbose

        Notas:
          - Usa los IDs reales desde la base de datos (restaurantes y productos)
          - Genera órdenes con 1+ productos, cantidades variables, distintos restaurantes
          - Crea pedidos de tipo pickup y delivery aleatoriamente
          - Envía a POST /api/v1/orders
      HELP
    end

    def list_catalog
      puts "\n=== RESTAURANTES (IDs reales desde BD) ==="
      Restaurant.order(:id).each do |r|
        puts "  ID: #{r.id} | Código: #{r.code} | Nombre: #{r.name}"
      end

      puts "\n=== PRODUCTOS (IDs reales desde BD) ==="
      Product.order(:id).each do |p|
        puts "  ID: #{p.id} | SKU: #{p.sku} | #{p.name} | $#{p.price_cents} CLP"
      end
      puts "\n"
    end

    def generate_payload
      restaurants = Restaurant.all.to_a
      products = Product.all.to_a

      raise "No hay restaurantes o productos en BD. Ejecuta: bin/rails db:seed" if restaurants.empty? || products.empty?

      restaurant = restaurants.sample
      order_type = %w[pickup delivery].sample

      item_count = rand(1..4)
      selected_products = products.sample(item_count)
      items = selected_products.map do |product|
        { product_id: product.id, quantity: rand(1..3) }
      end

      payload = {
        restaurant_id: restaurant.id,
        order_type: order_type,
        customer: {
          name: CLIENT_NAMES.sample,
          phone: CLIENT_PHONES.sample
        },
        items: items
      }

      payload[:delivery_address] = DELIVERY_ADDRESSES.sample if order_type == 'delivery'
      payload
    end

    def send_order(base_url, payload, verbose: false)
      uri = "#{base_url}/api/v1/orders"

      if verbose
        puts "\n--- PAYLOAD ENVIADO ---"
        puts JSON.pretty_generate(payload)
        puts "-----------------------\n"
      end

      begin
        response = HTTParty.post(
          uri,
          body: payload.to_json,
          headers: { 'Content-Type' => 'application/json' },
          timeout: 30
        )

        if verbose
          puts "--- RESPUESTA COMPLETA ---"
          puts "Status: #{response.code} #{response.message}"
          puts "Body: #{response.body}"
          puts "--------------------------\n"
        end

        { success: response.success? || response.code == 201, code: response.code, body: response.body }
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        { success: false, code: 0, body: { error: "Timeout: #{e.message}" }.to_json }
      rescue Errno::ECONNREFUSED => e
        { success: false, code: 0, body: { error: "Conexión rechazada. ¿Está corriendo el servidor Rails? (#{e.message})" }.to_json }
      rescue StandardError => e
        { success: false, code: 0, body: { error: "Error inesperado: #{e.message}" }.to_json }
      end
    end

    def run
      args = ARGV.dup

      if args.include?('-h') || args.include?('--help')
        print_help
        return
      end

      if args.include?('-l') || args.include?('--list')
        list_catalog
        return
      end

      verbose = args.include?('-v') || args.include?('--verbose')
      args.delete('-v')
      args.delete('--verbose')

      count = 5
      if args[0] && args[0].match?(/^\d+$/)
        count = args[0].to_i
        args.shift
      end

      base_url = args[0] || ENV['API_URL'] || 'http://localhost:3000'

      puts "=== SIMULADOR DE ÓRDENES NIUFOODS ==="
      puts "Cantidad de órdenes: #{count}"
      puts "API URL: #{base_url}"
      puts "Modo verbose: #{verbose ? 'SI' : 'NO'}"
      puts "=====================================\n"

      success_count = 0
      error_count = 0

      count.times do |i|
        begin
          payload = generate_payload
          result = send_order(base_url, payload, verbose: verbose)

          if result[:code] == 201
            data = JSON.parse(result[:body]) rescue {}
            puts "[ORDEN #{i + 1}/#{count}] ✓ ÉXITO (HTTP #{result[:code]})"
            puts "  ID Orden: #{data['id']} | Total: $#{data['total_cents']} CLP | Estado despacho: #{data['dispatch_status']}"
            puts "  Restaurante: #{data['restaurant_id']} | Tipo: #{data['order_type']} | Items: #{data['items']&.size || payload[:items].size}"
            puts "  Cliente: #{data.dig('customer', 'name')} (#{data.dig('customer', 'phone')})"
            success_count += 1
          else
            error_data = JSON.parse(result[:body]) rescue { 'errors' => [result[:body]] }
            puts "[ORDEN #{i + 1}/#{count}] ✗ ERROR (HTTP #{result[:code]})"
            puts "  Errores: #{error_data['errors']&.join(', ') || error_data}"
            error_count += 1
          end
        rescue => e
          puts "[ORDEN #{i + 1}/#{count}] ✗ ERROR"
          puts "  Excepción: #{e.message}"
          error_count += 1
        end
        puts ""
      end

      puts "====================================="
      puts "RESUMEN:"
      puts "  Exitosas: #{success_count}/#{count}"
      puts "  Con errores: #{error_count}/#{count}"
      puts "====================================="
    end
  end
end

OrderSimulator.run
