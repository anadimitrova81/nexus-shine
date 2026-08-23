# Value object for prices. Nexus Shine sells in euro; Bulgaria's lev is pegged
# to the euro at the fixed statutory rate, so the BGN figure is always derived
# from the EUR amount rather than stored, keeping the two currencies in sync.
class Money
  BGN_PER_EUR = 1.95583

  attr_reader :cents

  def initialize(cents)
    @cents = cents.to_i
  end

  def eur
    cents / 100.0
  end

  def bgn
    (eur * BGN_PER_EUR)
  end

  def eur_formatted
    format("%.2f €", eur)
  end

  def bgn_formatted
    format("%.2f лв.", bgn)
  end

  # "46.70 € / 91.34 лв." — the dual-currency label used across the shop.
  def to_s
    "#{eur_formatted} / #{bgn_formatted}"
  end

  def zero?
    cents.zero?
  end
end
