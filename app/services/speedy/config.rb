module Speedy
  # Reads Speedy API credentials from config/speedy.yml (git-ignored) or ENV.
  module Config
    module_function

    BASE_URL = "https://api.speedy.bg/v1".freeze
    COUNTRY_ID = 100 # Bulgaria
    PLACEHOLDER = "PASTE_YOUR_SPEEDY_PASSWORD_HERE".freeze

    def file_config
      path = Rails.root.join("config", "speedy.yml")
      return {} unless path.exist?
      (YAML.safe_load_file(path) || {}).transform_keys(&:to_s)
    rescue StandardError => e
      Rails.logger.warn("[speedy] could not read config/speedy.yml: #{e.message}")
      {}
    end

    def username = ENV["SPEEDY_USERNAME"].presence || file_config["username"].presence
    def password = ENV["SPEEDY_PASSWORD"].presence || file_config["password"].presence
    def language = (ENV["SPEEDY_LANGUAGE"].presence || file_config["language"].presence || "BG")
    def sender_site_id = (ENV["SPEEDY_SENDER_SITE_ID"].presence || file_config["sender_site_id"].presence)

    # Optional explicit service ids; when empty the client asks Speedy for all
    # available services and picks the cheapest.
    # Default to 505 = "СТАНДАРТ 24 ЧАСА" (standard domestic courier service).
    def service_ids
      raw = ENV["SPEEDY_SERVICE_IDS"].presence || file_config["service_ids"]
      ids = Array(raw).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?).map(&:to_i)
      ids.presence || [505]
    end

    def configured?
      username.present? && password.present? && password != PLACEHOLDER
    end
  end
end
