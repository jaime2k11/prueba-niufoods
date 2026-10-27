class IdempotencyKey < ApplicationRecord
  belongs_to :order, optional: true

  validates :key, presence: true, uniqueness: true
  validates :expires_at, presence: true
end
