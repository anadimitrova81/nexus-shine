module Mailing
  # Outgoing e-mail (SMTP) settings plus the admin's own address for password
  # reset links. Same precedence as myPOS/Speedy:
  #   production:  Rails credentials (smtp:) → ENV (SMTP_*) → config/smtp.yml
  #   elsewhere:   config/smtp.yml → ENV → Rails credentials
  # Install the git-ignored file into credentials with `bin/rails smtp:install_credentials`.
  module Config
    module_function

    KEYS = %w[address port user_name password domain authentication from admin_email].freeze

    def creds
      Rails.application.credentials.smtp || {}
    end

    def file_config
      path = Rails.root.join("config", "smtp.yml")
      return {} unless path.exist?
      (YAML.safe_load_file(path) || {}).transform_keys(&:to_s)
    rescue StandardError => e
      Rails.logger.warn("[mail] could not read config/smtp.yml: #{e.message}")
      {}
    end

    def setting(key)
      key = key.to_s
      env_key = "SMTP_#{key.upcase}"
      sources = [creds[key.to_sym], ENV[env_key], file_config[key]]
      sources.reverse! unless Rails.env.production?
      sources.map { |v| real(v) }.compact.first
    end

    # Ignore blanks and the "your-…" placeholders from config/smtp.example.yml.
    def real(value)
      v = value.to_s.strip
      v.presence unless v.include?("your-")
    end

    def address        = setting(:address)
    def port           = (setting(:port) || 587).to_i
    def user_name      = setting(:user_name)
    def password       = setting(:password)
    def domain         = setting(:domain) || "nexus-shine.com"
    def authentication = (setting(:authentication) || "plain").to_sym
    def from           = setting(:from) || Invoices::Config.email_from
    # Where admin password-reset links are sent.
    def admin_email    = setting(:admin_email)

    def configured?
      address.present? && user_name.present? && password.present? && !password.to_s.include?("your-")
    end

    def admin_email_configured?
      admin_email.present? && admin_email.include?("@") && !admin_email.include?("your-")
    end

    def smtp_settings
      {
        address: address, port: port, domain: domain,
        user_name: user_name, password: password,
        authentication: authentication, enable_starttls_auto: true,
      }
    end
  end
end
