module Speedy
  # Reads Speedy API credentials from Rails credentials (`speedy:`), ENV
  # (SPEEDY_*) or the git-ignored config/speedy.yml.
  #
  # Precedence:
  #   production:  Rails credentials → ENV → config/speedy.yml
  #   elsewhere:   config/speedy.yml → ENV → Rails credentials
  # Install the file into credentials with `bin/rails speedy:install_credentials`.
  module Config
    module_function

    BASE_URL = "https://api.speedy.bg/v1".freeze
    COUNTRY_ID = 100 # Bulgaria
    PLACEHOLDER = "PASTE_YOUR_SPEEDY_PASSWORD_HERE".freeze

    def creds
      Rails.application.credentials.speedy || {}
    end

    def setting(key, env_key)
      key = key.to_s
      if Rails.env.production?
        creds[key.to_sym].presence || ENV[env_key].presence || file_config[key].presence
      else
        file_config[key].presence || ENV[env_key].presence || creds[key.to_sym].presence
      end
    end

    def file_config
      path = Rails.root.join("config", "speedy.yml")
      return {} unless path.exist?
      (YAML.safe_load_file(path) || {}).transform_keys(&:to_s)
    rescue StandardError => e
      Rails.logger.warn("[speedy] could not read config/speedy.yml: #{e.message}")
      {}
    end

    def username = setting(:username, "SPEEDY_USERNAME")
    def password = setting(:password, "SPEEDY_PASSWORD")
    def language = setting(:language, "SPEEDY_LANGUAGE") || "BG"
    def sender_site_id = setting(:sender_site_id, "SPEEDY_SENDER_SITE_ID")

    # Optional explicit service ids; when empty the client asks Speedy for all
    # available services and picks the cheapest.
    # Default to 505 = "СТАНДАРТ 24 ЧАСА" (standard domestic courier service).
    def service_ids
      raw = setting(:service_ids, "SPEEDY_SERVICE_IDS")
      ids = Array(raw).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?).map(&:to_i)
      ids.presence || [505]
    end

    def configured?
      username.present? && password.present? && password != PLACEHOLDER
    end
  end
end
