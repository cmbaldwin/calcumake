class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Re-raise ParameterMissing in test environment so tests can catch it with assert_raises
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  before_action :set_locale

  # Memoized helper for info popups enabled state
  # Prevents multiple DB queries per request
  helper_method :info_popups_enabled?

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

  # Memoized check for info popups enabled state
  # Caches the result for the duration of the request
  # Returns: Boolean - true if user has info popups enabled, false otherwise
  def info_popups_enabled?
    return @info_popups_enabled if defined?(@info_popups_enabled)

    @info_popups_enabled = if user_signed_in?
      current_user.info_popups_enabled?
    else
      true # Default to enabled for non-authenticated users
    end
  end
end
