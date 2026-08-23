namespace :speedy do
  desc "Validate Speedy config and do a live location lookup. Never prints the password."
  task check: :environment do
    puts "Speedy configuration check"
    puts "  username set: #{Speedy::Config.username.present?}"
    puts "  password set: #{Speedy::Config.configured?}"
    unless Speedy::Config.configured?
      puts "\nAdd your password to config/speedy.yml, then re-run."
      next
    end

    begin
      sites = Speedy::Client.new.find_sites("София")
      puts "  ✓ API reachable — found #{sites.size} site(s) matching 'София' (e.g. id #{sites.first&.dig(:id)})"
      puts "\nSpeedy is configured and responding."
    rescue Speedy::Client::Error => e
      puts "  ✗ API error: #{e.message}"
      puts "\nCheck your username/password in config/speedy.yml."
    end
  end
end
