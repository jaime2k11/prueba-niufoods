require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product" do
    p = Product.new(sku: "SKU-999", name: "Test", price_cents: 1000)
    assert p.valid?
  end

  test "rejects negative price" do
    p = Product.new(sku: "SKU-998", name: "Test", price_cents: -1)
    assert_not p.valid?
  end

  test "requires unique sku" do
    p = Product.new(sku: "sku-001", name: "Dup", price_cents: 1000)
    assert_not p.valid?
  end
end
