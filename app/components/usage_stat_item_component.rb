# frozen_string_literal: true

class UsageStatItemComponent < ViewComponent::Base
  def initialize(resource:, current:, limit:, warning_threshold: 80)
    @resource = resource
    @current = current
    @limit = limit
    @warning_threshold = warning_threshold
  end

  def percentage
    return 0 if unlimited?
    return 0 if @limit.zero?
    ((@current.to_f / @limit) * 100).round
  end

  def unlimited?
    @limit == Float::INFINITY
  end

  def progress_color
    percentage >= @warning_threshold ? "bg-warning" : "bg-success"
  end

  def badge_text
    unlimited? ? I18n.t('usage_limits.unlimited') : "#{@current}/#{@limit}"
  end

  def resource_label
    I18n.t("models.#{@resource}_plural", default: @resource.to_s.titleize)
  end
end
