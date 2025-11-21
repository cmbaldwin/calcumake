# frozen_string_literal: true

class CardComponent < ViewComponent::Base
  VARIANTS = %w[default primary secondary success danger warning info light dark transparent].freeze

  renders_one :header
  renders_one :body
  renders_one :footer

  def initialize(
    variant: "default",
    shadow: true,
    border: true,
    header_class: "",
    body_class: "",
    footer_class: "",
    html_options: {}
  )
    @variant = variant
    @shadow = shadow
    @border = border
    @header_class = header_class
    @body_class = body_class
    @footer_class = footer_class
    @html_options = html_options

    validate_variant!
  end

  def card_classes
    classes = ["card"]
    classes << variant_class unless @variant == "default"
    classes << "shadow" if @shadow
    classes << "border-0" unless @border
    classes << @html_options[:class] if @html_options[:class]
    classes.join(" ")
  end

  def header_classes
    classes = ["card-header"]
    classes << @header_class if @header_class.present?
    classes.join(" ")
  end

  def body_classes
    classes = ["card-body"]
    classes << @body_class if @body_class.present?
    classes.join(" ")
  end

  def footer_classes
    classes = ["card-footer"]
    classes << @footer_class if @footer_class.present?
    classes.join(" ")
  end

  private

  def variant_class
    case @variant
    when "transparent"
      "bg-transparent"
    else
      "border-#{@variant}"
    end
  end

  def validate_variant!
    return if VARIANTS.include?(@variant)
    raise ArgumentError, "Invalid variant: #{@variant}. Must be one of: #{VARIANTS.join(', ')}"
  end
end
