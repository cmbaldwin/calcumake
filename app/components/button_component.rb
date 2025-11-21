# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  VARIANTS = %w[primary secondary success danger warning info light dark outline-primary outline-secondary outline-success outline-danger outline-warning outline-info outline-light outline-dark link].freeze
  SIZES = %w[sm md lg].freeze

  def initialize(
    text: nil,
    variant: "primary",
    size: "md",
    icon: nil,
    url: nil,
    method: :get,
    data: {},
    html_options: {},
    type: "button"
  )
    @text = text
    @variant = variant
    @size = size
    @icon = icon
    @url = url
    @method = method
    @data = data
    @html_options = html_options
    @type = type

    validate_variant!
    validate_size!
  end

  def button_classes
    classes = ["btn", "btn-#{@variant}"]
    classes << "btn-#{@size}" unless @size == "md"
    classes << @html_options[:class] if @html_options[:class]
    classes.join(" ")
  end

  def link?
    @url.present?
  end

  def link_options
    options = @html_options.except(:class)
    options[:class] = button_classes
    options[:method] = @method if @method != :get
    options[:data] = @data if @data.present?
    options
  end

  def button_options
    options = @html_options.except(:class)
    options[:class] = button_classes
    options[:type] = @type
    options[:data] = @data if @data.present?
    options
  end

  private

  def validate_variant!
    return if VARIANTS.include?(@variant)
    raise ArgumentError, "Invalid variant: #{@variant}. Must be one of: #{VARIANTS.join(', ')}"
  end

  def validate_size!
    return if SIZES.include?(@size)
    raise ArgumentError, "Invalid size: #{@size}. Must be one of: #{SIZES.join(', ')}"
  end
end
