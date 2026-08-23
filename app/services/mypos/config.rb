module Mypos
  # Reads myPOS Checkout credentials from Rails credentials (preferred) or ENV.
  #
  # Rails credentials shape (bin/rails credentials:edit):
  #   mypos:
  #     sid: "000000000000010"
  #     wallet_number: "61938166610"
  #     key_index: 1
  #     private_key: |
  #       -----BEGIN RSA PRIVATE KEY-----
  #       ...
  #     public_cert: |
  #       -----BEGIN CERTIFICATE-----
  #       ...
  #     ipc_url: "https://mypos.com/vmp/checkout-test"   # test; use .../checkout for live
  #
  # Or via ENV: MYPOS_SID, MYPOS_WALLET_NUMBER, MYPOS_KEY_INDEX,
  #             MYPOS_PRIVATE_KEY, MYPOS_PUBLIC_CERT, MYPOS_IPC_URL.
  module Config
    module_function

    # Default to the TEST endpoint so nothing charges real cards by accident.
    DEFAULT_TEST_URL = "https://mypos.com/vmp/checkout-test".freeze
    VERSION = "1.4".freeze

    def creds
      Rails.application.credentials.mypos || {}
    end

    # The local simulator (development only) short-circuits all credentials.
    def sandbox? = LocalSandbox.enabled?

    # Value precedence for real (non-sandbox) mode: Rails credentials → ENV →
    # a plain config/mypos.yml file (easiest to edit, git-ignored).
    def setting(cred_key, env_key)
      creds[cred_key].presence || ENV[env_key].presence || file_config[cred_key.to_s].presence
    end

    def sid           = sandbox? ? LocalSandbox.sid           : setting(:sid, "MYPOS_SID")
    def wallet_number = sandbox? ? LocalSandbox.wallet_number : setting(:wallet_number, "MYPOS_WALLET_NUMBER")
    def key_index     = sandbox? ? LocalSandbox.key_index     : (setting(:key_index, "MYPOS_KEY_INDEX") || 1).to_s
    def private_key   = sandbox? ? LocalSandbox.private_key   : setting(:private_key, "MYPOS_PRIVATE_KEY")
    def public_cert   = sandbox? ? LocalSandbox.public_cert   : setting(:public_cert, "MYPOS_PUBLIC_CERT")
    def ipc_url       = sandbox? ? LocalSandbox.checkout_url  : (setting(:ipc_url, "MYPOS_IPC_URL") || DEFAULT_TEST_URL)
    def source        = setting(:source, "MYPOS_SOURCE")     || "SDK_Ruby"
    def language      = setting(:language, "MYPOS_LANGUAGE") || "BG"
    def currency      = "EUR"

    # Public base URL (e.g. an ngrok/cloudflared tunnel) used to build the
    # myPOS return/notify URLs so the server-to-server notify can reach a local
    # app. Falls back to the request host when unset.
    def public_url
      ENV["MYPOS_PUBLIC_URL"].presence || file_config["public_url"].presence
    end

    # Plain YAML file fallback so credentials aren't required.
    def file_config
      path = Rails.root.join("config", "mypos.yml")
      return {} unless path.exist?
      (YAML.safe_load_file(path) || {}).transform_keys(&:to_s)
    rescue StandardError => e
      Rails.logger.warn("[mypos] could not read config/mypos.yml: #{e.message}")
      {}
    end

    # Card payment can only be offered when the essentials are present.
    def configured?
      sandbox? || (sid.present? && wallet_number.present? && private_key.present?)
    end

    # True when using the local simulator or the myPOS sandbox endpoint.
    def test_mode?
      sandbox? || ipc_url.to_s.include?("checkout-test")
    end
  end
end
