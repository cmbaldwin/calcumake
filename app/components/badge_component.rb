# frozen_string_literal: true

class BadgeComponent < ViewComponent::Base
  VARIANTS = %w[primary secondary success danger warning info light dark].freeze
  SIZES = %w[sm md lg].freeze

  def initialize(
    text:,
    variant: "primary",
    size: "md",
    icon: nil,
    pill: false,
    html_options: {}
  )
    @text = text
    @variant = variant
    @size = size
    @icon = icon
    @pill = pill
    @html_options = html_options

    validate_variant!
    validate_size!
  end

  def badge_classes
    classes = ["badge", "bg-#{@variant}"]
    classes << "rounded-pill" if @pill
    classes << size_class if @size != "md"
    classes << @html_options[:class] if @html_options[:class]
    classes.join(" ")
  end

  private

  def size_class
    case @size
    when "sm"
      "badge-sm"
    when "lg"
      "badge-lg"
    end
  end

  def validate_variant!
    return if VARIANTS.include?(@variant)
    raise ArgumentError, "Invalid variant: #{@variant}. Must be one of: #{VARIANTS.join(', ')}"
  end

  def validate_size!
    return if SIZES.include?(@size)
    raise ArgumentError, "Invalid size: #{@size}. Must be one of: #{SIZES.join(', ')}"
  end
end
