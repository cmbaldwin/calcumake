# Controller for managing user subscriptions via Stripe
class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  # GET /subscriptions/pricing
  # Show pricing plans and upgrade options
  def pricing
    @current_plan = current_user.plan
    @plans = {
      free: PlanLimits.features_for("free"),
      startup: PlanLimits.features_for("startup"),
      pro: PlanLimits.features_for("pro")
    }

    # Usage stats for current user
    @usage = {
      print_pricings: {
        current: current_user.current_usage("print_pricing"),
        limit: current_user.limit_for("print_pricing"),
        percentage: current_user.usage_percentage("print_pricing")
      },
      printers: {
        current: current_user.current_usage("printer"),
        limit: current_user.limit_for("printer"),
        percentage: current_user.usage_percentage("printer")
      },
      filaments: {
        current: current_user.current_usage("filament"),
        limit: current_user.limit_for("filament"),
        percentage: current_user.usage_percentage("filament")
      },
      invoices: {
        current: current_user.current_usage("invoice"),
        limit: current_user.limit_for("invoice"),
        percentage: current_user.usage_percentage("invoice")
      }
    }
  end

  # POST /subscriptions/create_checkout_session
  # Create Stripe checkout session for upgrading
  def create_checkout_session
    plan = params[:plan]

    unless %w[startup pro].include?(plan)
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.invalid_plan")
      return
    end

    # Prevent creating duplicate subscriptions
    if current_user.stripe_subscription_id.present?
      # Check if subscription is still active in Stripe
      begin
        subscription = Stripe::Subscription.retrieve(current_user.stripe_subscription_id)
        if subscription["status"] == "active" || subscription["status"] == "trialing"
          redirect_to pricing_subscriptions_path, alert: t("subscriptions.already_subscribed")
          return
        end
      rescue Stripe::InvalidRequestError
        # Subscription doesn't exist in Stripe, allow creating new one
        Rails.logger.info "Previous subscription #{current_user.stripe_subscription_id} not found, creating new"
      end
    end

    begin
      # Create or retrieve Stripe customer
      customer = get_or_create_stripe_customer

      # Stripe price IDs (should be configured in credentials or env)
      price_id = plan == "startup" ? stripe_startup_price_id : stripe_pro_price_id

      session = Stripe::Checkout::Session.create({
        customer: customer.id,
        payment_method_types: [ "card" ],
        line_items: [ {
          price: price_id,
          quantity: 1
        } ],
        mode: "subscription",
        success_url: success_subscriptions_url(session_id: "{CHECKOUT_SESSION_ID}"),
        cancel_url: pricing_subscriptions_url,
        metadata: {
          user_id: current_user.id,
          plan: plan
        }
      })

      redirect_to session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe checkout error: #{e.message}"
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.checkout_error")
    end
  end

  # GET /subscriptions/success
  # Handle successful subscription checkout
  def success
    session_id = params[:session_id]

    begin
      session = Stripe::Checkout::Session.retrieve(session_id)
      subscription = Stripe::Subscription.retrieve(session.subscription)

      # Update user's subscription
      plan = session.metadata["plan"]
      current_user.update!(
        plan: plan,
        stripe_customer_id: session.customer,
        stripe_subscription_id: subscription.id,
        plan_expires_at: Time.at(subscription.current_period_end),
        trial_ends_at: nil
      )

      redirect_to root_path, notice: t("subscriptions.upgrade_successful", plan: plan.titleize)
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe session retrieval error: #{e.message}"
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.verification_error")
    end
  end

  # GET /subscriptions/manage
  # Redirect to Stripe customer portal for managing subscription
  def manage
    unless current_user.stripe_customer_id
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.no_subscription")
      return
    end

    begin
      portal_session = Stripe::BillingPortal::Session.create({
        customer: current_user.stripe_customer_id,
        return_url: pricing_subscriptions_url
      })

      redirect_to portal_session.url, allow_other_host: true
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe portal error: #{e.message}"
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.portal_error")
    end
  end

  # POST /subscriptions/upgrade
  # Upgrade subscription immediately with prorated billing
  def upgrade
    target_plan = params[:plan]

    unless %w[startup pro].include?(target_plan)
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.invalid_plan")
      return
    end

    unless current_user.stripe_subscription_id
      # No existing subscription, use regular checkout flow
      redirect_to create_checkout_session_subscriptions_path(plan: target_plan)
      return
    end

    begin
      subscription = Stripe::Subscription.retrieve(current_user.stripe_subscription_id)
      current_plan = determine_current_plan(subscription)

      # Validate upgrade path (can't downgrade via upgrade action)
      if !valid_upgrade?(current_plan, target_plan)
        redirect_to pricing_subscriptions_path, alert: t("subscriptions.invalid_upgrade")
        return
      end

      # Get the new price ID
      new_price_id = target_plan == "startup" ? stripe_startup_price_id : stripe_pro_price_id

      # Update the subscription with prorated billing (immediate upgrade)
      updated_subscription = Stripe::Subscription.update(
        subscription.id,
        {
          items: [
            {
              id: subscription.items.data.first.id,
              price: new_price_id
            }
          ],
          proration_behavior: "always_invoice", # Charge prorated amount immediately
          billing_cycle_anchor: "unchanged" # Keep the same billing date
        }
      )

      # Update user's plan immediately
      current_user.update!(
        plan: target_plan,
        plan_expires_at: Time.at(updated_subscription.current_period_end)
      )

      redirect_to pricing_subscriptions_path, notice: t("subscriptions.upgrade_successful", plan: target_plan.titleize)
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe upgrade error: #{e.message}"
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.upgrade_error")
    end
  end

  # POST /subscriptions/downgrade
  # Downgrade subscription at end of current billing period
  def downgrade
    target_plan = params[:plan]

    unless %w[free startup].include?(target_plan)
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.invalid_plan")
      return
    end

    unless current_user.stripe_subscription_id
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.no_subscription")
      return
    end

    begin
      subscription = Stripe::Subscription.retrieve(current_user.stripe_subscription_id)
      current_plan = determine_current_plan(subscription)

      # Validate downgrade path (can't upgrade via downgrade action)
      if !valid_downgrade?(current_plan, target_plan)
        redirect_to pricing_subscriptions_path, alert: t("subscriptions.invalid_downgrade")
        return
      end

      if target_plan == "free"
        # Cancel subscription at period end
        Stripe::Subscription.update(
          subscription.id,
          { cancel_at_period_end: true }
        )
        redirect_to pricing_subscriptions_path, notice: t("subscriptions.downgrade_scheduled_free")
      else
        # Schedule downgrade to startup at period end
        new_price_id = stripe_startup_price_id

        Stripe::Subscription.update(
          subscription.id,
          {
            items: [
              {
                id: subscription.items.data.first.id,
                price: new_price_id
              }
            ],
            proration_behavior: "none", # No proration for downgrades
            billing_cycle_anchor: "unchanged" # Apply at end of current period
          }
        )

        redirect_to pricing_subscriptions_path, notice: t("subscriptions.downgrade_scheduled", plan: target_plan.titleize)
      end
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe downgrade error: #{e.message}"
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.downgrade_error")
    end
  end

  # POST /subscriptions/cancel
  # Cancel subscription (downgrade to free)
  def cancel
    unless current_user.stripe_subscription_id
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.no_subscription")
      return
    end

    begin
      # Cancel at period end (don't cancel immediately)
      Stripe::Subscription.update(
        current_user.stripe_subscription_id,
        { cancel_at_period_end: true }
      )

      redirect_to pricing_subscriptions_path, notice: t("subscriptions.cancel_scheduled")
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe cancellation error: #{e.message}"
      redirect_to pricing_subscriptions_path, alert: t("subscriptions.cancel_error")
    end
  end

  private

  # Get or create Stripe customer for current user
  def get_or_create_stripe_customer
    if current_user.stripe_customer_id
      begin
        return Stripe::Customer.retrieve(current_user.stripe_customer_id)
      rescue Stripe::InvalidRequestError
        # Customer doesn't exist, create new one
      end
    end

    customer = Stripe::Customer.create({
      email: current_user.email,
      metadata: {
        user_id: current_user.id
      }
    })

    current_user.update!(stripe_customer_id: customer.id)
    customer
  end

  # Get Stripe price ID for Startup plan
  def stripe_startup_price_id
    Rails.configuration.stripe[:startup_price_id]
  end

  # Get Stripe price ID for Pro plan
  def stripe_pro_price_id
    Rails.configuration.stripe[:pro_price_id]
  end

  # Determine current plan from Stripe subscription
  def determine_current_plan(subscription)
    price_id = subscription.items.data.first&.price&.id

    case price_id
    when stripe_startup_price_id
      "startup"
    when stripe_pro_price_id
      "pro"
    else
      # Fallback to user's current plan
      current_user.plan
    end
  end

  # Check if upgrade is valid (moving to higher tier)
  def valid_upgrade?(current_plan, target_plan)
    plan_hierarchy = { "free" => 0, "startup" => 1, "pro" => 2 }
    plan_hierarchy[target_plan] > plan_hierarchy[current_plan]
  end

  # Check if downgrade is valid (moving to lower tier)
  def valid_downgrade?(current_plan, target_plan)
    plan_hierarchy = { "free" => 0, "startup" => 1, "pro" => 2 }
    plan_hierarchy[target_plan] < plan_hierarchy[current_plan]
  end
end
