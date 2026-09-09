namespace :admin do
  desc "Set the admin password in encrypted Rails credentials from config/admin_password.local (deleted afterwards). Never prints the password."
  task set_password: :environment do
    path = Rails.root.join("config", "admin_password.local")
    abort "Create #{path.relative_path_from(Rails.root)} containing the new password on a single line, e.g.\n  openssl rand -base64 18 > config/admin_password.local" unless path.exist?

    password = path.read.strip
    abort "Password must be at least 12 characters (got #{password.length})." if password.length < 12

    credentials = Rails.application.credentials
    abort "Missing #{credentials.key_path} — cannot decrypt credentials" unless credentials.key.present?

    data = (YAML.safe_load(credentials.read.presence || "", permitted_classes: [Symbol]) || {})
    data["admin_password"] = password
    credentials.write(data.to_yaml)
    path.delete

    puts "Admin password (#{password.length} chars) installed into #{credentials.content_path.relative_path_from(Rails.root)}; removed #{path.relative_path_from(Rails.root)}."
    puts "Next: commit config/credentials.yml.enc and run `kamal deploy`."
  end
end
