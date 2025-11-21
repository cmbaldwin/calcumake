# frozen_string_literal: true

class IconComponent < ViewComponent::Base
  SIZES = %w[sm md lg xl].freeze

  def initialize(
    name:,
    size: "md",
    color: nil,
    spin: false,
    html_options: {}
  )
    @name = name
    @size = size
    @color = color
    @spin = spin
    @html_options = html_options

    validate_size!
  end

  def icon_classes
    classes = ["bi", "bi-#{@name}"]
    classes << size_class if @size != "md"
    classes << "icon-spin" if @spin
    classes << @html_options[:class] if @html_options[:class]
    classes.join(" ")
  end

  def icon_styles
    styles = []
    styles << "color: #{@color}" if @color
    styles << @html_options[:style] if @html_options[:style]
    styles.join("; ") if styles.any?
  end

  private

  def size_class
    case @size
    when "sm"
      "icon-sm"
    when "lg"
      "icon-lg"
    when "xl"
      "icon-xl"
    end
  end

  def validate_size!
    return if SIZES.include?(@size)
    raise ArgumentError, "Invalid size: #{@size}. Must be one of: #{SIZES.join(', ')}"
  end
end
