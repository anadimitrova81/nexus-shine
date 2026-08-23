module Mypos
  # Builds a signed IPCPurchase request for myPOS Checkout. The parameter set,
  # order, and signature algorithm mirror the official myPOS PHP SDK
  # (IPC/Purchase.php + IPC/Base.php::_createSignature) so the signature myPOS
  # verifies matches byte-for-byte:
  #   join all values with "-" → base64 → RSA-SHA256 sign → base64.
  #
  # The controller renders `params` as hidden fields in a form that auto-POSTs
  # to `action_url` (the myPOS hosted checkout page).
  class Purchase
    def initialize(order, url_ok:, url_cancel:, url_notify:)
      @order = order
      @url_ok = url_ok
      @url_cancel = url_cancel
      @url_notify = url_notify
    end

    def action_url
      Config.ipc_url
    end

    # Ordered params including the trailing Signature (insertion order preserved).
    def params
      @params ||= base_params.merge("Signature" => Signer.sign(base_params.values))
    end

    private

    def base_params
      first, last = split_name(@order.customer_name)
      p = {
        "IPCmethod"    => "IPCPurchase",
        "IPCVersion"   => Config::VERSION,
        "IPCLanguage"  => Config.language,
        "SID"          => Config.sid,
        "WalletNumber" => Config.wallet_number,
        "KeyIndex"     => Config.key_index,
        "Source"       => Config.source,
        "Currency"     => Config.currency,
        "Amount"       => money(@order.grand_total_cents),
        "OrderID"      => @order.id.to_s,
        "URL_OK"       => @url_ok,
        "URL_Cancel"   => @url_cancel,
        "URL_Notify"   => @url_notify,
        "Note"         => "",
        "expires_in"   => "",
        "ApplicationID" => "",
        "PartnerID"    => "",
        "customeremail"      => @order.email.to_s,
        "customerphone"      => @order.phone.to_s,
        "customerfirstnames" => first,
        "customerfamilyname" => last,
        "customercountry"    => "",
        "customercity"       => @order.city.to_s,
        "customerzipcode"    => @order.postal_code.to_s,
        "customeraddress"    => @order.address.to_s,
      }

      # Product lines, plus a shipping line so the item amounts sum to Amount.
      lines = @order.order_items.map do |item|
        { name: item.product_name, qty: item.quantity, price_cents: item.unit_price_cents }
      end
      if @order.shipping_cents.to_i.positive?
        lines << { name: "Доставка (Speedy)", qty: 1, price_cents: @order.shipping_cents }
      end

      p["CartItems"] = lines.size.to_s
      lines.each_with_index do |line, idx|
        i = idx + 1
        p["Article_#{i}"]  = line[:name].to_s
        p["Quantity_#{i}"] = line[:qty].to_s
        p["Price_#{i}"]    = money(line[:price_cents])
        p["Amount_#{i}"]   = money(line[:price_cents] * line[:qty])
        p["Currency_#{i}"] = Config.currency
      end

      p["CardTokenRequest"] = ""
      p["PaymentParametersRequired"] = ""
      p["PaymentMethod"] = ""
      p
    end

    def money(cents)
      format("%.2f", cents.to_i / 100.0)
    end

    def split_name(name)
      parts = name.to_s.strip.split(/\s+/, 2)
      [parts[0].to_s, parts[1].to_s]
    end
  end
end
