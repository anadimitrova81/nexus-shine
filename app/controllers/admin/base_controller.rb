module Admin
  # Base for all admin screens: applies the admin layout and requires login.
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin

    private

    def require_admin
      return if session[:admin_authenticated]
      redirect_to admin_login_path, alert: "Моля, влезте в администрацията."
    end
  end
end
