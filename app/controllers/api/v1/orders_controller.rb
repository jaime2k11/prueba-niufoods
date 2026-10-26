module Api
  module V1
    class OrdersController < Api::BaseController
      def create
        result = Orders::CreateOrder.call(order_params)

        if result.success?
          render json: result.data, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_content
        end
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
