# frozen_string_literal: true

class AlertComponent < ViewComponent::Base
  VARIANTS = %w[success info warning danger primary secondary light dark].freeze

  def initialize(
    message: nil,
    variant: "info",
    dismissible: true,
    icon: nil,
    html_options: {}
  )
    @message = message
    @variant = variant
    @dismissible = dismissible
    @icon = icon
    @html_options = html_options

    validate_variant!
  end

  def alert_classes
    classes = ["alert", "alert-#{@variant}"]
    classes << "alert-dismissible fade show" if @dismissible
    classes << @html_options[:class] if @html_options[:class]
    classes.join(" ")
  end

  def default_icon
    return @icon if @icon

    case @variant
    when "success"
      "check-circle-fill"
    when "info"
      "info-circle-fill"
    when "warning"
      "exclamation-triangle-fill"
    when "danger"
      "x-circle-fill"
    end
  end

  private

  def validate_variant!
    return if VARIANTS.include?(@variant)
    raise ArgumentError, "Invalid variant: #{@variant}. Must be one of: #{VARIANTS.join(', ')}"
  end
end
