class PaymentsController < ApplicationController
  # myPOS posts the server-to-server notification and also returns the customer
  # to the success/cancel URLs with a cross-origin POST — none carry a CSRF token.
  skip_before_action :verify_authenticity_token, only: %i[notify success cancel]
  before_action :set_order

  # Renders the auto-submitting form that hands the customer to myPOS.
  def new
    return redirect_to order_path(@order) unless payable?

    @order.issue_mypos_order_ref!
    @purchase = Mypos::Purchase.new(@order, **callback_urls)
    render layout: false
  end

  # Browser returns here from myPOS after a successful payment. The
  # authoritative confirmation is the signed notify; this just shows the order.
  def success
    notice = @order.paid? ? "Плащането е успешно! Благодарим за поръчката." :
                            "Плащането се обработва. Ще потвърдим поръчката скоро."
    redirect_to order_path(@order), notice: notice
  end

  def cancel
    redirect_to order_path(@order), alert: "Плащането беше прекратено. Можете да опитате отново."
  end

  # Server-to-server notification from myPOS. Verify the RSA signature before
  # trusting it, then mark the order paid.
  def notify
    notification = Mypos::Notification.new(request.request_parameters)
    if notification.valid_signature? && @order.matches_mypos_order_ref?(notification.order_id)
      @order.mark_paid!(notification.trnref)
      render plain: "OK"
    else
      Rails.logger.warn("[mypos] rejected notify for order #{@order.id} (OrderID=#{notification.order_id.inspect}, signature_valid=#{notification.valid_signature?})")
      head :bad_request
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def payable?
    @order.card_payment? && mypos_available? && !@order.paid?
  end

  # Uses a public tunnel host (MYPOS_PUBLIC_URL) when set so myPOS can reach the
  # notify endpoint; otherwise builds full URLs from the current request host.
  def callback_urls
    if (base = Mypos::Config.public_url).present?
      b = base.chomp("/")
      {
        url_ok:     "#{b}#{order_payment_success_path(@order)}",
        url_cancel: "#{b}#{order_payment_cancel_path(@order)}",
        url_notify: "#{b}#{order_payment_notify_path(@order)}",
      }
    else
      {
        url_ok:     order_payment_success_url(@order),
        url_cancel: order_payment_cancel_url(@order),
        url_notify: order_payment_notify_url(@order),
      }
    end
  end
end
