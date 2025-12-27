# Configure additional assets for Rails Admin
Rails.application.config.to_prepare do
  # Ensure Lexxy styles are available in Rails Admin
  Rails.application.config.assets.precompile += %w[lexxy.css]
end
