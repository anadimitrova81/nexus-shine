# Preview at http://localhost:3050/rails/mailers/order_mailer
class OrderMailerPreview < ActionMailer::Preview
  def confirmation_cash_on_delivery = OrderMailer.confirmation(sample_order("cod"))
  def confirmation_bank_transfer    = OrderMailer.confirmation(sample_order("bank"))
  def confirmation_card_paid        = OrderMailer.confirmation(sample_order("card"))

  private

  # Unsaved order with realistic data; numbers are preset so the PDF
  # attachments render without touching the invoice sequences.
  def sample_order(payment_method)
    order = Order.new(
      id: 1042, created_at: Time.current,
      customer_name: "Мария Иванова", email: "maria@example.com", phone: "0888 123 456",
      address: "ул. Витоша 15", city: "Пловдив", postal_code: "4000",
      payment_method: payment_method, payment_status: payment_method == "card" ? "paid" : "pending",
      mypos_ipc_trnref: payment_method == "card" ? "502845" : nil,
      shipping_method: "office", shipping_label: "Пловдив – Тракия, бул. Освобождение 3", shipping_cents: 650,
      wants_invoice: payment_method != "bank",
      invoice_company: "Автомивка Блясък ЕООД", invoice_eik: "204567891", invoice_mol: "Мария Иванова", invoice_address: "гр. Пловдив, ул. Витоша 15",
      invoice_number: payment_method == "bank" ? nil : 7_000_000_042, invoice_issued_at: Time.current,
      proforma_number: payment_method == "bank" ? 9_000_000_042 : nil, proforma_issued_at: Time.current,
    )
    [["ERA 111 Super Naturemax – Шампоан за килими", 16_000, 2], ["TURBOPAX – Блясък за гуми 5 кг", 4_800, 1]].each do |name, cents, qty|
      order.order_items.build(product_name: name, unit_price_cents: cents, quantity: qty)
    end
    order.total_cents = order.order_items.sum { |i| i.unit_price_cents * i.quantity }
    order.discount_cents = Discount.cents_for(order.total_cents)
    order
  end
end
