module Orders
  class CreateOrder
    Result = Struct.new(:success?, :data, :errors, keyword_init: true)

    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params.to_h.deep_symbolize_keys
    end

    def call
      restaurant = Restaurant.find_by(id: @params[:restaurant_id])
      return failure(['Restaurant not found']) unless restaurant

      order_type = @params[:order_type]
      return failure(['Invalid order_type']) unless %w[pickup delivery].include?(order_type.to_s)

      items_params = @params[:items]
      return failure(['Items are required']) if items_params.blank?

      order = nil

      ActiveRecord::Base.transaction do
        order = Order.new(
          restaurant: restaurant,
          order_type: order_type,
          customer_name: @params.dig(:customer, :name),
          customer_phone: @params.dig(:customer, :phone),
          delivery_address: @params[:delivery_address]
        )

        items_params.each do |item_param|
          item_h = item_param.is_a?(Hash) ? item_param : item_param.to_h
          product = Product.find_by(id: item_h[:product_id])
          raise ActiveRecord::RecordInvalid.new(order) unless product

          quantity = item_h[:quantity].to_i
          order.order_items.build(product: product, quantity: quantity)
        end

        order.save!
        order.recalculate_total!
      end

      DispatchOrderJob.perform_later(order.id)

      success(order_response(order))
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.presence || [e.message])
    rescue ActiveRecord::RecordNotFound => e
      failure([e.message])
    rescue ArgumentError => e
      failure([e.message])
    end

    private

    def success(data)
      Result.new(success?: true, data: data, errors: [])
    end

    def failure(errors)
      Result.new(success?: false, data: nil, errors: Array(errors))
    end

    def order_response(order)
      order.reload
      {
        id: order.id,
        restaurant_id: order.restaurant_id,
        order_type: order.order_type,
        customer: {
          name: order.customer_name,
          phone: order.customer_phone
        },
        delivery_address: order.delivery_address,
        total_cents: order.total_cents,
        dispatch_status: order.dispatch_status,
        created_at: order.created_at,
        items: order.order_items.includes(:product).map do |oi|
          {
            product_id: oi.product_id,
            product_name: oi.product&.name,
            quantity: oi.quantity,
            unit_price_cents: oi.unit_price_cents,
            subtotal_cents: oi.subtotal_cents
          }
        end
      }
    end
  end
end
