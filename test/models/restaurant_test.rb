require "test_helper"

class RestaurantTest < ActiveSupport::TestCase
  test "normalizes code to upcase" do
    r = Restaurant.new(code: "prov", name: "Test")
    r.valid?
    assert_equal "PROV", r.code
  end

  test "requires unique code" do
    r = Restaurant.new(code: "prov", name: "Dup")
    assert_not r.valid?
    assert_includes r.errors[:code], "has already been taken"
  end
end
