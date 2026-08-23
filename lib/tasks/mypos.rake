namespace :mypos do
  desc "Validate myPOS config (keys parse + signature self-test). Never prints secrets."
  task check: :environment do
    require "openssl"

    puts "myPOS configuration check"
    puts "  sandbox mode: #{Mypos::Config.sandbox? ? 'ON (local simulator)' : 'off (real myPOS)'}"
    puts "  endpoint:     #{Mypos::Config.ipc_url}"

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

    puts ok ? "\nAll good — myPOS is configured." : "\nConfiguration incomplete (see ✗ above)."
  end
end
