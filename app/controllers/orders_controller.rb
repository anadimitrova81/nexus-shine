class OrdersController < ApplicationController
  before_action :require_non_empty_cart, only: %i[new create]

  def new
    @order = Order.new(payment_method: mypos_available? ? "card" : "cod")
  end

  def create
    @order = Order.new(order_params)
    @order.populate_from_cart(current_cart)
    @order.payment_method = "cod" if @order.card_payment? && !mypos_available?

    if (shipping_error = compute_shipping!(@order))
      flash.now[:alert] = shipping_error
      return render :new, status: :unprocessable_entity
    end

    if @order.save
      current_cart.clear
      OrderMailer.bank_instructions(@order).deliver_later if @order.bank_transfer?
      # Bank orders get an invoice manually in the admin once the transfer arrives.
      @order.ensure_invoice_number! if @order.wants_invoice? && !@order.bank_transfer?
      if @order.card_payment?
        redirect_to pay_order_path(@order)
      else
        redirect_to order_path(@order), notice: "Благодарим за поръчката! Ще се свържем с вас за потвърждение."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @order = Order.includes(:order_items).find(params[:id])
  end

  def proforma
    order = Order.includes(:order_items).find(params[:id])
    head :not_found and return unless order.bank_transfer?
    order.ensure_proforma_number!
    pdf = Invoices::DocumentPdf.new(order, kind: :proforma)
    send_data pdf.render, filename: pdf.filename, type: "application/pdf", disposition: "inline"
  end

  private

  def order_params
    params.require(:order).permit(
      :customer_name, :email, :phone, :address, :city, :postal_code, :note, :payment_method,
      :shipping_method, :shipping_site_id, :shipping_office_id, :shipping_city, :shipping_label,
      :wants_invoice, :invoice_eik, :invoice_company, :invoice_vat, :invoice_mol, :invoice_address,
    )
  end

  # Recomputes the Speedy shipping price on the server (the submitted price is
  # never trusted). Returns an error string, or nil on success.
  def compute_shipping!(order)
    return nil unless shipping_available?
    return "Моля, изберете начин на доставка." if order.shipping_method.blank?

    if order.shipping_method == "office" && order.shipping_office_id.blank?
      return "Моля, изберете офис на Speedy."
    end
    if order.shipping_method == "address" && order.shipping_site_id.blank?
      return "Моля, изберете населено място за доставка."
    end

    recipient =
      if order.shipping_method == "office"
        Speedy::Client.office_recipient(order.shipping_office_id)
      else
        Speedy::Client.address_recipient(order.shipping_site_id)
      end
    price = Speedy::Client.new.calculate(recipient: recipient, weight_kg: current_cart.total_weight_kg)
    order.shipping_cents = (price.to_f * 100).round
    nil
  rescue Speedy::Client::Error => e
    "Грешка при изчисляване на доставката: #{e.message}"
  end

  def require_non_empty_cart
    redirect_to cart_path, alert: "Количката ви е празна." if current_cart.empty?
  end
end
