class OrderMailer < ApplicationMailer
  default from: -> { Invoices::Config.email_from }

  # Bank transfer instructions with the proforma invoice attached.
  def bank_instructions(order)
    @order = order
    @bank = Invoices::Config.bank
    order.ensure_proforma_number!

    pdf = Invoices::DocumentPdf.new(order, kind: :proforma)
    attachments[pdf.filename] = { mime_type: "application/pdf", content: pdf.render }

    mail(to: order.email, subject: "Поръчка ##{order.id} — данни за плащане по банков път")
  end
end
