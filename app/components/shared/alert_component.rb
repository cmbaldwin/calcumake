# frozen_string_literal: true

module Shared
  # Renders Bootstrap alert messages with optional dismissible functionality
  #
  # @example Basic alert with message
  #   <%= render Shared::AlertComponent.new(message: "Success!") %>
  #
  # @example Alert with variant and icon
  #   <%= render Shared::AlertComponent.new(message: "Warning!", variant: "warning", icon: "exclamation-triangle") %>
  #
  # @example Non-dismissible alert
  #   <%= render Shared::AlertComponent.new(message: "Info", variant: "info", dismissible: false) %>
  #
  # @example Alert with block content
  #   <%= render Shared::AlertComponent.new(variant: "success") do %>
  #     <strong>Success!</strong> Your changes have been saved.
  #   <% end %>
  class AlertComponent < ViewComponent::Base
    # @param message [String, nil] Alert message text (can be omitted if using block content)
    # @param variant [String] Bootstrap alert variant: 'success', 'info', 'warning', 'danger', 'primary', 'secondary'
    # @param dismissible [Boolean] Whether to show close button
    # @param icon [String, nil] Optional Bootstrap icon name (without 'bi-' prefix)
    # @param html_options [Hash] Additional HTML attributes
    def initialize(message: nil, variant: "info", dismissible: true, icon: nil, html_options: {})
      @message = message
      @variant = variant
      @dismissible = dismissible
      @icon = icon
      @html_options = html_options
    end

    # Returns combined CSS classes for the alert
    # @return [String]
    def css_classes
      classes = ["alert", "alert-#{@variant}"]
      classes << "alert-dismissible fade show" if @dismissible
      classes << @html_options[:class] if @html_options[:class]
      classes.compact.join(" ")
    end

    # Returns html_options without class
    # @return [Hash]
    def html_attrs
      attrs = @html_options.except(:class)
      attrs[:role] = "alert"
      attrs
    end

    # Whether the alert has an icon
    # @return [Boolean]
    def icon?
      @icon.present?
    end

    # Returns alert content (message or block content)
    # @return [String]
    def alert_content
      content || @message
    end
  end
end
