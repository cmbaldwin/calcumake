class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Re-raise ParameterMissing in test environment so tests can catch it with assert_raises
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  before_action :set_locale
  before_action :check_onboarding_needed

  def switch_locale
    locale = params[:locale]
    if I18n.available_locales.include?(locale.to_sym)
      session[:locale] = locale
      # Store in user profile if logged in
      current_user.update(locale: locale) if user_signed_in? && current_user.respond_to?(:locale)
    end
    redirect_back(fallback_location: root_path)
  end

  private

  def handle_parameter_missing(exception)
    # Re-raise in test environment so tests can catch it
    # In other environments, let Rails handle it normally (returns 400 Bad Request)
    raise exception if Rails.env.test?

    # For production/development, render a user-friendly error
    respond_to do |format|
      format.json { render json: { error: "Missing required parameter: #{exception.param}" }, status: :bad_request }
      format.html { redirect_back fallback_location: root_path, alert: "Missing required information. Please try again." }
    end
  end

  def check_onboarding_needed
    return unless user_signed_in?
    return if controller_name == "onboarding"
    return if devise_controller?
    return if current_user.onboarding_completed?
    return unless current_user.needs_onboarding?

    redirect_to onboarding_path, notice: t("onboarding.welcome_message")
  end

  def set_locale
    # Check if locale is set in session, URL param, user preference, or fall back to default
    locale = session[:locale] ||
             params[:locale] ||
             (current_user&.locale) ||
             I18n.default_locale

    # Validate locale before setting
    if I18n.available_locales.include?(locale.to_sym)
      I18n.locale = locale
      # Store the locale in session for future requests
      session[:locale] = I18n.locale.to_s if I18n.locale != I18n.default_locale
    else
      I18n.locale = I18n.default_locale
    end
  end
end
