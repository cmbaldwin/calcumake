# frozen_string_literal: true

class Cards::FilamentCardComponent < ViewComponent::Base
  def initialize(filament:, current_user:, html_options: {})
    @filament = filament
    @current_user = current_user
    @html_options = html_options
  end

  private

  attr_reader :filament, :current_user, :html_options

  def card_classes
    [ "card", "h-100", html_options[:class] ].compact.join(" ")
  end

  def has_brand?
    filament.brand.present?
  end

  def has_color?
    filament.color.present?
  end

  def has_cost_data?
    filament.spool_price.present? && filament.spool_weight.present?
  end

  def formatted_cost_per_gram
    "#{currency_symbol}#{format('%.3f', filament.cost_per_gram)}/g"
  end

  def currency_symbol
    helpers.currency_symbol(current_user.default_currency)
  end

  def is_moisture_sensitive?
    filament.moisture_sensitive?
  end

  def confirm_delete_message
    I18n.t("filaments.confirm_delete", name: filament.name)
  end
end
