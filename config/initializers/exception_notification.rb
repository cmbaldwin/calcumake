# Exception Notification Configuration
# Provides real-time error alerts via email and other channels
# See: https://github.com/smartinez87/exception_notification

require "exception_notification/rails"
require "exception_notification/rake"

ExceptionNotification.configure do |config|
  # Ignore common exceptions that don't need immediate attention
  # Default ignored: ActiveRecord::RecordNotFound, ActionController::RoutingError,
  #                  ActionController::UnknownFormat, ActionController::InvalidAuthenticityToken
  config.ignored_exceptions += %w[
    ActionController::InvalidAuthenticityToken
    ActionController::UnknownFormat
    ActionView::MissingTemplate
    Rack::Timeout::RequestTimeoutException
  ]

  # Ignore requests from known crawlers/bots
  config.ignore_crawlers %w[
    Googlebot
    Bingbot
    AhrefsBot
    SemrushBot
    MJ12bot
    baiduspider
    YandexBot
  ]

  # Only send notifications in production environment
  config.ignore_if do |exception, options|
    !Rails.env.production?
  end

  # Error grouping to reduce notification fatigue
  # Sends notifications at: 1st, 2nd, 4th, 8th, 16th, 32nd... occurrences
  config.error_grouping = true
  config.error_grouping_period = 5.minutes

  # Notifiers ===================================================================

  # Email notifier configuration using Resend SMTP
  if Rails.env.production?
    config.add_notifier :email, {
      email_prefix: "[CalcuMake ERROR] ",
      sender_address: %("CalcuMake Errors" <noreply@calcumake.com>),
      exception_recipients: %w[dev@moab.co.jp],
      delivery_method: :smtp,
      smtp_settings: {
        address: "smtp.resend.com",
        port: 587,
        authentication: :plain,
        user_name: "resend",
        password: ENV["RESEND_API_KEY"],
        enable_starttls_auto: true
      }
    }
  end

  # Slack notifier configuration (Phase 2 - optional)
  # Uncomment when EXCEPTION_NOTIFICATION_SLACK_WEBHOOK is configured in Kamal secrets
  # if Rails.env.production? && ENV["EXCEPTION_NOTIFICATION_SLACK_WEBHOOK"].present?
  #   config.add_notifier :slack, {
  #     webhook_url: ENV["EXCEPTION_NOTIFICATION_SLACK_WEBHOOK"],
  #     channel: "#calcumake-errors",
  #     username: "CalcuMake Error Bot",
  #     additional_fields: [
  #       { title: "User", value: ->(exception, opts) { opts[:env]["exception_notifier.exception_data"][:current_user] } },
  #       { title: "Environment", value: Rails.env },
  #       { title: "Server", value: Socket.gethostname }
  #     ]
  #   }
  # end
end
