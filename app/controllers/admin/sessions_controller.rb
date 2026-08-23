module Admin
  # Single-password admin gate. The password comes from Rails credentials
  # (admin_password) or the ADMIN_PASSWORD env var, with a dev-only fallback.
  class SessionsController < ApplicationController
    layout "admin"

    def new
      redirect_to admin_root_path if session[:admin_authenticated]
    end

    def create
      if valid_password?(params[:password])
        session[:admin_authenticated] = true
        redirect_to admin_root_path, notice: "Добре дошли!"
      else
        flash.now[:alert] = "Грешна парола."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to admin_login_path, notice: "Излязохте от администрацията."
    end

    private

    def valid_password?(input)
      ActiveSupport::SecurityUtils.secure_compare(
        Digest::SHA256.hexdigest(input.to_s),
        Digest::SHA256.hexdigest(admin_password),
      )
    end

    def admin_password
      Rails.application.credentials.admin_password.presence ||
        ENV["ADMIN_PASSWORD"].presence ||
        "shine-admin"
    end
  end
end
