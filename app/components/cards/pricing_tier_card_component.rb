# frozen_string_literal: true

module Cards
  class PricingTierCardComponent < ViewComponent::Base
    def initialize(
      plan:,
      features:,
      current: false,
      popular: false,
      show_cta: true,
      current_user: nil,
      html_options: {}
    )
      @plan = plan
      @features = features
      @current = current
      @popular = popular
      @show_cta = show_cta
      @current_user = current_user
      @html_options = html_options
    end

    private

    attr_reader :plan, :features, :current, :popular, :show_cta, :current_user, :html_options

    def card_classes
      classes = [ "card", "pricing-card", "h-100" ]
      classes << "popular-plan" if popular
      classes << "current-plan" if current
      classes << "border-primary shadow-lg" if popular
      classes << "border-0 shadow-sm" unless popular
      classes.join(" ")
    end

    def show_trial_badge?
      plan == "free" && current_user&.in_trial_period?
    end

    def trial_days_remaining
      current_user&.trial_days_remaining
    end

    def show_popular_badge?
      popular
    end

    def has_limits?
      features[:limits].present?
    end

    def limit_text(resource, count)
      if count == Float::INFINITY
        I18n.t("subscriptions.features.unlimited_#{resource}")
      else
        I18n.t("subscriptions.features.#{resource}", count: count)
      end
    end

    def additional_features
      features[:features] || []
    end

    def negative_features
      features[:negative_features] || []
    end

    def cta_button_class
      classes = [ "btn", "w-100" ]
      if current
        classes << "btn-outline-secondary"
      elsif popular
        classes << "btn-primary btn-gradient-primary"
      else
        classes << "btn-outline-primary"
      end
      classes.join(" ")
    end

    def cta_text
      return I18n.t("subscriptions.current_plan") if current

      I18n.t("landing.pricing.cta")
    end

    def cta_path
      return nil if current

      Rails.application.routes.url_helpers.new_user_registration_path
    end

    def cta_disabled?
      current
    end
  end
end
