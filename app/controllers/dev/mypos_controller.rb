require "net/http"
require "uri"

module Dev
  # Local myPOS simulator — DEVELOPMENT ONLY. Stands in for the myPOS hosted
  # checkout page so the full card flow works on localhost without real
  # credentials or a public tunnel. Receives the signed IPCPurchase, shows a
  # mock pay/cancel page, and on "pay" signs a notification and posts it back to
  # the app's URL_Notify (server-side), then redirects the browser to URL_OK.
  class MyposController < ActionController::Base
    skip_forgery_protection
    layout false
    before_action :only_when_enabled

    # Receives the browser's auto-submitted IPCPurchase POST.
    def checkout
      @params = request.request_parameters
    end

    # "Pay" button → build a signed notify, deliver it to URL_Notify, then
    # send the customer to URL_OK.
    def pay
      notify = {
        "IPCmethod"    => "IPCPurchaseNotify",
        "IPCVersion"   => "1.4",
        "SID"          => params[:SID].to_s,
        "WalletNumber" => params[:WalletNumber].to_s,
        "KeyIndex"     => params[:KeyIndex].to_s,
        "OrderID"      => params[:OrderID].to_s,
        "IPC_Trnref"   => "SANDBOX-#{SecureRandom.hex(5).upcase}",
        "Amount"       => params[:Amount].to_s,
        "Currency"     => params[:Currency].to_s,
        "Status"       => "0",
      }
      notify["Signature"] = Mypos::Signer.sign(notify.values)
      deliver_notify(params[:URL_Notify], notify)
      redirect_to params[:URL_OK], allow_other_host: true
    end

    def cancel
      redirect_to params[:URL_Cancel], allow_other_host: true
    end

    private

    def only_when_enabled
      head :not_found unless Mypos::Config.sandbox?
    end

    def deliver_notify(url, data)
      Net::HTTP.post_form(URI(url), data)
    rescue => e
      Rails.logger.warn("[mypos-sandbox] notify delivery failed: #{e.message}")
    end
  end
end
