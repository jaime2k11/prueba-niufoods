module Stores
  # Cliente HTTP simple para enviar órdenes al servicio simulador de tienda
  class DispatchClient
    class DispatchError < StandardError; end

    def initialize(base_url: ENV.fetch('STORE_URL', 'http://localhost:3001'))
      @base_url = base_url
    end

    def call(order)
      payload = {
        order_id: order.id,
        restaurant_code: order.try(:restaurant)&.try(:code),
        order_type: order.try(:order_type),
        total_cents: order.try(:total_cents),
        customer_name: order.try(:customer_name),
        customer_phone: order.try(:customer_phone),
        delivery_address: order.try(:delivery_address)
      }

      response = HTTParty.post(
        "#{@base_url}/stores/#{order.try(:restaurant)&.try(:code) || 'UNKNOWN'}/orders",
        body: payload.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: 60
      )

      unless response.success?
        raise DispatchError, "Store respondió con status #{response.code}"
      end

      response
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
      raise DispatchError, e.message
    end
  end
end
