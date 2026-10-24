# Tiendas/restaurantes de destino para despacho
class Restaurant < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  before_validation { self.code = code.to_s.strip.upcase }

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
end
