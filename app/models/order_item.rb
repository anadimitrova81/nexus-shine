class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :product_name, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  def unit_price
    Money.new(unit_price_cents)
  end

  def subtotal
    Money.new(unit_price_cents * quantity)
  end
end
