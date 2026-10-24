require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:prov)
    @product = products(:sushi1)
  end

  test "delivery requires address" do
    order = Order.new(restaurant: @restaurant, order_type: :delivery, customer_name: "Ana", customer_phone: "+56912345678")
    order.order_items.build(product: @product, quantity: 1)
    assert_not order.valid?
    assert_includes order.errors[:delivery_address], "can't be blank"
  end

  test "pickup does not require address" do
    order = Order.new(restaurant: @restaurant, order_type: :pickup, customer_name: "Ana", customer_phone: "+56912345678")
    order.order_items.build(product: @product, quantity: 1)
    assert order.valid?
  end

  test "recalculates total from item snapshots" do
    order = Order.new(restaurant: @restaurant, order_type: :pickup, customer_name: "Ana", customer_phone: "+56912345678")
    order.order_items.build(product: @product, quantity: 2)
    order.save!(validate: false)
    order.recalculate_total!
    assert_equal 8990 * 2, order.reload.total_cents
  end
end
