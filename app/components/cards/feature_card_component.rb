# frozen_string_literal: true

class Cards::FeatureCardComponent < ViewComponent::Base
  def initialize(icon:, title:, description:, features: [], html_options: {})
    @icon = icon
    @title = title
    @description = description
    @features = features
    @html_options = html_options
  end

  private

  attr_reader :icon, :title, :description, :features, :html_options

  def has_features?
    features.present? && features.any?
  end

  def card_classes
    ["card", "border-0", "shadow-sm", "h-100", html_options[:class]].compact.join(" ")
  end

  def icon_class
    "bi bi-#{icon}-fill fs-1"
  end
end
