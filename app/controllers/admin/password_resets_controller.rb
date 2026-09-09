module Admin
  # Set a new admin password from a link issued on the server
  # (`bin/rails admin:password_reset_link`). No login required — the signed,
  # 30-minute token is the proof. Also the bootstrap path for the very first
  # password.
  class PasswordResetsController < ApplicationController
    layout "admin"
    before_action :load_account_from_token, only: %i[show update]
    rate_limit to: 3, within: 15.minutes, only: :create,
               with: -> { redirect_to admin_login_path, alert: "Твърде много опити. Опитайте отново след 15 минути." }

    # "Забравена парола?" — e-mail a fresh link to the admin address.
    def create
      unless Mailing::Config.configured? && Mailing::Config.admin_email_configured?
        Rails.logger.error("[admin] password reset requested but SMTP/admin_email is not configured (config/smtp.yml)")
        return redirect_to admin_login_path, alert: "Изпращането на имейли не е настроено. Използвайте `bin/rails admin:password_reset_link` на сървъра."
      end

      account = AdminAccount.current_or_bootstrap!
      url = admin_password_reset_url(account.generate_token_for(:password_reset))
      AdminMailer.password_reset(url).deliver_later
      redirect_to admin_login_path, notice: "Изпратихме линк за нова парола на имейла на администратора. Валиден е 30 минути."
    end

    def show
    end

    def update
      if @account.update(password: params[:password], password_confirmation: params[:password_confirmation])
        reset_session
        session[:admin_authenticated] = true
        redirect_to admin_root_path, notice: "Паролата е зададена. Добре дошли!"
      else
        flash.now[:alert] = @account.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    private

    def load_account_from_token
      @account = AdminAccount.find_by_token_for(:password_reset, params[:token].to_s)
      return if @account
      redirect_to admin_login_path, alert: "Линкът за смяна на паролата е невалиден или е изтекъл. Генерирайте нов от сървъра."
    end
  end
end
