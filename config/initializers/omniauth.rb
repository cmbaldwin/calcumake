# OmniAuth configuration
OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true

# CSRF protection for OmniAuth
Rails.application.config.middleware.use OmniAuth::Builder do
  # Providers are configured in devise.rb
end
