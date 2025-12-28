class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2, :github, :microsoft_graph, :facebook, :yahoojp, :line ]

  def google_oauth2
    handle_auth("Google")
  end

  def github
    handle_auth("GitHub")
  end

  def microsoft_graph
    handle_auth("Microsoft")
  end

  def facebook
    handle_auth("Facebook")
  end

  def yahoojp
    handle_auth("Yahoo Japan")
  end

  def line
    handle_auth("LINE")
  end

  def failure
    redirect_to new_user_registration_url, alert: "Authentication failed."
  end

  private

  def handle_auth(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    # Handle missing email (common with LINE)
    if @user.nil?
      session["devise.omniauth_data"] = request.env["omniauth.auth"].except("extra")
      session["devise.omniauth_provider"] = kind
      redirect_to users_omniauth_complete_profile_path, notice: "Please provide your email to complete registration"
      return
    end

    if @user.persisted?
      sign_in @user, event: :authentication

      # Redirect new users to onboarding
      if @user.needs_onboarding?
        redirect_to onboarding_path, notice: I18n.t("onboarding.welcome_oauth", kind: kind)
      else
        redirect_to root_path, notice: I18n.t("devise.omniauth_callbacks.success", kind: kind)
      end
    else
      session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
