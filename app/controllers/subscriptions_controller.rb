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
        success_url: subscription_success_url(session_id: "{CHECKOUT_SESSION_ID}"),
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
end
