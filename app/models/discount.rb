# Automatic volume discount: 10% off the product subtotal once it exceeds
# 300 €. Applied in the cart and snapshotted onto the order at checkout.
module Discount
  THRESHOLD_CENTS = 30_000
  PERCENT = 10

  module_function

  def applies?(subtotal_cents)
    subtotal_cents.to_i > THRESHOLD_CENTS
  end

  def cents_for(subtotal_cents)
    return 0 unless applies?(subtotal_cents)
    (subtotal_cents.to_i * PERCENT / 100.0).round
  end

  # How much more the customer needs to add to unlock the discount (0 if unlocked).
  def remaining_cents(subtotal_cents)
    return 0 if applies?(subtotal_cents)
    [THRESHOLD_CENTS - subtotal_cents.to_i, 1].max
  end

  def label
    "Отстъпка #{PERCENT}%"
  end

  def threshold
    Money.new(THRESHOLD_CENTS)
  end
end
