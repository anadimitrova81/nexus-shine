namespace :mypos do
  desc "Validate myPOS config (keys parse + signature self-test). Never prints secrets."
  task check: :environment do
    require "openssl"

    puts "myPOS configuration check (#{Rails.env})"
    puts "  sandbox mode: #{Mypos::Config.sandbox? ? 'ON (local simulator)' : 'off (real myPOS)'}"
    puts "  endpoint:     #{Mypos::Config.ipc_url}#{Mypos::Config.test_mode? ? '  [TEST — no real charges]' : '  [LIVE]'}"
    unless Mypos::Config.sandbox?
      file_first = !Rails.env.production? && Mypos::Config.file_config.present?
      source = if file_first then "config/mypos.yml (takes precedence outside production)"
               elsif Mypos::Config.creds.present? then "Rails credentials"
               else "ENV / config/mypos.yml"
               end
      puts "  source:       #{source}"
    end

    ok = true
    present = ->(label, val) do
      good = val.to_s.strip.present? && !val.to_s.include?("...")
      ok &&= good
      puts "  #{good ? '✓' : '✗'} #{label}#{good ? '' : ' — missing'}"
    end

    present.("Store ID (sid)",     Mypos::Config.sid)
    present.("Wallet number",      Mypos::Config.wallet_number)
    present.("Key index",          Mypos::Config.key_index)

    begin
      OpenSSL::PKey::RSA.new(Mypos::Config.private_key.to_s).sign(OpenSSL::Digest::SHA256.new, "test")
      puts "  ✓ Private key parses and can sign"
    rescue StandardError => e
      ok = false
      puts "  ✗ Private key invalid — #{e.class}"
    end

    begin
      Mypos::Signer.public_key(Mypos::Config.public_cert.to_s)
      puts "  ✓ myPOS certificate parses"
    rescue StandardError => e
      ok = false
      puts "  ✗ Certificate invalid — #{e.class}"
    end

    if !Mypos::Config.sandbox? && Mypos::Config.demo_store?
      puts "  ⚠ These are myPOS's public DEMO store credentials — payments go to the shared test store, not to you."
    end
    if !Mypos::Config.sandbox? && !Mypos::Config.test_mode? && Mypos::Config.demo_store?
      ok = false
      puts "  ✗ Demo store credentials with the LIVE endpoint will not work."
    end

    puts ok ? "\nAll good — myPOS is configured." : "\nConfiguration incomplete (see ✗ above)."
  end

  desc "Copy a myPOS yml (default config/mypos.production.yml) into encrypted Rails credentials under `mypos:`. Never prints secrets."
  task :install_credentials, [:path] => :environment do |_t, args|
    path = Rails.root.join(args[:path] || "config/mypos.production.yml")
    abort "No such file: #{path}" unless path.exist?

    source = (YAML.safe_load_file(path) || {}).transform_keys(&:to_s)
    keys = %w[sid wallet_number key_index ipc_url private_key public_cert]
    missing = keys.select { |k| source[k].to_s.strip.empty? || source[k].to_s.include?("your-") || source[k].to_s.include?("...") }
    abort "Fill in these values in #{path.relative_path_from(Rails.root)} first: #{missing.join(', ')}" if missing.any?

    credentials = Rails.application.credentials
    abort "Missing #{credentials.key_path} — cannot decrypt credentials" unless credentials.key.present?

    data = (YAML.safe_load(credentials.read.presence || "", permitted_classes: [Symbol]) || {})
    data["mypos"] = keys.to_h { |k| [k, k == "key_index" ? source[k].to_i : source[k].to_s.strip] }
    credentials.write(data.to_yaml)

    live = !data["mypos"]["ipc_url"].include?("checkout-test")
    puts "Installed myPOS credentials from #{path.relative_path_from(Rails.root)} into #{credentials.content_path.relative_path_from(Rails.root)}"
    puts "  endpoint: #{data['mypos']['ipc_url']}  [#{live ? 'LIVE' : 'TEST'}]"
    puts "Next: commit config/credentials.yml.enc and run `kamal deploy`."
  end
end
