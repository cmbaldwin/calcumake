module OauthHelper
  # Configure Devise OmniAuth with all available providers
  # Only configures providers that have credentials set in environment/secrets
  def self.configure_devise_omniauth(config)
    # Google OAuth2
    if ENV['GOOGLE_OAUTH_CLIENT_ID'].present? && ENV['GOOGLE_OAUTH_CLIENT_SECRET'].present?
      config.omniauth :google_oauth2,
                      ENV['GOOGLE_OAUTH_CLIENT_ID'],
                      ENV['GOOGLE_OAUTH_CLIENT_SECRET'],
                      scope: 'email,profile',
                      name: 'google_oauth2'
    end

    # GitHub
    if ENV['GITHUB_OAUTH_CLIENT_ID'].present? && ENV['GITHUB_OAUTH_CLIENT_SECRET'].present?
      config.omniauth :github,
                      ENV['GITHUB_OAUTH_CLIENT_ID'],
                      ENV['GITHUB_OAUTH_CLIENT_SECRET'],
                      scope: 'user:email'
    end

    # Microsoft Graph (Azure AD)
    if ENV['MICROSOFT_OAUTH_CLIENT_ID'].present? && ENV['MICROSOFT_OAUTH_CLIENT_SECRET'].present?
      config.omniauth :microsoft_graph,
                      ENV['MICROSOFT_OAUTH_CLIENT_ID'],
                      ENV['MICROSOFT_OAUTH_CLIENT_SECRET'],
                      scope: 'https://graph.microsoft.com/User.Read'
    end

    # Facebook
    if ENV['FACEBOOK_OAUTH_CLIENT_ID'].present? && ENV['FACEBOOK_OAUTH_CLIENT_SECRET'].present?
      config.omniauth :facebook,
                      ENV['FACEBOOK_OAUTH_CLIENT_ID'],
                      ENV['FACEBOOK_OAUTH_CLIENT_SECRET'],
                      scope: 'email,public_profile',
                      info_fields: 'email,name'
    end

    # Yahoo Japan
    if ENV['YAHOOJP_OAUTH_CLIENT_ID'].present? && ENV['YAHOOJP_OAUTH_CLIENT_SECRET'].present?
      config.omniauth :yahoojp,
                      ENV['YAHOOJP_OAUTH_CLIENT_ID'],
                      ENV['YAHOOJP_OAUTH_CLIENT_SECRET'],
                      scope: 'openid,email,profile'
    end

    # LINE
    if ENV['LINE_CHANNEL_ID'].present? && ENV['LINE_CHANNEL_SECRET'].present?
      config.omniauth :line,
                      ENV['LINE_CHANNEL_ID'],
                      ENV['LINE_CHANNEL_SECRET'],
                      scope: 'profile openid email'
    end
  end

  # Get list of enabled OAuth providers (those with credentials configured)
  def self.enabled_providers
    # In test environment, return all providers for testing
    if Rails.env.test?
      return [:google_oauth2, :github, :microsoft_graph, :facebook, :yahoojp, :line]
    end

    providers = []
    providers << :google_oauth2 if ENV['GOOGLE_OAUTH_CLIENT_ID'].present?
    providers << :github if ENV['GITHUB_OAUTH_CLIENT_ID'].present?
    providers << :microsoft_graph if ENV['MICROSOFT_OAUTH_CLIENT_ID'].present?
    providers << :facebook if ENV['FACEBOOK_OAUTH_CLIENT_ID'].present?
    providers << :yahoojp if ENV['YAHOOJP_OAUTH_CLIENT_ID'].present?
    providers << :line if ENV['LINE_CHANNEL_ID'].present?
    providers
  end

  # Provider display names for UI
  def self.provider_name(provider)
    case provider.to_sym
    when :google_oauth2
      'Google'
    when :github
      'GitHub'
    when :microsoft_graph
      'Microsoft'
    when :facebook
      'Facebook'
    when :yahoojp
      'Yahoo! JAPAN'
    when :line
      'LINE'
    else
      provider.to_s.titleize
    end
  end
end
