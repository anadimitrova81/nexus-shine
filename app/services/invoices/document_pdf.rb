require "prawn"
require "prawn/table"

module Invoices
  # Renders proforma invoices (kind: :proforma) and real invoices
  # (kind: :invoice). Layout mirrors the invoices issued by the accounting
  # software, plus a supplier bank details box where payment is by bank.
  class DocumentPdf
    FONT_DIR = Rails.root.join("app/assets/fonts")
    LOGO = Rails.root.join("app/assets/images/nexus-shine-logo.png")

    BORDER = "999999".freeze
    LABEL_BG = "eeeeee".freeze

    KINDS = {
      proforma: { title: "Проформа фактура", file_prefix: "proforma" },
      invoice: { title: "Фактура", file_prefix: "invoice" }
    }.freeze

    def initialize(order, kind: :proforma)
      @order = order
      @kind = kind.to_sym
      raise ArgumentError, "unknown document kind #{kind}" unless KINDS.key?(@kind)
      @seller = Config.seller
      @bank = Config.bank
    end

    def render
      doc.render
    end

    def filename
      "#{KINDS[@kind][:file_prefix]}-#{number}.pdf"
    end

    private

    def invoice? = @kind == :invoice

    def number
      invoice? ? @order.invoice_number : @order.proforma_number
    end

    def issued_at
      invoice? ? @order.invoice_issued_at : @order.proforma_issued_at
    end

    def doc
      @doc ||= Prawn::Document.new(page_size: "A4", margin: 40).tap do |pdf|
        pdf.font_families.update("DejaVu" => {
          normal: FONT_DIR.join("DejaVuSans.ttf").to_s,
          bold: FONT_DIR.join("DejaVuSans-Bold.ttf").to_s
        })
        pdf.font("DejaVu")
        pdf.font_size(9)

        header(pdf)
        parties(pdf)
        title_block(pdf)
        items_table(pdf)
        totals(pdf)
        notes(pdf)
        bank_details(pdf) if !invoice? || @order.bank_transfer?
        signatures(pdf)
      end
    end

    def header(pdf)
      pdf.image(LOGO.to_s, width: 150, position: :right) if LOGO.exist?
      pdf.move_down 20
    end

    def parties(pdf)
      buyer = buyer_rows
      seller = seller_rows
      width = pdf.bounds.width / 2 - 10

      y = pdf.cursor
      pdf.bounding_box([ 0, y ], width: width) do
        party_box(pdf, "ПОЛУЧАТЕЛ", buyer, width)
      end
      pdf.bounding_box([ width + 20, y ], width: width) do
        party_box(pdf, "ДОСТАВЧИК", seller, width)
      end
      pdf.move_down 16
    end

    def party_box(pdf, heading, rows, width)
      pdf.text(heading, style: :bold, size: 10)
      pdf.move_down 4
      pdf.table(rows, width: width) do |t|
        t.cells.borders = []
        t.cells.padding = [ 3, 6 ]
        t.row(0).font_style = :bold
        t.cells.border_color = BORDER
        t.cells.borders = %i[left right]
        t.row(0).borders = %i[top left right]
        t.row(-1).borders = %i[bottom left right]
      end
    end

    def buyer_rows
      if @order.wants_invoice? && @order.invoice_company.present?
        rows = [ [ { content: "#{@order.invoice_company}\n#{@order.invoice_address}", colspan: 2 } ] ]
        rows << [ "ЕИК/Булстат:", @order.invoice_eik ] if @order.invoice_eik.present?
        rows << [ "ДДС №:", @order.invoice_vat ] if @order.invoice_vat.present?
        rows << [ "МОЛ:", @order.invoice_mol.presence || @order.customer_name ]
        rows
      else
        [
          [ { content: "#{@order.customer_name}\n#{[ @order.address, @order.postal_code, @order.city ].compact_blank.join(', ')}", colspan: 2 } ],
          [ "Телефон:", @order.phone ]
        ]
      end
    end

    def seller_rows
      [
        [ { content: "#{@seller[:name]}\n#{@seller[:address]}\n#{@seller[:city]}\n#{@seller[:country]}", colspan: 2 } ],
        [ "ЕИК/Булстат:", @seller[:eik] ],
        [ "МОЛ:", @seller[:mol] ]
      ]
    end

    def title_block(pdf)
      pdf.stroke_color(BORDER)
      pdf.stroke_horizontal_rule
      pdf.move_down 14

      y = pdf.cursor
      pdf.bounding_box([ 0, y ], width: 220) do
        pdf.text(KINDS[@kind][:title], size: 22, style: :bold)
        pdf.text("Оригинал", size: 14) if invoice?
      end
      pdf.bounding_box([ 220, y ], width: pdf.bounds.width - 220) do
        info = [
          [ "Номер:", format("%010d", number) ],
          [ "Дата на издаване:", issued_at.strftime("%d.%m.%Y") ]
        ]
        info << [ "Дата на данъчно събитие:", issued_at.strftime("%d.%m.%Y") ] if invoice?
        info << [ "Поръчка:", "##{@order.id}" ]
        pdf.table(info, position: :right) do |t|
          t.cells.borders = []
          t.cells.padding = [ 2, 6 ]
          t.column(0).align = :right
          t.column(1).font_style = :bold
          t.column(1).background_color = LABEL_BG
        end
      end
      pdf.move_down 14
      pdf.stroke_horizontal_rule
      pdf.move_down 16
    end

    def items_table(pdf)
      header = [ [ "№", "Артикул", "Количество", "Ед. цена", "Стойност" ] ]
      rows = @order.order_items.map.with_index(1) do |item, i|
        [ i.to_s, item.product_name,
         format("%.2f бр.", item.quantity),
         format("%.2f", item.unit_price_cents / 100.0),
         format("%.2f €", item.quantity * item.unit_price_cents / 100.0) ]
      end
      if @order.discount?
        rows << [ (rows.size + 1).to_s, "#{Discount.label} (поръчка над #{Discount.threshold.eur_formatted})", "1.00 бр.",
                 format("%.2f", -@order.discount_cents / 100.0),
                 format("%.2f €", -@order.discount_cents / 100.0) ]
      end
      if @order.shipping_cents.to_i.positive?
        rows << [ (rows.size + 1).to_s, shipping_line_label, "1.00 бр.",
                 format("%.2f", @order.shipping_cents / 100.0),
                 format("%.2f €", @order.shipping_cents / 100.0) ]
      end

      pdf.table(header + rows, width: pdf.bounds.width,
                column_widths: { 0 => 28, 2 => 80, 3 => 70, 4 => 80 }) do |t|
        t.cells.border_color = BORDER
        t.cells.padding = [ 4, 6 ]
        t.row(0).font_style = :bold
        t.row(0).background_color = LABEL_BG
        t.columns(2..4).align = :right
        t.column(0).align = :center
      end
      pdf.move_down 14
    end

    def totals(pdf)
      total = format("%.2f €", @order.grand_total_cents / 100.0)
      rows = [
        [ "Данъчна основа:", total ],
        [ "Процент ДДС:", "0 %" ],
        [ "Начислен ДДС:", "0.00 €" ],
        [ "Сума за плащане:", total ]
      ]
      pdf.table(rows, position: :right, column_widths: [ 130, 90 ]) do |t|
        t.cells.borders = []
        t.cells.padding = [ 3, 6 ]
        t.column(0).align = :right
        t.column(1).align = :right
        t.column(1).background_color = LABEL_BG
        t.column(1).font_style = :bold
        t.row(-1).size = 12
      end
      pdf.move_down 16
    end

    def notes(pdf)
      lines = [
        [ "Словом:", BulgarianWords.amount_in_words(@order.grand_total_cents) ],
        [ "Основание за неначисляване на ДДС:", Config.vat_exemption_note ],
        [ "Начин на плащане:", payment_method_text ]
      ]
      lines.each do |label, value|
        pdf.text("#{label} <b>#{value}</b>", inline_format: true)
        pdf.move_down 4
      end
      pdf.move_down 8
    end

    def payment_method_text
      return "банков превод" unless invoice?
      { "card" => "плащане с карта", "cod" => "наложен платеж", "bank" => "банков превод" }
        .fetch(@order.payment_method, @order.payment_method)
    end

    def bank_details(pdf)
      rows = [
        [ { content: "Банкови детайли на доставчика", colspan: 2, font_style: :bold, background_color: LABEL_BG } ],
        [ "Банка:", @bank[:name] ],
        [ "IBAN:", @bank[:iban] ],
        [ "BIC/SWIFT:", @bank[:bic] ]
      ]
      pdf.table(rows, width: 320) do |t|
        t.cells.border_color = BORDER
        t.cells.padding = [ 4, 8 ]
        t.column(1).font_style = :bold
      end
      pdf.move_down 20
    end

    def signatures(pdf)
      pdf.text("Получател: <b>#{buyer_signature_name}</b>    Съставил: <b>#{Config.issuer}</b>", inline_format: true)
      return if invoice?
      pdf.move_down 12
      pdf.text("Проформа фактурата не е данъчен документ. Фактура се издава след получаване на плащането.",
               size: 7.5, color: "666666")
    end

    def buyer_signature_name
      (@order.wants_invoice? && @order.invoice_mol.presence) || @order.customer_name
    end

    def shipping_line_label
      base = "Доставка със Speedy"
      @order.shipping_label.present? ? "#{base} — #{@order.shipping_label}" : base
    end
  end
end
