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

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: kind
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
