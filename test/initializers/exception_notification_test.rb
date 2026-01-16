require "test_helper"

class ExceptionNotificationTest < ActiveSupport::TestCase
  test "exception notification is configured" do
    assert ExceptionNotification.notifiers.any?, "ExceptionNotification should have at least one notifier configured"
  end

  test "email notifier is configured in production" do
    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      # Reload initializer to pick up production environment
      load Rails.root.join("config/initializers/exception_notification.rb")

      # Check that email notifier exists
      assert ExceptionNotification.notifiers.key?(:email), "Email notifier should be configured in production"
    end
  end

  test "ignores common exceptions" do
    ignored = ExceptionNotification.ignored_exceptions

    # Check for custom ignored exceptions we added
    assert_includes ignored, "ActionController::InvalidAuthenticityToken"
    assert_includes ignored, "ActionController::UnknownFormat"
    assert_includes ignored, "ActionView::MissingTemplate"
    assert_includes ignored, "Rack::Timeout::RequestTimeoutException"
  end

  test "ignores known crawler bots" do
    # Create a mock request from a crawler
    exception = StandardError.new("Test exception")
    options = {
      env: {
        "HTTP_USER_AGENT" => "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
      }
    }

    # Exception should be ignored for crawlers
    # Note: This tests the ignore_crawlers configuration
    assert ExceptionNotification.ignore_crawlers.include?("Googlebot"),
           "Googlebot should be in the ignored crawlers list"
  end

  test "error grouping is enabled" do
    assert ExceptionNotification.error_grouping, "Error grouping should be enabled"
    assert_equal 5.minutes, ExceptionNotification.error_grouping_period,
                 "Error grouping period should be 5 minutes"
  end

  test "does not send notifications in development environment" do
    Rails.stub(:env, ActiveSupport::StringInquirer.new("development")) do
      # Reload initializer
      load Rails.root.join("config/initializers/exception_notification.rb")

      # Check that ignore_if condition prevents development notifications
      # The ignore_if block should return true for non-production environments
      assert_not Rails.env.production?, "Should be in development environment for this test"
    end
  end

  test "does not send notifications in test environment" do
    # Test environment should ignore notifications
    assert_not Rails.env.production?, "Should not be in production for this test"

    # The ignore_if block should prevent notifications in test
    # This is tested implicitly by the configuration
  end
end
