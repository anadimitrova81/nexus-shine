# JSON endpoints powering the checkout Speedy shipping calculator.
class ShippingController < ApplicationController
  before_action :require_speedy

  # GET /shipping/sites?q=Пловдив
  def sites
    list = client.find_sites(params[:q].to_s).first(20).map do |s|
      { id: s[:id], label: [s[:name], (s[:post_code].presence)].compact.join(" ") }
    end
    render json: { sites: list }
  rescue Speedy::Client::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /shipping/offices?site_id=68134
  def offices
    list = client.find_offices(params[:site_id]).first(200).map do |o|
      { id: o[:id], label: [o[:name], o[:address]].compact_blank.join(" — ") }
    end
    render json: { offices: list }
  rescue Speedy::Client::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /shipping/quote?delivery_type=office&office_id=..&site_id=..
  def quote
    recipient =
      if params[:delivery_type] == "office"
        Speedy::Client.office_recipient(params[:office_id])
      else
        Speedy::Client.address_recipient(params[:site_id])
      end
    price = client.calculate(recipient: recipient, weight_kg: current_cart.total_weight_kg)
    cents = (price.to_f * 100).round
    render json: { price_cents: cents, formatted: Money.new(cents).eur_formatted }
  rescue Speedy::Client::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def client
    @client ||= Speedy::Client.new
  end

  def require_speedy
    return if shipping_available?
    render json: { error: "Изчисляването на доставка не е налично." }, status: :service_unavailable
  end
end
