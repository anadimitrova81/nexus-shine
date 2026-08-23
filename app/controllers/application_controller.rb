class ApplicationController < ActionController::Base
  # Only allow modern browsers — but never gate the myPOS server-to-server
  # webhook, which arrives without a browser user-agent.
  allow_browser versions: :modern,
                unless: -> { controller_name == "payments" && action_name == "notify" }

  helper_method :current_cart, :mypos_available?, :shipping_available?

  private

  def current_cart
    @current_cart ||= Cart.new(session)
  end

  # Card payment is only offered when myPOS is configured.
  def mypos_available?
    Mypos::Config.configured?
  end

  # Live Speedy shipping calculation is only offered when configured.
  def shipping_available?
    Speedy::Config.configured?
  end
end
