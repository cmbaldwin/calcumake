class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :set_locale
  
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
