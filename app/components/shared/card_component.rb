# frozen_string_literal: true

module Shared
  # Renders Bootstrap card wrapper with optional header, body, and footer slots
  #
  # @example Basic card
  #   <%= render Shared::CardComponent.new do |c| %>
  #     <% c.with_body do %>
  #       Card content here
  #     <% end %>
  #   <% end %>
  #
  # @example Card with header and footer
  #   <%= render Shared::CardComponent.new do |c| %>
  #     <% c.with_header do %>
  #       Card Title
  #     <% end %>
  #     <% c.with_body do %>
  #       Card content
  #     <% end %>
  #     <% c.with_footer do %>
  #       Footer actions
  #     <% end %>
  #   <% end %>
  #
  # @example Card with variant and custom classes
  #   <%= render Shared::CardComponent.new(variant: "primary", shadow: true) do |c| %>
  #     <% c.with_body(class: "text-center") do %>
  #       Centered content
  #     <% end %>
  #   <% end %>
  class CardComponent < ViewComponent::Base
    # @param variant [String, nil] Bootstrap color variant: 'primary', 'secondary', 'success', 'danger', 'warning', 'info'
    # @param shadow [Boolean, String] Add shadow: true (shadow-sm), 'lg' (shadow-lg), false (no shadow)
    # @param border [Boolean] Whether to show border
    # @param html_options [Hash] Additional HTML attributes for the card wrapper
    def initialize(variant: nil, shadow: false, border: true, html_options: {})
      @variant = variant
      @shadow = shadow
      @border = border
      @html_options = html_options
      @header_class = nil
      @body_class = nil
      @footer_class = nil
    end

    # Slot definitions with custom class support
    renders_one :header
    renders_one :body
    renders_one :footer    # Returns combined CSS classes for the card wrapper
    # @return [String]
    def css_classes
      classes = [ "card" ]
      classes << "bg-#{@variant}" if @variant
      classes << "text-white" if @variant && text_white_variants.include?(@variant)
      classes << shadow_class if @shadow
      classes << "border-0" unless @border
      classes << @html_options[:class] if @html_options[:class]
      classes.compact.join(" ")
    end

    # Returns html_options without class
    # @return [Hash]
    def html_attrs
      @html_options.except(:class)
    end

    # Returns CSS classes for card header
    # @return [String]
    def header_classes
      classes = ["card-header"]
      classes << "bg-#{@variant}" if @variant
      classes << "text-white" if @variant && text_white_variants.include?(@variant)
      classes.compact.join(" ")
    end

    # Returns CSS classes for card body
    # @return [String]
    def body_classes
      ["card-body"].join(" ")
    end

    # Returns CSS classes for card footer
    # @return [String]
    def footer_classes
      ["card-footer"].join(" ")
    end

    private

    # Returns shadow class based on shadow parameter
    # @return [String, nil]
    def shadow_class
      case @shadow
      when true then "shadow-sm"
      when "sm" then "shadow-sm"
      when "lg" then "shadow-lg"
      when String then "shadow-#{@shadow}"
      end
    end

    # Variants that should have white text
    # @return [Array<String>]
    def text_white_variants
      %w[primary secondary success danger dark]
    end
  end
end
