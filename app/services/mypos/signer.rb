module Mypos
  # Shared RSA-SHA256 signing/verification, matching the myPOS PHP SDK:
  #   base64( join(values, "-") ) → sign → base64.
  module Signer
    module_function

    def sign(values)
      key = OpenSSL::PKey::RSA.new(Config.private_key)
      Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new, concatenate(values)))
    end

    def verify(values, signature, cert = Config.public_cert)
      return false if signature.blank? || cert.blank?
      public_key(cert).verify(OpenSSL::Digest::SHA256.new,
                              Base64.strict_decode64(signature), concatenate(values))
    rescue OpenSSL::OpenSSLError, ArgumentError
      false
    end

    def concatenate(values)
      Base64.strict_encode64(Array(values).map(&:to_s).join("-"))
    end

    # Accepts either an X.509 certificate or a bare public key in PEM form.
    def public_key(cert)
      OpenSSL::X509::Certificate.new(cert).public_key
    rescue OpenSSL::X509::CertificateError
      OpenSSL::PKey::RSA.new(cert)
    end
  end
end
