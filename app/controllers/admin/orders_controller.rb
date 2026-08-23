module Admin
  class OrdersController < BaseController
    before_action :set_order, only: %i[show update invoice issue_invoice]

    def index
      @status = params[:status].presence_in(Order::STATUSES)
      scope = Order.order(created_at: :desc)
      scope = scope.where(status: @status) if @status
      @orders = scope
      @counts = Order.group(:status).count
    end

    def show; end

    def update
      if @order.update(params.require(:order).permit(:status, :payment_status))
        redirect_to admin_order_path(@order), notice: "Поръчката е обновена."
      else
        redirect_to admin_order_path(@order), alert: "Невалидни данни."
      end
    end

    def invoice
      head :not_found and return unless @order.invoiced?
      pdf = Invoices::DocumentPdf.new(@order, kind: :invoice)
      send_data pdf.render, filename: pdf.filename, type: "application/pdf", disposition: "inline"
    end

    def issue_invoice
      @order.ensure_invoice_number!
      redirect_to admin_order_path(@order), notice: "Издадена е фактура №#{format('%010d', @order.invoice_number)}."
    end

    private

    def set_order
      @order = Order.includes(:order_items).find(params[:id])
    end
  end
end
