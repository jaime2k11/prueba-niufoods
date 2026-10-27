# Job asíncrono para despachar las órdenes a la tienda simulada. Usa Sidekiq + Redis
class DispatchOrderJob < ApplicationJob
  queue_as :default

  # Definición de reintentos ante errores (conexión/timeouts/errores 5xx, etc)
  retry_on Stores::DispatchClient::DispatchError, wait: :polynomially_longer, attempts: 5

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    return if order.dispatch_status_sent?

    order.increment!(:dispatch_attempts)
    order.update!(last_dispatched_at: Time.current)

    # Se marca como enviado si el despacho fue exitoso
    Stores::DispatchClient.new.call(order)
    order.update!(dispatch_status: 'sent') if order.respond_to?(:dispatch_status=)
  rescue Stores::DispatchClient::DispatchError
    order.update!(dispatch_status: 'error') if order&.respond_to?(:dispatch_status=)
    raise
  rescue ActiveRecord::RecordNotFound
    # Si la orden ya no existe, no se hace nada más
  end
end
