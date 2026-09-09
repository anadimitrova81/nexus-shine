module Admin
  # Change the admin password from inside the admin (requires the current one).
  class PasswordsController < BaseController
    def edit
      @account = AdminAccount.current
    end

    def update
      account = AdminAccount.current
      unless account&.authenticate(params[:current_password].to_s)
        flash.now[:alert] = "Текущата парола не е вярна."
        return render :edit, status: :unprocessable_entity
      end

      if account.update(password: params[:password], password_confirmation: params[:password_confirmation])
        redirect_to admin_root_path, notice: "Паролата е сменена."
      else
        flash.now[:alert] = account.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
