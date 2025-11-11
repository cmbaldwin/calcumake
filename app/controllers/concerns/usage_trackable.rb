# Concern for tracking user resource usage and enforcing plan limits
module UsageTrackable
  extend ActiveSupport::Concern

  included do
    before_action :check_resource_limit, only: [ :create ]
    after_action :track_resource_creation, only: [ :create ]
  end

  private

  # Check if user has reached their plan limit for this resource
  def check_resource_limit
    return unless user_signed_in?
    return if skip_limit_check?

    resource_name = resource_type_for_tracking

    unless current_user.can_create?(resource_name)
      handle_limit_reached(resource_name)
    end
  end

  # Track resource creation for usage-based limits
  def track_resource_creation
    return unless user_signed_in?
    return unless response.successful?
    return if skip_usage_tracking?

    resource_name = resource_type_for_tracking

    # Only track resources that use monthly limits
    if %w[print_pricing invoice].include?(resource_name)
      UsageTracking.track!(current_user, resource_name)
    end
  end

  # Get the resource type name for tracking from controller name
  def resource_type_for_tracking
    controller_name.singularize
  end

  # Override this in controllers that should skip limit checks
  def skip_limit_check?
    false
  end

  # Override this in controllers that should skip usage tracking
  def skip_usage_tracking?
    false
  end

  # Handle when user reaches their plan limit
  def handle_limit_reached(resource_type)
    limit = current_user.limit_for(resource_type)
    plan_name = current_user.plan.titleize

    respond_to do |format|
      format.html do
        flash[:alert] = t("usage_limits.limit_reached",
                         resource: resource_type.humanize.downcase,
                         limit: limit,
                         plan: plan_name)
        redirect_to upgrade_path
      end
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash",
                                                  locals: {
                                                    flash: {
                                                      alert: t("usage_limits.limit_reached",
                                                              resource: resource_type.humanize.downcase,
                                                              limit: limit,
                                                              plan: plan_name)
                                                    }
                                                  })
      end
      format.json do
        render json: {
          error: t("usage_limits.limit_reached",
                  resource: resource_type.humanize.downcase,
                  limit: limit,
                  plan: plan_name),
          upgrade_url: upgrade_path
        }, status: :forbidden
      end
    end
  end

  # Path to upgrade page
  def upgrade_path
    pricing_subscriptions_path
  end
end
