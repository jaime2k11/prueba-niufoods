# Catálogo global de productos (compartido entre restaurantes)
class Product < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error

  before_validation { self.sku = sku.to_s.strip.upcase }

  validates :sku, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :price_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
