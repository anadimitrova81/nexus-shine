module Invoices
  # Company requisites and bank details from config/invoice.yml.
  module Config
    class << self
      def seller = settings.fetch(:seller)
      def bank = settings.fetch(:bank)
      def issuer = settings.fetch(:issuer)
      def vat_exemption_note = settings.fetch(:vat_exemption_note)
      def proforma_sequence_start = settings.fetch(:proforma_sequence_start)
      def invoice_sequence_start = settings.fetch(:invoice_sequence_start)
      def email_from = settings.fetch(:email_from)

      def settings
        @settings ||= Rails.application.config_for(:invoice)
      end
    end
  end
end
