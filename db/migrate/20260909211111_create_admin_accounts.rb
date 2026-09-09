class CreateAdminAccounts < ActiveRecord::Migration[8.1]
  def change
    # Single-row table holding the bcrypt digest of the admin password so it can
    # be changed from inside the app (Admin → Парола) or reset with a
    # console-generated link (bin/rails admin:password_reset_link).
    create_table :admin_accounts do |t|
      t.string :password_digest, null: false
      t.timestamps
    end
  end
end
