require "test_helper"

class Api::V1::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restaurant = restaurants(:prov)
    @product1 = products(:sushi1)
    @product2 = products(:sushi2)
  end

  test "creates order successfully for pickup" do
    assert_enqueued_with(job: DispatchOrderJob) do
      post api_v1_orders_path, params: {
        restaurant_id: @restaurant.id,
        order_type: 'pickup',
        customer: { name: 'Ana Pérez', phone: '+56912345678' },
        items: [
          { product_id: @product1.id, quantity: 2 },
          { product_id: @product2.id, quantity: 1 }
        ]
      }.to_json, headers: { 'Content-Type' => 'application/json' }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal @restaurant.id, json['restaurant_id']
    assert_equal 'pickup', json['order_type']
    assert_equal 8990 * 2 + 7490, json['total_cents']
    assert_equal 'pending', json['dispatch_status']
    assert_equal 2, json['items'].size
  end

  test "creates order successfully for delivery with address" do
    post api_v1_orders_path, params: {
      restaurant_id: @restaurant.id,
      order_type: 'delivery',
      customer: { name: 'Juan', phone: '+56987654321' },
      delivery_address: 'Av. Providencia 1234, Santiago',
      items: [
        { product_id: @product1.id, quantity: 1 }
      ]
    }.to_json, headers: { 'Content-Type' => 'application/json' }

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 'delivery', json['order_type']
    assert_equal 'Av. Providencia 1234, Santiago', json['delivery_address']
  end

  test "returns 422 when delivery missing address" do
    post api_v1_orders_path, params: {
      restaurant_id: @restaurant.id,
      order_type: 'delivery',
      customer: { name: 'Ana', phone: '+56912345678' },
      items: [
        { product_id: @product1.id, quantity: 1 }
      ]
    }.to_json, headers: { 'Content-Type' => 'application/json' }

    assert_response :unprocessable_content
  end

  test "returns 422 when items empty" do
    post api_v1_orders_path, params: {
      restaurant_id: @restaurant.id,
      order_type: 'pickup',
      customer: { name: 'Ana', phone: '+56912345678' },
      items: []
    }.to_json, headers: { 'Content-Type' => 'application/json' }

    assert_response :unprocessable_content
  end

  test "returns 422 when restaurant not found" do
    post api_v1_orders_path, params: {
      restaurant_id: 999999,
      order_type: 'pickup',
      customer: { name: 'Ana', phone: '+56912345678' },
      items: [
        { product_id: @product1.id, quantity: 1 }
      ]
    }.to_json, headers: { 'Content-Type' => 'application/json' }

    assert_response :unprocessable_content
  end

  test "returns 422 when product not found" do
    post api_v1_orders_path, params: {
      restaurant_id: @restaurant.id,
      order_type: 'pickup',
      customer: { name: 'Ana', phone: '+56912345678' },
      items: [
        { product_id: 999999, quantity: 1 }
      ]
    }.to_json, headers: { 'Content-Type' => 'application/json' }

    assert_response :unprocessable_content
  end

  test "ignores client total and calculates server side" do
    post api_v1_orders_path, params: {
      restaurant_id: @restaurant.id,
      order_type: 'pickup',
      customer: { name: 'Ana', phone: '+56912345678' },
      total_cents: 1,
      items: [
        { product_id: @product1.id, quantity: 2 }
      ]
    }.to_json, headers: { 'Content-Type' => 'application/json' }

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 8990 * 2, json['total_cents']
  end
end
