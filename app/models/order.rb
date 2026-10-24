# Orden recibida via API.
# Se considera total calculado en servidor desde items (snapshot de precio)
class Order < ApplicationRecord
  belongs_to :restaurant
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  enum order_type: { pickup: 0, delivery: 1 }, _prefix: true
  enum dispatch_status: { pending: 0, sent: 1, error: 2 }, _prefix: true

  validates :order_type, presence: true
  validates :dispatch_status, presence: true
  validates :customer_name, presence: true
  validates :customer_phone, presence: true
  validates :total_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :restaurant, presence: true
  validate :delivery_address_required_for_delivery
  validate :must_have_at_least_one_item

  # Recalcular el total sumando quantity * unit_price_cents de los items
  def recalculate_total!
    sum = order_items.sum("quantity * unit_price_cents")
    update_column(:total_cents, sum)
  end

  private

  def delivery_address_required_for_delivery
    if order_type_delivery? && delivery_address.to_s.strip.blank?
      errors.add(:delivery_address, :blank)
    end
  end

  def must_have_at_least_one_item
    # Se debe exigir al menos un item de orden
    items = order_items.to_a.reject(&:marked_for_destruction?)
    if items.empty?
      errors.add(:order_items, :blank)
    end
  end
end
