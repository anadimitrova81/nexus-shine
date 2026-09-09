# The single admin login. Stores a bcrypt digest of the password; the row is
# created on first use (initial password via console reset link or the
# credentials/ENV fallback in Admin::SessionsController).
class AdminAccount < ApplicationRecord
  has_secure_password

  MIN_PASSWORD_LENGTH = 12
  validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, allow_nil: true

  # Reset links are valid for 30 minutes and die as soon as the password changes.
  generates_token_for :password_reset, expires_in: 30.minutes do
    password_salt&.last(10)
  end

  def self.current
    first
  end

  # Creates the row with an unguessable throwaway password so a reset link can
  # be issued before any password has ever been set.
  def self.current_or_bootstrap!
    current || create!(password: SecureRandom.base58(32))
  end
end
