# frozen_string_literal: true

module Shared
  # Renders Bootstrap buttons with consistent styling and behavior
  #
  # @example Basic button
  #   <%= render Shared::ButtonComponent.new(text: "Save") %>
  #
  # @example Link button
  #   <%= render Shared::ButtonComponent.new(text: "View Details", url: product_path(@product)) %>
  #
  # @example Button with icon
  #   <%= render Shared::ButtonComponent.new(text: "Delete", variant: "danger", icon: "trash", method: :delete) %>
  #
  # @example Loading state
  #   <%= render Shared::ButtonComponent.new(text: "Processing...", loading: true) %>
  #
  # @example With block content
  #   <%= render Shared::ButtonComponent.new(variant: "primary") do %>
  #     <strong>Custom</strong> Content
  #   <% end %>
  class ButtonComponent < ViewComponent::Base
    # @param text [String, nil] Button text (can be omitted if using block content)
    # @param variant [String] Bootstrap button variant: 'primary', 'secondary', 'success', 'danger', 'warning', 'info', 'outline-primary', etc.
    # @param size [String] Button size: 'sm', 'md', 'lg'
    # @param icon [String, nil] Optional Bootstrap icon name (without 'bi-' prefix)
    # @param icon_position [Symbol] Icon position: :left or :right
    # @param url [String, nil] URL for link buttons (uses link_to)
    # @param method [Symbol] HTTP method for link buttons: :get, :post, :delete, :patch, :put
    # @param loading [Boolean] Whether to show loading spinner
    # @param disabled [Boolean] Whether button is disabled
    # @param type [String] Button type attribute: 'button', 'submit', 'reset'
    # @param html_options [Hash] Additional HTML attributes
    def initialize(
      text: nil,
      variant: "primary",
      size: "md",
      icon: nil,
      icon_position: :left,
      url: nil,
      method: :get,
      loading: false,
      disabled: false,
      type: "button",
      html_options: {}
    )
      @text = text
      @variant = variant
      @size = size
      @icon = icon
      @icon_position = icon_position
      @url = url
      @method = method
      @loading = loading
      @disabled = disabled
      @type = type
      @html_options = html_options
    end

    # Returns combined CSS classes for the button
    # @return [String]
    def css_classes
      classes = ["btn", "btn-#{@variant}"]
      classes << size_class if @size != "md"
      classes << "disabled" if @disabled
      classes << @html_options[:class] if @html_options[:class]
      classes.compact.join(" ")
    end

    # Returns html_options without class since we handle it separately
    # @return [Hash]
    def html_attrs
      attrs = @html_options.except(:class)

      # Add type attribute for non-link buttons
      attrs[:type] = @type unless link?

      # Add disabled attribute if disabled
      attrs[:disabled] = true if @disabled && !link?

      # Add method data attribute for non-GET link buttons
      if link? && @method != :get
        attrs[:data] ||= {}
        attrs[:data][:turbo_method] = @method
      end

      attrs
    end

    # Whether this is a link button (has URL)
    # @return [Boolean]
    def link?
      @url.present?
    end

    # Whether button has an icon
    # @return [Boolean]
    def icon?
      @icon.present? && !@loading
    end

    # Whether icon should appear on the left
    # @return [Boolean]
    def icon_left?
      icon? && @icon_position == :left
    end

    # Whether icon should appear on the right
    # @return [Boolean]
    def icon_right?
      icon? && @icon_position == :right
    end

    # Returns button content (text or block content)
    # @return [String]
    def button_content
      content || @text
    end

    private

    # Maps size parameter to Bootstrap button size class
    # @return [String, nil]
    def size_class
      case @size
      when "sm" then "btn-sm"
      when "lg" then "btn-lg"
      end
    end
  end
end
