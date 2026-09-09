class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy

  validates :customer_name, :email, :phone, :address, :city, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # ДДС № stays optional — not every company is VAT-registered. Checked only
  # on create so pre-existing orders with incomplete invoice data can still be
  # updated (status changes, mark_paid!).
  with_options if: :wants_invoice?, on: :create do
    validates :invoice_company, :invoice_eik, :invoice_mol, :invoice_address,
              presence: { message: "е задължително поле при заявена фактура" }
    validates :invoice_eik, format: { with: /\A\d{9}(\d{4})?\z/, message: "трябва да съдържа 9 или 13 цифри" },
              allow_blank: true
  end

  STATUSES = %w[pending confirmed shipped delivered cancelled].freeze
  validates :status, inclusion: { in: STATUSES }

  PAYMENT_METHODS = %w[card cod bank].freeze
  PAYMENT_STATUSES = %w[pending paid failed].freeze
  PAYMENT_METHOD_LABELS = {
    "card" => "Плащане с карта",
    "cod"  => "Наложен платеж",
    "bank" => "Банков превод"
  }.freeze
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }

  def payment_method_label
    PAYMENT_METHOD_LABELS[payment_method] || payment_method
  end

  def bank_transfer?
    payment_method == "bank"
  end

  # Assigns the next number in the web shop's own proforma range (see
  # config/invoice.yml). Retries on a concurrent-order collision.
  def ensure_proforma_number!
    ensure_sequential_number!(:proforma_number, :proforma_issued_at, Invoices::Config.proforma_sequence_start)
  end

  # Same for real invoices, which use their own gapless range.
  def ensure_invoice_number!
    ensure_sequential_number!(:invoice_number, :invoice_issued_at, Invoices::Config.invoice_sequence_start)
  end

  def invoiced?
    invoice_number.present?
  end

  # total_cents is the product subtotal; discount and shipping are separate.
  def subtotal
    Money.new(total_cents)
  end

  def discount
    Money.new(discount_cents)
  end

  def discount?
    discount_cents.to_i.positive?
  end

  def shipping
    Money.new(shipping_cents)
  end

  def grand_total_cents
    total_cents.to_i - discount_cents.to_i + shipping_cents.to_i
  end

  def grand_total
    Money.new(grand_total_cents)
  end

  # Kept for backwards compatibility (grand total incl. shipping).
  def total
    grand_total
  end

  def card_payment?
    payment_method == "card"
  end

  def paid?
    payment_status == "paid"
  end

  after_create_commit :reduce_stock_on_commit

  # myPOS requires a globally unique OrderID per purchase request — the plain
  # order id collides on retries and (on the shared demo store) with other
  # merchants' test orders. Issue a fresh reference for every payment attempt,
  # prefixed so it can always be traced back to this order.
  def mypos_order_ref_prefix
    "NS-#{id}-"
  end

  def issue_mypos_order_ref!
    ref = "#{mypos_order_ref_prefix}#{SecureRandom.alphanumeric(6).upcase}"
    update_column(:mypos_order_ref, ref)
    ref
  end

  # Accept the current reference, any earlier attempt for this order (a customer
  # may pay from an older tab), or the legacy bare id for orders created before
  # references existed.
  def matches_mypos_order_ref?(value)
    value = value.to_s
    value == mypos_order_ref.to_s || value.start_with?(mypos_order_ref_prefix) || value == id.to_s
  end

  def mark_paid!(trnref = nil)
    update!(payment_status: "paid", mypos_ipc_trnref: trnref, status: status == "pending" ? "confirmed" : status)
    reduce_stock!
  end

  # Decrement each product's stock once per order (guarded).
  def reduce_stock!
    return if stock_reduced?
    order_items.includes(:product).each do |item|
      item.product&.reduce_stock!(item.quantity)
    end
    update_column(:stock_reduced, true)
  end

  def mark_failed!
    update!(payment_status: "failed")
  end

  # Populates line items and the order total from a session cart, snapshotting
  # each product's name and price so the order stays accurate even if the
  # catalogue changes later.
  def populate_from_cart(cart)
    cart.each do |product, quantity|
      order_items.build(
        product: product,
        product_name: product.name,
        unit_price_cents: product.price_cents,
        quantity: quantity,
      )
    end
    self.total_cents = cart.subtotal_cents
    self.discount_cents = cart.discount_cents
  end

  private

  def ensure_sequential_number!(number_attr, issued_at_attr, sequence_start)
    return self[number_attr] if self[number_attr].present?
    attempts = 0
    begin
      next_number = [ self.class.maximum(number_attr).to_i + 1, sequence_start ].max
      update!(number_attr => next_number, issued_at_attr => Time.current)
    rescue ActiveRecord::RecordNotUnique
      (attempts += 1) <= 3 ? retry : raise
    end
    self[number_attr]
  end

  # Card orders reduce stock when payment is confirmed (mark_paid!);
  # cash-on-delivery / bank transfer reduce it as soon as the order is placed.
  def reduce_stock_on_commit
    return if card_payment? && !paid?
    reduce_stock!
  end
end
