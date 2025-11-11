# Webhook controller for handling Stripe events
# This endpoint receives and processes webhooks from Stripe
module Webhooks
  class StripeController < ApplicationController
    # Skip CSRF protection for webhooks
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      event = nil

      begin
        event = Stripe::Webhook.construct_event(
          payload,
          sig_header,
          Rails.configuration.stripe[:webhook_secret]
        )
      rescue JSON::ParserError => e
        Rails.logger.error "⚠️  Webhook error: Invalid payload - #{e.message}"
        return head :bad_request
      rescue Stripe::SignatureVerificationError => e
        Rails.logger.error "⚠️  Webhook error: Invalid signature - #{e.message}"
        return head :bad_request
      end

      # Handle the event
      case event.type
      when "customer.subscription.created"
        handle_subscription_created(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      when "invoice.payment_succeeded"
        handle_payment_succeeded(event.data.object)
      when "invoice.payment_failed"
        handle_payment_failed(event.data.object)
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      else
        Rails.logger.info "Unhandled event type: #{event.type}"
      end

      head :ok
    end

    private

    # Handle subscription creation
    def handle_subscription_created(subscription)
      user = find_user_by_customer_id(subscription.customer)
      return unless user

      plan = determine_plan_from_subscription(subscription)

      user.update!(
        plan: plan,
        stripe_subscription_id: subscription.id,
        plan_expires_at: Time.at(subscription.current_period_end),
        trial_ends_at: nil
      )

      Rails.logger.info "✓ Subscription created for user #{user.id}: #{plan}"
    end

    # Handle subscription updates (plan changes, renewals)
    def handle_subscription_updated(subscription)
      user = find_user_by_customer_id(subscription.customer)
      return unless user

      # Check if subscription is being canceled
      if subscription.cancel_at_period_end
        Rails.logger.info "Subscription scheduled for cancellation for user #{user.id}"
        # We don't downgrade immediately - wait for subscription.deleted event
        return
      end

      plan = determine_plan_from_subscription(subscription)

      user.update!(
        plan: plan,
        plan_expires_at: Time.at(subscription.current_period_end)
      )

      Rails.logger.info "✓ Subscription updated for user #{user.id}: #{plan}"
    end

    # Handle subscription deletion/cancellation
    def handle_subscription_deleted(subscription)
      user = find_user_by_customer_id(subscription.customer)
      return unless user

      # Downgrade to free plan
      user.downgrade_to_free!

      Rails.logger.info "✓ Subscription canceled for user #{user.id}, downgraded to free"
    end

    # Handle successful payment
    def handle_payment_succeeded(invoice)
      user = find_user_by_customer_id(invoice.customer)
      return unless user

      Rails.logger.info "✓ Payment succeeded for user #{user.id}: #{invoice.amount_paid / 100.0} #{invoice.currency.upcase}"

      # Update subscription expiration if available
      if invoice.subscription && (subscription = Stripe::Subscription.retrieve(invoice.subscription))
        user.update!(plan_expires_at: Time.at(subscription.current_period_end))
      end
    end

    # Handle failed payment
    def handle_payment_failed(invoice)
      user = find_user_by_customer_id(invoice.customer)
      return unless user

      Rails.logger.warn "⚠️  Payment failed for user #{user.id}"

      # TODO: Send email notification to user about failed payment
      # You might want to add a grace period before downgrading
    end

    # Handle checkout session completion
    def handle_checkout_completed(session)
      user_id = session.metadata&.dig("user_id")
      return unless user_id

      user = User.find_by(id: user_id)
      return unless user

      plan = session.metadata["plan"]

      user.update!(
        stripe_customer_id: session.customer,
        stripe_subscription_id: session.subscription
      )

      Rails.logger.info "✓ Checkout completed for user #{user.id}: #{plan}"
    end

    # Find user by Stripe customer ID
    def find_user_by_customer_id(customer_id)
      user = User.find_by(stripe_customer_id: customer_id)

      unless user
        Rails.logger.error "⚠️  User not found for Stripe customer: #{customer_id}"
      end

      user
    end

    # Determine plan tier from Stripe subscription
    def determine_plan_from_subscription(subscription)
      # Get the price ID from the subscription
      price_id = subscription.items.data.first&.price&.id

      # Match price ID to plan tier
      startup_price_id = Rails.application.credentials.dig(:stripe, :startup_price_id)
      pro_price_id = Rails.application.credentials.dig(:stripe, :pro_price_id)

      case price_id
      when startup_price_id
        "startup"
      when pro_price_id
        "pro"
      else
        # Default to determining by amount
        amount = subscription.items.data.first&.price&.unit_amount

        if amount
          # $0.99 = Startup, $9.99 = Pro
          amount < 500 ? "startup" : "pro"
        else
          "free"
        end
      end
    end
  end
end
