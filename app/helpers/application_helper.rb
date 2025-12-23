module ApplicationHelper
  def page_title(title = nil)
    if title.present?
      "#{title} | #{t('nav.brand')}"
    else
      t("nav.brand")
    end
  end

  def bootstrap_flash_class(flash_type)
    case flash_type.to_s
    when "notice", "success"
      "alert-success"
    when "alert", "error"
      "alert-danger"
    when "warning"
      "alert-warning"
    else
      "alert-info"
    end
  end

  def format_boolean(value)
    value ? t("common.yes") : t("common.no")
  end

  def format_percentage(value)
    return "0%" if value.nil? || value == 0
    "#{value}%"
  end

  def translate_filament_type(filament_type)
    return "" if filament_type.blank?
    t("print_pricing.filament_types.#{filament_type.downcase}")
  end

  def oauth_provider_icon(provider)
    render(Shared::OAuthIconComponent.new(provider: provider))
  end

  def oauth_provider_button_class(provider)
    case provider.to_s.downcase
    when "google"
      "btn btn-outline-danger"
    when "github"
      "btn btn-outline-dark"
    when "microsoft"
      "btn btn-outline-primary"
    when "facebook"
      "btn btn-outline-primary"
    when "yahoo japan", "yahoo! japan", "yahoojp"
      "btn btn-outline-danger"
    when "line"
      "btn btn-outline-success"
    else
      "btn btn-outline-secondary"
    end
  end

  # Get list of OAuth providers configured for display in views
  def oauth_providers_for_view
    enabled_providers = OAuthHelper.enabled_providers
    enabled_providers.map do |provider|
      {
        name: OAuthHelper.provider_name(provider),
        path: user_oauth_path(provider)
      }
    end
  end

  # Helper to generate OAuth callback path
  def user_oauth_path(provider)
    "/users/auth/#{provider}"
  end

  # Format price with USD conversion
  # @param amount [Numeric] The price amount
  # @param currency [String] Source currency code (e.g., 'JPY', 'USD')
  # @return [String] Formatted price with USD conversion (e.g., "¥150 ($1.23)")
  def format_price_with_usd(amount, currency = "JPY")
    return "$0" if amount.to_i.zero?

    # Format primary price
    primary_price = case currency.upcase
    when "JPY"
      "¥#{number_with_delimiter(amount)}"
    when "USD"
      "$#{number_with_precision(amount, precision: 2)}"
    else
      "#{currency} #{number_with_precision(amount, precision: 2)}"
    end

    # Return primary price only if it's already USD
    return primary_price if currency.upcase == "USD"

    # Convert to USD
    usd_amount = CurrencyConverter.convert(amount, from: currency, to: "USD")

    if usd_amount
      usd_formatted = "$#{number_with_precision(usd_amount, precision: 2)}"
      content_tag(:span, class: "price-with-conversion") do
        safe_join([
          content_tag(:span, primary_price, class: "primary-price"),
          " ",
          content_tag(:span, "(~#{usd_formatted})", class: "text-muted small usd-conversion")
        ])
      end
    else
      # Fallback to primary price only if conversion fails
      primary_price
    end
  end
end
