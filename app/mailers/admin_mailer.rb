class AdminMailer < ApplicationMailer
  # One-time link (30 min) for setting a new admin password.
  def password_reset(url)
    @url = url
    mail(to: Mailing::Config.admin_email, subject: "Nexus Shine — линк за нова парола на администрацията")
  end

  # Used by `bin/rails smtp:check`.
  def test_message
    mail(to: Mailing::Config.admin_email, subject: "Nexus Shine — тест на изпращането на имейли") do |format|
      format.text { render plain: "Изпращането на имейли от Nexus Shine работи. (#{Time.current.strftime('%d.%m.%Y %H:%M')})" }
    end
  end
end
