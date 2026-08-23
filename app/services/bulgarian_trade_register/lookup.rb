require "net/http"
require "json"

module BulgarianTradeRegister
  # Looks up a Bulgarian company's invoice details by ЕИК.
  #
  # Uses the free EU VIES service (no credentials), which returns the legal
  # name and registered address for VAT-registered companies. Non-VAT-registered
  # EIKs won't be found — the customer then fills the details manually.
  #
  # For МОЛ (representative) and non-VAT companies you'd need the official Trade
  # Register API (registryagency.bg, requires registration); wire it in here if
  # needed.
  module Lookup
    Result = Struct.new(
      :eik, :company_legal_name, :company_address, :vat_number, :mol,
      keyword_init: true,
    )

    EIK_REGEX = /\A\d{9}(\d{4})?\z/
    VIES_URL = "https://ec.europa.eu/taxation_customs/vies/rest-api/check-vat-number".freeze

    def self.find(eik)
      eik = eik.to_s.strip
      return nil unless eik.match?(EIK_REGEX)
      vies(eik)
    end

    def self.vies(eik)
      uri = URI(VIES_URL)
      http = Net::HTTP.new(uri.host, 443)
      http.use_ssl = true
      http.open_timeout = 6
      http.read_timeout = 12
      res = http.post(uri.path, JSON.generate(countryCode: "BG", vatNumber: eik),
                      "Content-Type" => "application/json", "Accept" => "application/json")
      data = JSON.parse(res.body.presence || "{}")
      return nil unless data["valid"]

      Result.new(
        eik: eik,
        company_legal_name: clean(data["name"]),
        company_address: clean(data["address"]),
        vat_number: "BG#{eik}",
        mol: nil,
      )
    rescue StandardError => e
      Rails.logger.warn("[trade-register] VIES lookup failed for #{eik}: #{e.class}")
      nil
    end

    def self.clean(value)
      return nil if value.blank? || value == "---"
      value.to_s.gsub(/\s+/, " ").strip
    end
  end
end
