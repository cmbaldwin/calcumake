# Exception Notification Implementation Plan

**Project**: CalcuMake (Rails 8.1.1)
**Created**: 2026-01-15
**Purpose**: Implement comprehensive exception tracking and alerting for production errors

---

## Executive Summary

Implement the `exception_notification` gem to provide real-time email alerts when errors occur in production. The system uses intelligent error grouping, filtering, and contextual information to keep developers informed without overwhelming them.

**Benefits**:
- Immediate awareness of production issues via email
- Reduced mean time to detection (MTTD)
- Context-rich error reports with user data, request info, and stack traces
- Intelligent error grouping to reduce notification fatigue
- Background job error tracking (SolidQueue, ActiveJob)

---

## Technical Overview

### Gem Information

- **Name**: `exception_notification`
- **Repository**: https://github.com/smartinez87/exception_notification
- **Requirements**: Ruby 3.2+, Rails 7.1+ (CalcuMake uses Ruby 3.3+ and Rails 8.1.1 ✅)
- **Status**: Mature, stable gem with 15+ years of production use

### Notification Channel

**Email** (via Resend SMTP - already configured)
- Direct email alerts to cody@moab.jp
- No additional integrations or webhooks needed
- Simple, reliable notification delivery

---

## Implementation Phases

### Phase 1: Basic Email Notifications (Quick Win)

**Goal**: Get immediate email alerts for production errors using existing Resend configuration

**Tasks**:

1. **Add gem to Gemfile**
   ```ruby
   # Error monitoring and notifications
   gem "exception_notification"
   ```

2. **Generate initializer**
   ```bash
   bundle install
   rails g exception_notification:install
   ```

3. **Configure email notifier** (`config/initializers/exception_notification.rb`)
   ```ruby
   require 'exception_notification/rails'

   ExceptionNotification.configure do |config|
     # Ignore common exceptions that don't need alerts
     config.ignore_exceptions += [
       'ActionController::RoutingError',
       'ActiveRecord::RecordNotFound',
       'ActionController::InvalidAuthenticityToken',
       'ActionController::UnknownFormat'
     ]

     # Email notifier configuration
     config.add_notifier :email, {
       email_prefix: "[CalcuMake ERROR] ",
       sender_address: %{"CalcuMake Errors" <noreply@calcumake.com>},
       exception_recipients: %w{cody@moab.jp},
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

     # Error grouping to reduce notification fatigue
     # Groups similar errors: 1st, 2nd, 4th, 8th, 16th, 32nd... occurrences
     config.error_grouping = true
     config.error_grouping_period = 5.minutes
   end
   ```

4. **Add context to notifications** (optional but recommended)
   ```ruby
   # In ApplicationController
   before_action :prepare_exception_notifier

   private

   def prepare_exception_notifier
     request.env["exception_notifier.exception_data"] = {
       current_user: current_user&.email,
       user_id: current_user&.id,
       locale: I18n.locale,
       user_agent: request.user_agent
     }
   end
   ```

5. **Test in development**
   ```ruby
   # Create test route (remove before deploying)
   # config/routes.rb
   get '/test-error' => 'application#test_error' if Rails.env.development?

   # app/controllers/application_controller.rb
   def test_error
     raise "Test error for exception notification"
   end
   ```

**Deployment**:
- No new environment variables needed (uses existing RESEND_API_KEY)
- Deploy via normal `kamal deploy` process
- Test by triggering a 500 error in production

**Testing Checklist**:
- [ ] Development: Verify email is sent to console/log
- [ ] Staging: Confirm email delivery via Resend
- [ ] Production: Monitor first 24 hours for notification volume

---

### Phase 2: Slack Integration (Not Implemented)

**Status**: Not needed - email-only notification is sufficient

**Tasks**:

1. **Create Slack webhook**
   - Go to https://api.slack.com/apps
   - Create new app or use existing workspace app
   - Enable "Incoming Webhooks"
   - Create webhook for `#engineering-alerts` or `#calcumake-errors` channel
   - Copy webhook URL (e.g., `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXX`)

2. **Add Slack webhook to Kamal secrets**
   ```bash
   # .kamal/secrets
   EXCEPTION_NOTIFICATION_SLACK_WEBHOOK=https://hooks.slack.com/services/...
   ```

3. **Update deploy.yml**
   ```yaml
   # config/deploy.yml
   env:
     secret:
       - EXCEPTION_NOTIFICATION_SLACK_WEBHOOK
   ```

4. **Update exception_notification initializer**
   ```ruby
   # config/initializers/exception_notification.rb
   ExceptionNotification.configure do |config|
     # ... existing email config ...

     # Slack notifier configuration
     if Rails.env.production? && ENV['EXCEPTION_NOTIFICATION_SLACK_WEBHOOK'].present?
       config.add_notifier :slack, {
         webhook_url: ENV['EXCEPTION_NOTIFICATION_SLACK_WEBHOOK'],
         channel: "#calcumake-errors",
         username: "CalcuMake Error Bot",
         additional_fields: [
           { title: "User", value: ->(exception, opts) { opts[:env]["exception_notifier.exception_data"][:current_user] } },
           { title: "Environment", value: Rails.env },
           { title: "Server", value: Socket.gethostname }
         ]
       }
     end
   end
   ```

5. **Test Slack integration**
   ```bash
   # In Rails console on production
   ExceptionNotification.notify_exception(
     StandardError.new("Test Slack notification"),
     env: {},
     data: { message: "Testing Slack integration" }
   )
   ```

**Benefits**:
- Real-time notifications in team chat
- Easier to spot patterns and trends
- Better visibility across team members
- Can link to error tracking dashboard

---

### Phase 3: Advanced Configuration (Optional)

**Goal**: Fine-tune notifications for specific use cases

#### 3.1 Background Job Error Handling

**SolidQueue Integration**:
```ruby
# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  # Automatically retry with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  # Notify on final failure
  discard_on ActiveJob::DeserializationError do |job, error|
    ExceptionNotification.notify_exception(
      error,
      data: {
        job: job.class.name,
        arguments: job.arguments,
        queue: job.queue_name,
        message: "Job failed after max retries"
      }
    )
  end

  rescue_from(Exception) do |exception|
    ExceptionNotification.notify_exception(
      exception,
      data: {
        job: self.class.name,
        arguments: arguments,
        queue: queue_name
      }
    )
    raise exception  # Re-raise to trigger retry logic
  end
end
```

#### 3.2 Webhook Integration for External Services

**PagerDuty, Datadog, or Custom Services**:
```ruby
# config/initializers/exception_notification.rb
if Rails.env.production? && ENV['EXCEPTION_NOTIFICATION_WEBHOOK_URL'].present?
  config.add_notifier :webhook, {
    url: ENV['EXCEPTION_NOTIFICATION_WEBHOOK_URL'],
    http_method: :post,
    body: ->(exception, opts) {
      {
        error: exception.message,
        backtrace: exception.backtrace[0..10],
        environment: Rails.env,
        user: opts[:env]["exception_notifier.exception_data"][:current_user],
        timestamp: Time.current.iso8601
      }.to_json
    },
    headers: {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['WEBHOOK_AUTH_TOKEN']}"
    }
  }
end
```

#### 3.3 Exception Filtering by Environment

**Ignore Specific Exceptions in Production**:
```ruby
# config/initializers/exception_notification.rb
ExceptionNotification.configure do |config|
  # Ignore crawler/bot errors
  config.ignore_crawlers = %w{
    Googlebot
    Bingbot
    AhrefsBot
    SemrushBot
    MJ12bot
  }

  # Ignore specific exceptions only in production
  if Rails.env.production?
    config.ignore_if do |exception, options|
      # Ignore 404s from known bad paths
      exception.is_a?(ActionController::RoutingError) &&
        options[:env]['PATH_INFO'] =~ /\.(php|asp|aspx)$/
    end
  end

  # Custom ignore logic for API rate limiting
  config.ignore_if do |exception, options|
    exception.is_a?(RateLimitExceeded)
  end
end
```

#### 3.4 User Context Enrichment

**Enhanced User Data in Notifications**:
```ruby
# app/controllers/application_controller.rb
before_action :prepare_exception_notifier

private

def prepare_exception_notifier
  return unless user_signed_in?

  request.env["exception_notifier.exception_data"] = {
    # User info
    user_email: current_user.email,
    user_id: current_user.id,
    user_created_at: current_user.created_at,
    subscription_plan: current_user.subscription_plan,

    # Session info
    locale: I18n.locale,
    session_id: session.id,

    # Request context
    referer: request.referer,
    user_agent: request.user_agent,

    # Business metrics
    print_pricings_count: current_user.print_pricings.count,
    invoices_count: current_user.invoices.count
  }
end
```

#### 3.5 API-Specific Error Handling

**Separate Notifications for API Errors**:
```ruby
# app/controllers/api/v1/base_controller.rb
rescue_from StandardError, with: :handle_api_error

private

def handle_api_error(exception)
  # Log to exception notification with API context
  ExceptionNotification.notify_exception(
    exception,
    env: request.env,
    data: {
      api_version: "v1",
      endpoint: "#{request.method} #{request.path}",
      token_hint: current_api_token&.token_hint,
      user_id: current_user&.id,
      request_payload: request.request_parameters
    }
  )

  # Return JSON error response
  render json: {
    errors: [{
      status: "500",
      code: "internal_error",
      title: "Internal Server Error",
      detail: Rails.env.production? ? "An unexpected error occurred" : exception.message
    }]
  }, status: :internal_server_error
end
```

---

## Testing Strategy

### Unit Tests

**Test error notification is configured**:
```ruby
# test/initializers/exception_notification_test.rb
require "test_helper"

class ExceptionNotificationTest < ActiveSupport::TestCase
  test "exception notification is configured" do
    assert ExceptionNotification.notifiers.any?
  end

  test "email notifier is configured in production" do
    Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
      # Reload initializer
      load Rails.root.join("config/initializers/exception_notification.rb")
      assert ExceptionNotification.notifiers.key?(:email)
    end
  end

  test "ignores common exceptions" do
    ignored = ExceptionNotification.ignored_exceptions
    assert_includes ignored, 'ActionController::RoutingError'
    assert_includes ignored, 'ActiveRecord::RecordNotFound'
  end
end
```

### Integration Tests

**Test exception context is set**:
```ruby
# test/controllers/application_controller_test.rb
class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test "sets exception notifier context for authenticated users" do
    sign_in users(:one)
    get dashboard_path

    exception_data = @request.env["exception_notifier.exception_data"]
    assert_not_nil exception_data
    assert_equal users(:one).email, exception_data[:current_user]
  end
end
```

### Manual Testing

**Production Verification Checklist**:

1. **Trigger a test error**
   ```ruby
   # In Rails console on production
   raise "Test exception notification - please ignore"
   ```

2. **Verify notifications received**
   - [ ] Email received at cody@moab.jp
   - [ ] Slack message in #calcumake-errors (if configured)
   - [ ] Notification includes user context
   - [ ] Stack trace is complete and readable

3. **Test error grouping**
   - Trigger same error multiple times
   - Verify notifications sent at: 1st, 2nd, 4th, 8th occurrence
   - Confirm notification includes occurrence count

4. **Test background job errors**
   ```ruby
   # In Rails console
   TestErrorJob.perform_later
   ```

5. **Test API errors**
   ```bash
   curl -X POST https://calcumake.com/api/v1/test-error \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

---

## Deployment Checklist

### Pre-Deployment

- [ ] Add gem to Gemfile
- [ ] Run `bundle install` locally
- [ ] Generate and configure initializer
- [ ] Add custom context to ApplicationController
- [ ] Write unit tests for configuration
- [ ] Test in development environment
- [ ] Update `.env.local.example` with notification variables
- [ ] Document notification channels in CLAUDE.md

### Deployment (Phase 1 - Email Only)

- [ ] Commit changes to feature branch
- [ ] Run `bin/ci` to verify all tests pass
- [ ] Push to GitHub
- [ ] Create PR with this plan as reference
- [ ] Merge to main branch
- [ ] Deploy via `kamal deploy`
- [ ] Verify deployment health
- [ ] Trigger test error in production
- [ ] Confirm email notification received

### Post-Deployment (Phase 2 - Slack)

- [ ] Create Slack webhook
- [ ] Add webhook to `.kamal/secrets`
- [ ] Update `config/deploy.yml` with new env var
- [ ] Update exception_notification initializer
- [ ] Test locally with dotenv
- [ ] Deploy via `kamal deploy`
- [ ] Trigger test error
- [ ] Confirm Slack notification received
- [ ] Monitor for 24-48 hours
- [ ] Adjust filters if notification volume is too high

---

## Monitoring and Maintenance

### Week 1: High Alert

- Check notifications daily
- Tune ignore filters if needed
- Verify error grouping works correctly
- Ensure no notification fatigue

### Month 1: Optimization

- Review notification volume
- Identify noisy exceptions to ignore
- Add business-specific context
- Consider webhook integration for dashboards

### Ongoing

- Review exception patterns monthly
- Update ignore filters as needed
- Ensure team members are receiving alerts
- Document common exceptions and resolutions

---

## Configuration Reference

### Environment Variables

| Variable | Purpose | Required | Example |
|----------|---------|----------|---------|
| `RESEND_API_KEY` | Email delivery | Yes (existing) | `re_123...` |
| `EXCEPTION_NOTIFICATION_SLACK_WEBHOOK` | Slack alerts | Optional | `https://hooks.slack.com/...` |
| `EXCEPTION_NOTIFICATION_WEBHOOK_URL` | Custom webhooks | Optional | `https://api.service.com/errors` |
| `WEBHOOK_AUTH_TOKEN` | Webhook authentication | Optional | `Bearer token...` |

### Notification Channels Priority

1. **Slack** (Phase 2) - Real-time team awareness
2. **Email** (Phase 1) - Persistent record, async review
3. **Webhook** (Phase 3) - Integration with monitoring tools

### Recommended Ignore List

```ruby
# Common exceptions that don't need immediate attention
config.ignore_exceptions += [
  'ActionController::RoutingError',        # 404s
  'ActiveRecord::RecordNotFound',          # Expected DB misses
  'ActionController::InvalidAuthenticityToken', # CSRF (often bots)
  'ActionController::UnknownFormat',       # Format negotiation
  'ActionView::MissingTemplate',           # Template issues (dev)
  'Rack::Timeout::RequestTimeoutException' # Timeout monitoring separate
]
```

---

## Rollback Plan

If exception_notification causes issues:

1. **Immediate**: Comment out middleware in `config/initializers/exception_notification.rb`
   ```ruby
   # ExceptionNotification.configure do |config|
   #   ...
   # end
   ```

2. **Quick**: Remove gem from Gemfile and redeploy
   ```bash
   # Remove from Gemfile
   bundle install
   kamal deploy
   ```

3. **Clean**: Remove all configuration
   ```bash
   git revert <commit-hash>
   kamal deploy
   ```

**No data loss risk** - This is monitoring-only, doesn't affect data or user experience.

---

## Cost Analysis

### Email (Resend)

- **Current plan**: Already configured for transactional email
- **Estimated volume**: 10-50 error emails/day in production
- **Cost impact**: Negligible (within existing email quota)

### Slack

- **Cost**: Free (using incoming webhooks)
- **Volume**: Same as email (10-50 notifications/day)
- **Rate limits**: No practical limit for this volume

### Development Time

- **Phase 1 (Email)**: 2-3 hours
  - Gem installation: 30 min
  - Configuration: 1 hour
  - Testing: 1 hour
  - Deployment: 30 min

- **Phase 2 (Slack)**: 1-2 hours
  - Slack setup: 30 min
  - Configuration: 30 min
  - Testing: 30 min

- **Phase 3 (Advanced)**: 3-5 hours
  - Custom filtering: 1-2 hours
  - Background job integration: 1 hour
  - API-specific handling: 1-2 hours

**Total**: 6-10 hours for complete implementation

---

## Success Metrics

### Immediate (Week 1)

- [ ] All production errors are captured and notified
- [ ] Notifications contain sufficient context to debug
- [ ] No notification fatigue (not too many alerts)
- [ ] Team responds to at least one alert successfully

### Short-term (Month 1)

- [ ] Mean time to detection (MTTD) reduced by 80%
- [ ] All critical errors are resolved within 24 hours
- [ ] Error notification volume is stable and manageable
- [ ] Team has confidence in error monitoring system

### Long-term (Quarter 1)

- [ ] Zero unknown production errors
- [ ] Proactive issue resolution before user reports
- [ ] Error rate trending downward
- [ ] Exception notification integrated into on-call workflow

---

## Related Documentation

- **Exception Notification Gem**: https://github.com/smartinez87/exception_notification
- **Resend SMTP Setup**: `docs/OAUTH_SETUP_GUIDE.md` (email delivery already configured)
- **Kamal Deployment**: `config/deploy.yml`
- **Testing Guide**: `docs/TESTING_GUIDE.md`

---

## Questions for Product Team

Before implementing, consider:

1. **Notification Recipients**: Who should receive error alerts?
   - Suggested: `cody@moab.jp` for now, expand later

2. **Slack Channel**: Create `#calcumake-errors` or use existing `#engineering`?
   - Recommended: Dedicated channel to avoid noise

3. **Severity Levels**: Should we implement tiered alerting (critical vs. warning)?
   - Phase 1: All errors equal priority
   - Phase 3: Can add severity-based routing

4. **Business Hours**: Should we suppress non-critical alerts outside business hours?
   - Phase 1: 24/7 notifications
   - Phase 3: Can add time-based filtering

5. **External Monitoring**: Do we want PagerDuty, Datadog, or similar integration?
   - Phase 3: Can add webhook integration

---

## Conclusion

Exception notification is a high-value, low-risk improvement that will significantly improve CalcuMake's production reliability and team responsiveness. The phased approach allows for quick wins (Phase 1) while leaving room for advanced features (Phase 2-3) based on team needs.

**Recommendation**: Start with Phase 1 (email notifications) immediately, add Phase 2 (Slack) within the same week, and evaluate Phase 3 (advanced features) after 1 month of production use.

**Next Steps**:
1. Review this plan with team
2. Create Slack channel for errors
3. Begin Phase 1 implementation
4. Schedule deployment for low-traffic period
