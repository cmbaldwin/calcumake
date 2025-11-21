# frozen_string_literal: true

module Shared
  # Renders Bootstrap badges for status indicators, counts, and labels
  #
  # @example Basic usage
  #   <%= render Shared::BadgeComponent.new(text: "New") %>
  #
  # @example With variant and icon
  #   <%= render Shared::BadgeComponent.new(text: "Active", variant: "success", icon: "check-circle") %>
  #
  # @example Pill style
  #   <%= render Shared::BadgeComponent.new(text: "3", pill: true, variant: "info") %>
  #
  # @example With size
  #   <%= render Shared::BadgeComponent.new(text: "Beta", size: "lg", variant: "warning") %>
  class BadgeComponent < ViewComponent::Base
    # @param text [String] The text content of the badge
    # @param variant [String] Bootstrap color variant: 'primary', 'secondary', 'success', 'danger', 'warning', 'info'
    # @param size [String] Badge size: 'sm', 'md', 'lg'
    # @param icon [String, nil] Optional Bootstrap icon name (without 'bi-' prefix)
    # @param pill [Boolean] Whether to render as pill-shaped badge
    # @param html_options [Hash] Additional HTML attributes
    def initialize(text:, variant: "primary", size: "md", icon: nil, pill: false, html_options: {})
      @text = text
      @variant = variant
      @size = size
      @icon = icon
      @pill = pill
      @html_options = html_options
    end

    # Returns combined CSS classes for the badge
    # @return [String]
    def css_classes
      classes = [ "badge", "bg-#{@variant}" ]
      classes << "rounded-pill" if @pill
      classes << size_class if @size != "md"
      classes << @html_options[:class] if @html_options[:class]
      classes.compact.join(" ")
    end

    # Returns html_options without class since we handle it separately
    # @return [Hash]
    def html_attrs
      @html_options.except(:class)
    end

    # Whether the badge has an icon
    # @return [Boolean]
    def icon?
      @icon.present?
    end

    private

    # Maps size parameter to padding and font-size classes
    # @return [String, nil]
    def size_class
      case @size
      when "sm" then "fs-7 px-2 py-1"
      when "lg" then "fs-5 px-3 py-2"
      end
    end
  end
end
