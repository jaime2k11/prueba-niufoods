class OrdersController < ApplicationController
  before_action :require_login

  def index
    per_page = 20
    offset = params[:offset].to_i
    @orders = Order.includes(:restaurant)
                   .order(created_at: :desc)
                   .limit(per_page)
                   .offset(offset)
    @next_offset = offset + per_page
    @prev_offset = [offset - per_page, 0].max
    @has_more = Order.count > @next_offset
  end

  def show
    @order = Order.includes(order_items: :product).find(params[:id])
  end
end
