# frozen_string_literal: true

class Cards::ProblemCardComponent < ViewComponent::Base
  def initialize(icon:, icon_color:, title:, description:, html_options: {})
    @icon = icon
    @icon_color = icon_color
    @title = title
    @description = description
    @html_options = html_options
  end

  private

  attr_reader :icon, :icon_color, :title, :description, :html_options

  def card_classes
    [ "card", "h-100", "border-0", "shadow-sm", html_options[:class] ].compact.join(" ")
  end

  def icon_class
    "bi bi-#{icon} text-#{icon_color} fs-1 mb-3"
  end
end
