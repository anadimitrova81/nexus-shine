module Mypos
  # A self-contained local myPOS simulator for development. Generates a
  # throwaway RSA keypair (persisted under tmp/) so no real credentials are
  # needed to exercise the full card flow on localhost. Never active outside
  # development.
  module LocalSandbox
    module_function

    DIR = Rails.root.join("tmp", "mypos_sandbox")
    TRUTHY = %w[1 true yes on].freeze

    def enabled?
      Rails.env.development? && TRUTHY.include?(ENV["MYPOS_LOCAL_SANDBOX"].to_s.downcase)
    end

    def sid           = "SANDBOX-SID"
    def wallet_number = "SANDBOX-WALLET"
    def key_index     = "1"

    def private_key
      ensure_keys
      File.read(DIR.join("private.pem"))
    end

    # The simulator signs notifications with the same key, so the app's own
    # public key verifies them — exercising the real crypto path.
    def public_cert
      ensure_keys
      File.read(DIR.join("public.pem"))
    end

    # Where PaymentsController#new posts the browser (our mock checkout page).
    def checkout_url
      ENV["MYPOS_SANDBOX_URL"].presence || "http://localhost:3050/dev/mypos/checkout"
    end

    def ensure_keys
      return if File.exist?(DIR.join("private.pem"))
      FileUtils.mkdir_p(DIR)
      key = OpenSSL::PKey::RSA.new(2048)
      File.write(DIR.join("private.pem"), key.to_pem)
      File.write(DIR.join("public.pem"), key.public_key.to_pem)
    end
  end
end
