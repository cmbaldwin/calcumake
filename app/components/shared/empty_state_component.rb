# frozen_string_literal: true

module Shared
  class EmptyStateComponent < ViewComponent::Base
    def initialize(
      title:,
      description: nil,
      action_text: nil,
      action_url: nil,
      action_variant: "primary",
      icon: nil,
      html_options: {}
    )
      @title = title
      @description = description
      @action_text = action_text
      @action_url = action_url
      @action_variant = action_variant
      @icon = icon
      @html_options = html_options
    end

    private

    attr_reader :title, :description, :action_text, :action_url, :action_variant, :icon, :html_options

    def wrapper_classes
      classes = [ "text-center", "py-5" ]
      classes << html_options[:class] if html_options[:class].present?
      classes.join(" ")
    end

    def has_action?
      action_text.present? && action_url.present?
    end

    def has_icon?
      icon.present?
    end

    def action_button_class
      "btn btn-#{action_variant}"
    end
  end
end
