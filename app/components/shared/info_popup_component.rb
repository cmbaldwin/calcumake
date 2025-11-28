# frozen_string_literal: true

module Shared
  # Renders an info icon with a tooltip containing translated documentation
  #
  # @example Basic usage
  #   <%= render Shared::InfoPopupComponent.new(translation_key: "print_pricings.help.job_name") %>
  #
  # @example With custom position
  #   <%= render Shared::InfoPopupComponent.new(
  #     translation_key: "invoices.help.status",
  #     position: "left"
  #   ) %>
  #
  # @example With custom icon size
  #   <%= render Shared::InfoPopupComponent.new(
  #     translation_key: "profile.help.currency",
  #     icon_size: "lg"
  #   ) %>
  class InfoPopupComponent < ViewComponent::Base
    # @param translation_key [String] The i18n key for the tooltip content
    # @param position [String] Tooltip position: 'top', 'bottom', 'left', 'right'
    # @param icon_size [String] Icon size: 'sm', 'md', 'lg'
    # @param html_options [Hash] Additional HTML attributes
    def initialize(translation_key:, position: "top", icon_size: "sm", html_options: {})
      @translation_key = translation_key
      @position = position
      @icon_size = icon_size
      @html_options = html_options
    end

    # Returns the translated tooltip content
    # @return [String]
    def tooltip_content
      I18n.t(@translation_key)
    end

    # Returns combined CSS classes for the info icon container
    # @return [String]
    def css_classes
      classes = [ "info-popup-icon", "d-inline-block", "ms-1" ]
      classes << @html_options[:class] if @html_options[:class]
      classes.compact.join(" ")
    end

    # Returns html_options without class since we handle it separately
    # @return [Hash]
    def html_attrs
      @html_options.except(:class)
    end

    # Returns icon size class for Bootstrap Icons
    # @return [String]
    def icon_size_class
      case @icon_size
      when "sm" then "fs-6"
      when "md" then "fs-5"
      when "lg" then "fs-4"
      else "fs-6"
      end
    end
  end
end
