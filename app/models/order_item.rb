# Item de orden con snapshot de precio (unit_price_cents)
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  before_validation :copy_price_from_product
  before_save :copy_price_from_product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: :order_id }

  # Cálculo de subtotal
  def subtotal_cents
    quantity.to_i * unit_price_cents.to_i
  end

  private

  def copy_price_from_product
    if (unit_price_cents.nil? || unit_price_cents.to_s == "" || unit_price_cents == 0) && product
      self.unit_price_cents = product.price_cents
    elsif (unit_price_cents.nil? || unit_price_cents.to_s == "" || unit_price_cents == 0) && product_id.present?
      prod = Product.find_by(id: product_id)
      self.unit_price_cents = prod.price_cents if prod
    end
  end
end
