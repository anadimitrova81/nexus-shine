module Mypos
  # Verifies a server-to-server notification (URL_Notify) from myPOS.
  # Pass the raw posted body params (request.request_parameters) so the field
  # order matches what myPOS signed.
  class Notification
    TRNREF_KEYS = %w[IPC_Trnref IPCTrnRef TrnRef IPC_TransactionRef].freeze

    def initialize(body_params)
      @params = body_params.to_h.transform_keys(&:to_s)
    end

    def order_id
      @params["OrderID"]
    end

    def trnref
      TRNREF_KEYS.filter_map { |k| @params[k].presence }.first
    end

    def valid_signature?
      Signer.verify(@params.except("Signature").values, @params["Signature"])
    end
  end
end
