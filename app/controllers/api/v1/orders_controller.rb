module Api
  module V1
    class OrdersController < Api::BaseController
      def create
        result = with_idempotency do
          svc_result = Orders::CreateOrder.call(order_params)

          if svc_result.success?
            { status: :created, body: svc_result.data }
          else
            { status: :unprocessable_content, body: { errors: svc_result.errors } }
          end
        end
        render_from_result(result) unless performed?
      rescue ActionDispatch::Http::Parameters::ParseError
        render json: { errors: ['Invalid JSON payload'] }, status: :bad_request
      rescue ArgumentError => e
        render json: { errors: [e.message] }, status: :unprocessable_content
      end

      private

      def order_params
        params.require(:restaurant_id)
        params.require(:order_type)
        params.require(:items)
        params.permit(
          :restaurant_id,
          :order_type,
          :delivery_address,
          customer: [:name, :phone],
          items: [:product_id, :quantity]
        )
      rescue ActionController::ParameterMissing => e
        raise ArgumentError, e.message
      end
    end
  end
end
