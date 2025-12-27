# frozen_string_literal: true

class Cards::ResinCardComponent < ViewComponent::Base
  def initialize(resin:, current_user:, html_options: {})
    @resin = resin
    @current_user = current_user
    @html_options = html_options
  end

  private

  attr_reader :resin, :current_user, :html_options

  def card_classes
    [ "card", "h-100", html_options[:class] ].compact.join(" ")
  end

  def has_brand?
    resin.brand.present?
  end

  def has_color?
    resin.color.present?
  end

  def has_cost_data?
    resin.bottle_price.present? && resin.bottle_volume_ml.present?
  end

  def formatted_cost_per_ml
    "#{currency_symbol}#{format('%.4f', resin.cost_per_ml)}/mL"
  end

  def currency_symbol
    helpers.currency_symbol(current_user.default_currency)
  end

  def needs_wash?
    resin.needs_wash?
  end

  def confirm_delete_message
    I18n.t("resins.confirm_delete", name: resin.name)
  end
end
