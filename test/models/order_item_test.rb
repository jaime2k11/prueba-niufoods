require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:prov)
    @product = products(:sushi1)
    @order = Order.new(restaurant: @restaurant, order_type: :pickup, customer_name: "Ana", customer_phone: "+56912345678")
    @order.save!(validate: false)
  end

  test "copies price from product" do
    item = OrderItem.create!(order: @order, product: @product, quantity: 1)
    assert_equal @product.price_cents, item.unit_price_cents
  end

  test "rejects quantity zero or negative" do
    item = OrderItem.new(order: @order, product: @product, quantity: 0)
    assert_not item.valid?
    item.quantity = -1
    assert_not item.valid?
  end

  test "computes subtotal" do
    item = OrderItem.create!(order: @order, product: @product, quantity: 3)
    assert_equal @product.price_cents * 3, item.subtotal_cents
  end
end
