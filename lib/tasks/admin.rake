namespace :admin do
  desc "Print a 30-minute link for setting a new admin password (use when the password is forgotten or not yet set)"
  task password_reset_link: :environment do
    account = AdminAccount.current_or_bootstrap!
    token = account.generate_token_for(:password_reset)
    host = ENV["APP_HOST"].presence || (Rails.env.production? ? "https://nexus-shine.com" : "http://localhost:3050")
    url = Rails.application.routes.url_helpers.admin_password_reset_url(token, host: host)
    puts "Open this link within 30 minutes to set the admin password:"
    puts "  #{url}"
    puts "The link stops working as soon as a password is set."
  end
end
