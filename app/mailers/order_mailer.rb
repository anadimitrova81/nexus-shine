class OrderMailer < ApplicationMailer
  # Order confirmation for the customer. Sent when a cash-on-delivery or bank
  # transfer order is placed, and for card orders once myPOS confirms payment.
  # Bank transfer orders get the proforma invoice and bank details; orders that
  # asked for an invoice (and already have a number) get the invoice attached.
  def confirmation(order)
    @order = order
    @bank = Invoices::Config.bank if order.bank_transfer?

    if order.bank_transfer?
      order.ensure_proforma_number!
      attach_pdf(Invoices::DocumentPdf.new(order, kind: :proforma))
    elsif order.invoiced?
      attach_pdf(Invoices::DocumentPdf.new(order, kind: :invoice))
    end

    mail(to: order.email, subject: "Поръчка ##{order.id} в Nexus Shine — потвърждение")
  end

  # Kept for compatibility: the bank instructions are now part of #confirmation.
  alias_method :bank_instructions, :confirmation

  private

  def attach_pdf(pdf)
    attachments[pdf.filename] = { mime_type: "application/pdf", content: pdf.render }
  end
end
