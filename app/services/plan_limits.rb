# Service class for managing subscription plan limits
# Based on the freemium model defined in LANDING_PAGE_PLAN.md
class PlanLimits
  # Plan limits based on subscription tiers
  FREE_LIMITS = {
    print_pricings: 5,
    printers: 1,
    filaments: 4,
    invoices: 5
  }.freeze

  STARTUP_LIMITS = {
    print_pricings: 50,
    printers: 10,
    filaments: 16,
    invoices: Float::INFINITY
  }.freeze

  PRO_LIMITS = {
    print_pricings: Float::INFINITY,
    printers: Float::INFINITY,
    filaments: Float::INFINITY,
    invoices: Float::INFINITY
  }.freeze

  # Trial period - new users get Startup limits for first month
  TRIAL_DURATION = 30.days

  class << self
    # Get limits for a specific user
    def limits_for(user)
      return STARTUP_LIMITS if user.in_trial_period?

      case user.plan
      when "free" then FREE_LIMITS
      when "startup" then STARTUP_LIMITS
      when "pro" then PRO_LIMITS
      else FREE_LIMITS
      end
    end

    # Check if user can create a new resource of the given type
    def can_create?(user, resource_type)
      limit = limit_for(user, resource_type)
      return true if limit == Float::INFINITY

      current_count = current_usage(user, resource_type)
      current_count < limit
    end

    # Get the limit for a specific resource type
    def limit_for(user, resource_type)
      limits = limits_for(user)
      limits[resource_type.to_sym] || 0
    end

    # Get current usage count for a resource type
    def current_usage(user, resource_type)
      case resource_type.to_s
      when "print_pricing"
        # For print_pricings, use monthly usage tracking
        UsageTracking.current_usage(user, "print_pricing")
      when "printer", "filament"
        # For printers and filaments, count total records
        user.send(resource_type.to_s.pluralize).count
      when "invoice"
        # For invoices, use monthly usage tracking
        UsageTracking.current_usage(user, "invoice")
      else
        0
      end
    end

    # Get remaining resources for a user
    def remaining(user, resource_type)
      limit = limit_for(user, resource_type)
      return Float::INFINITY if limit == Float::INFINITY

      current = current_usage(user, resource_type)
      [limit - current, 0].max
    end

    # Check if user has reached their limit
    def limit_reached?(user, resource_type)
      !can_create?(user, resource_type)
    end

    # Get usage percentage for a resource type
    def usage_percentage(user, resource_type)
      limit = limit_for(user, resource_type)
      return 0 if limit == Float::INFINITY

      current = current_usage(user, resource_type)
      return 100 if limit.zero?

      ((current.to_f / limit) * 100).round
    end

    # Check if user is approaching their limit (>= 80%)
    def approaching_limit?(user, resource_type)
      limit = limit_for(user, resource_type)
      return false if limit == Float::INFINITY

      usage_percentage(user, resource_type) >= 80
    end

    # Get plan features as a hash for display
    def features_for(plan)
      case plan.to_s
      when "free"
        {
          name: "Free",
          price: "$0",
          limits: FREE_LIMITS,
          features: ["CalcuMake branding on invoices", "Community support", "Ads displayed"],
          trial: true
        }
      when "startup"
        {
          name: "Startup",
          price: "$0.99/month",
          limits: STARTUP_LIMITS,
          features: ["Remove CalcuMake branding", "No ads", "Email support"],
          trial: false
        }
      when "pro"
        {
          name: "Pro",
          price: "$9.99/month",
          limits: PRO_LIMITS,
          features: [
            "Unlimited everything",
            "Remove CalcuMake branding",
            "No ads",
            "Priority support",
            "Advanced analytics",
            "Bulk import/export"
          ],
          trial: false
        }
      else
        features_for("free")
      end
    end
  end
end
