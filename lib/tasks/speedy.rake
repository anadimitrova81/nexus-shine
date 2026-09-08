namespace :speedy do
  desc "Validate Speedy config and do a live location lookup. Never prints the password."
  task check: :environment do
    puts "Speedy configuration check (#{Rails.env})"
    source = if !Rails.env.production? && Speedy::Config.file_config.present? then "config/speedy.yml (takes precedence outside production)"
             elsif Speedy::Config.creds.present? then "Rails credentials"
             else "ENV / config/speedy.yml"
             end
    puts "  source:       #{source}"
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

namespace :speedy do
  desc "Copy a Speedy yml (default config/speedy.yml) into encrypted Rails credentials under `speedy:`. Never prints secrets."
  task :install_credentials, [:path] => :environment do |_t, args|
    path = Rails.root.join(args[:path] || "config/speedy.yml")
    abort "No such file: #{path}" unless path.exist?

    source = (YAML.safe_load_file(path) || {}).transform_keys(&:to_s)
    required = %w[username password]
    missing = required.select { |k| source[k].to_s.strip.empty? || source[k].to_s == Speedy::Config::PLACEHOLDER }
    abort "Fill in these values in #{path.relative_path_from(Rails.root)} first: #{missing.join(', ')}" if missing.any?

    credentials = Rails.application.credentials
    abort "Missing #{credentials.key_path} — cannot decrypt credentials" unless credentials.key.present?

    data = (YAML.safe_load(credentials.read.presence || "", permitted_classes: [Symbol]) || {})
    keys = %w[username password language sender_site_id service_ids]
    data["speedy"] = keys.each_with_object({}) do |k, h|
      v = source[k]
      next if v.nil? || v.to_s.strip.empty?
      h[k] = v.is_a?(Array) ? v : v.to_s.strip
    end
    credentials.write(data.to_yaml)

    puts "Installed Speedy credentials (#{data['speedy'].keys.join(', ')}) from #{path.relative_path_from(Rails.root)} into #{credentials.content_path.relative_path_from(Rails.root)}"
    puts "Next: commit config/credentials.yml.enc and run `kamal deploy`."
  end
end
