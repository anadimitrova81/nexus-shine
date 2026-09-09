namespace :smtp do
  desc "Send a test e-mail to admin_email using the current SMTP settings. Never prints the password."
  task check: :environment do
    puts "SMTP configuration check (#{Rails.env})"
    puts "  server:      #{Mailing::Config.address.presence || '—'}:#{Mailing::Config.port}"
    puts "  user set:    #{Mailing::Config.user_name.present?}"
    puts "  from:        #{Mailing::Config.from}"
    puts "  admin_email: #{Mailing::Config.admin_email.presence || '—'}"
    abort "\nSMTP is not configured. Copy config/smtp.example.yml to config/smtp.yml and fill it in." unless Mailing::Config.configured?
    abort "\nadmin_email is missing or a placeholder." unless Mailing::Config.admin_email_configured?

    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = Mailing::Config.smtp_settings
    ActionMailer::Base.raise_delivery_errors = true
    AdminMailer.test_message.deliver_now
    puts "\n✓ Test e-mail sent to #{Mailing::Config.admin_email} — check the inbox (and spam folder)."
  rescue StandardError => e
    abort "\n✗ Sending failed: #{e.class}: #{e.message}"
  end

  desc "Copy config/smtp.yml into encrypted Rails credentials under `smtp:`. Never prints secrets."
  task :install_credentials, [:path] => :environment do |_t, args|
    path = Rails.root.join(args[:path] || "config/smtp.yml")
    abort "No such file: #{path}" unless path.exist?

    source = (YAML.safe_load_file(path) || {}).transform_keys(&:to_s)
    missing = %w[address user_name password admin_email].select { |k| source[k].to_s.strip.empty? || source[k].to_s.include?("your-") }
    abort "Fill in these values in config/smtp.yml first: #{missing.join(', ')}" if missing.any?

    credentials = Rails.application.credentials
    abort "Missing #{credentials.key_path} — cannot decrypt credentials" unless credentials.key.present?

    data = (YAML.safe_load(credentials.read.presence || "", permitted_classes: [Symbol]) || {})
    data["smtp"] = Mailing::Config::KEYS.each_with_object({}) do |k, h|
      v = source[k]
      h[k] = (k == "port" ? v.to_i : v.to_s.strip) unless v.nil? || v.to_s.strip.empty?
    end
    credentials.write(data.to_yaml)
    puts "Installed SMTP settings (#{data['smtp'].keys.join(', ')}) into #{credentials.content_path.relative_path_from(Rails.root)}"
    puts "Next: commit config/credentials.yml.enc and run `kamal deploy`."
  end
end
