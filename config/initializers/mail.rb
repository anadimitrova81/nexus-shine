# Outgoing mail: use SMTP whenever credentials are present (see Mailing::Config).
# Without them production mail is silently dropped, so `bin/rails smtp:check`
# is the way to confirm delivery works.
Rails.application.config.to_prepare do
  if Mailing::Config.configured?
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = Mailing::Config.smtp_settings
  end
end
