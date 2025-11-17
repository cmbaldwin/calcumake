class Users::Omniauth::CompleteProfileController < ApplicationController
  # Show form to collect missing email for OAuth providers like LINE
  def show
    unless session["devise.omniauth_data"]
      redirect_to root_path, alert: "Session expired. Please sign in again."
      return
    end

    @provider = session["devise.omniauth_provider"]
    @user = User.new
  end

  # Create user with provided email
  def create
    unless session["devise.omniauth_data"]
      redirect_to root_path, alert: "Session expired. Please sign in again."
      return
    end

    @provider = session["devise.omniauth_provider"]
    auth_data = session["devise.omniauth_data"]
    email = params[:user][:email]

    # Check if email is already taken
    if User.exists?(email: email)
      @user = User.new(email: email)
      @user.errors.add(:email, "is already taken")
      render :show, status: :unprocessable_entity
      return
    end

    # Create user with the provided email
    @user = User.create_from_omniauth_with_email(auth_data, email)

    if @user.persisted?
      # Clear session data
      session.delete("devise.omniauth_data")
      session.delete("devise.omniauth_provider")

      # Sign in and redirect
      sign_in @user
      redirect_to root_path, notice: I18n.t("devise.omniauth_callbacks.success", kind: @provider)
    else
      render :show, status: :unprocessable_entity
    end
  end
end
