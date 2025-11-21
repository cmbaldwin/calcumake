# frozen_string_literal: true

module Shared
  # Renders Bootstrap Icons with consistent styling
  #
  # @example Basic usage
  #   <%= render Shared::IconComponent.new(name: "check") %>
  #
  # @example With size and color
  #   <%= render Shared::IconComponent.new(name: "x-circle", size: "lg", color: "danger") %>
  #
  # @example Spinning loader
  #   <%= render Shared::IconComponent.new(name: "arrow-clockwise", spin: true) %>
  class IconComponent < ViewComponent::Base
    # @param name [String] Bootstrap icon name (without 'bi-' prefix)
    # @param size [String] Icon size: 'sm', 'md', 'lg', 'xl'
    # @param color [String] Bootstrap color class: 'primary', 'danger', 'success', etc.
    # @param spin [Boolean] Whether icon should spin (for loading states)
    # @param html_options [Hash] Additional HTML attributes
    def initialize(name:, size: "md", color: nil, spin: false, html_options: {})
      @name = name
      @size = size
      @color = color
      @spin = spin
      @html_options = html_options
    end

    # Returns combined CSS classes for the icon
    # @return [String]
    def css_classes
      classes = [ "bi", "bi-#{@name}" ]
      classes << size_class if @size != "md"
      classes << "text-#{@color}" if @color
      classes << "icon-spin" if @spin
      classes << @html_options[:class] if @html_options[:class]
      classes.compact.join(" ")
    end

    # Returns html_options without class since we handle it separately
    # @return [Hash]
    def html_attrs
      @html_options.except(:class)
    end

    private

    # Returns size class based on size parameter
    # @return [String, nil]
    def size_class
      case @size
      when "sm" then "fs-6"
      when "lg" then "fs-4"
      when "xl" then "fs-2"
      end
    end
  end
end
