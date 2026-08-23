require "net/http"
require "uri"
require "json"

module Speedy
  # Thin JSON client for the Speedy REST API (https://api.speedy.bg/v1).
  # Credentials are injected into every request body.
  class Client
    class Error < StandardError; end

    # Recipient builders for calculate().
    def self.office_recipient(office_id)
      { privatePerson: true, pickupOfficeId: office_id.to_i }
    end

    def self.address_recipient(site_id)
      { privatePerson: true, addressLocation: { siteId: site_id.to_i } }
    end

    def find_sites(name)
      body = post("/location/site", name: name.to_s, countryId: Config::COUNTRY_ID)
      Array(body["sites"]).map { |s| { id: s["id"], name: s["name"], post_code: s["postCode"], type: s["type"] } }
    end

    def find_offices(site_id, name: nil)
      params = { siteId: site_id.to_i, countryId: Config::COUNTRY_ID }
      params[:name] = name if name.present?
      body = post("/location/office", params)
      Array(body["offices"]).map { |o| { id: o["id"], name: o["name"], address: office_address(o) } }
    end

    # Speedy caps a single parcel around ~31.5 kg; split heavier shipments so a
    # service stays available.
    MAX_PARCEL_KG = 30.0

    # Returns the cheapest shipping price (Float, EUR) for the recipient.
    # /calculate requires explicit serviceId(s): try the configured/default
    # service first, then fall back to whatever /services reports for the route.
    def calculate(recipient:, weight_kg:, parcels: nil)
      weight = [weight_kg.to_f, 0.1].max.round(3)
      count = parcels || [(weight / MAX_PARCEL_KG).ceil, 1].max

      price = cheapest_price(recipient, weight, count, Config.service_ids)
      if price.nil?
        available = available_service_ids(recipient: recipient, weight_kg: weight, parcels: count)
        price = cheapest_price(recipient, weight, count, available) if available.any?
      end
      if price.nil?
        raise Error, "До избраното място не е възможна доставка на тази пратка. " \
                     "Опитайте друг офис или доставка до адрес."
      end
      price
    end

    # Service ids offered by Speedy for a given route/weight.
    def available_service_ids(recipient:, weight_kg:, parcels: 1)
      body = post("/services", { recipient: recipient, content: { parcelsCount: parcels.to_i, totalWeight: weight_kg } })
      Array(body["services"]).filter_map { |s| s["id"] }.map(&:to_i)
    rescue Error
      []
    end

    private

    # Cheapest price among the given service ids, or nil if none priced.
    def cheapest_price(recipient, weight, parcels, service_ids)
      return nil if service_ids.blank?
      req = {
        recipient: recipient,
        service: { autoAdjustPickupDate: true, serviceIds: service_ids },
        content: { parcelsCount: parcels.to_i, totalWeight: weight },
        payment: { courierServicePayer: "SENDER" },
      }
      req[:sender] = sender if sender
      body = post("/calculate", req)
      prices = Array(body["calculations"]).filter_map do |c|
        next if c["error"]
        c.dig("price", "total") || c.dig("price", "amount")
      end
      prices.map(&:to_f).min
    rescue Error
      nil
    end

    def sender
      return nil if Config.sender_site_id.blank?
      { address: { countryId: Config::COUNTRY_ID, siteId: Config.sender_site_id.to_i } }
    end

    def office_address(office)
      addr = office["address"]
      addr.is_a?(Hash) ? addr["fullAddressString"] || addr["addressNote"] : addr
    end

    def post(path, params)
      uri = URI("#{Config::BASE_URL}#{path}")
      payload = params.merge(
        userName: Config.username,
        password: Config.password,
        language: Config.language,
      )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 8
      http.read_timeout = 15
      res = http.post(uri.path, JSON.generate(payload), "Content-Type" => "application/json; charset=utf-8")
      body = JSON.parse(res.body.presence || "{}")
      if body["error"]
        raise Error, body.dig("error", "message") || "Speedy API грешка"
      end
      body
    rescue JSON::ParserError
      raise Error, "Невалиден отговор от Speedy"
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise Error, "Speedy не отговори навреме"
    end
  end
end
