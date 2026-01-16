# AI-Powered Price Estimate Chat - Implementation Plan

**Created**: 2026-01-16
**Status**: Planning Phase
**Target**: Logged-in users only
**Goal**: Conversational AI assistant that gathers pricing requirements and generates accurate price estimates

---

## Executive Summary

This feature adds an AI-powered chat interface for logged-in CalcuMake users to obtain 3D print price estimates through natural conversation. The AI assistant asks contextual questions, interprets user responses, automatically populates database records, and generates professional price estimates using the existing API infrastructure.

**Key Benefits**:
- Reduces friction in pricing workflow (no manual form filling)
- Guides inexperienced users through complex pricing requirements
- Learns from user's existing printer/material profiles
- Generates accurate estimates using proven calculation engine
- Creates permanent records in database for future reference
- Multilingual support (7 languages already supported)

---

## Technical Architecture

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                    User Browser                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Chat Interface (Stimulus Controller)              │ │
│  │  - Message display                                 │ │
│  │  - Real-time typing indicators                     │ │
│  │  - Quick action buttons                            │ │
│  └────────────────────────────────────────────────────┘ │
│                         ↕ WebSocket (ActionCable)        │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│              Rails Backend (CalcuMake)                   │
│  ┌────────────────────────────────────────────────────┐ │
│  │  ChatSessionsController                            │ │
│  │  - Create/read/update sessions                     │ │
│  │  - Stream messages via Turbo                       │ │
│  └────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────┐ │
│  │  AiAssistantService                                │ │
│  │  - Conversation management                         │ │
│  │  - Context building from user profile              │ │
│  │  - Structured data extraction                      │ │
│  └────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────┐ │
│  │  PrintPricingBuilderService                        │ │
│  │  - Parse AI-extracted data                         │ │
│  │  - Build nested PrintPricing records               │ │
│  │  - Validate and save to database                   │ │
│  └────────────────────────────────────────────────────┘ │
│                         ↕                                │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Existing API (v1)                                 │ │
│  │  - POST /api/v1/print_pricings                     │ │
│  │  - Calculation engine                              │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│              AI Service Provider                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │  OpenRouter API (Recommended)                      │ │
│  │  Model: GPT-4 Turbo or Claude 3.5 Sonnet          │ │
│  │  - Conversation processing                         │ │
│  │  - Structured output (JSON)                        │ │
│  │  - Multi-language support                          │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│              Database (PostgreSQL)                       │
│  - chat_sessions (conversations)                         │
│  - chat_messages (message history)                       │
│  - print_pricings (generated estimates)                  │
│  - plates, plate_filaments, etc. (nested data)          │
└─────────────────────────────────────────────────────────┘
```

---

## AI Service Selection

### Recommendation: OpenRouter API

**Why OpenRouter**:
1. ✅ **Already integrated**: CalcuMake uses OpenRouter for translation system
2. ✅ **Cost-effective**: Access to multiple models at competitive pricing
3. ✅ **Flexibility**: Can switch models without code changes
4. ✅ **Multi-language**: Supports all 7 CalcuMake languages natively
5. ✅ **Structured output**: JSON mode for reliable data extraction
6. ✅ **Existing gem**: Uses `open_router` Ruby gem already in Gemfile

**Model Selection** (in priority order):

| Model | Use Case | Cost (per 1M tokens) | Speed | Accuracy |
|-------|----------|---------------------|-------|----------|
| **GPT-4 Turbo** | Primary (complex pricing) | Input: $10, Output: $30 | Fast | Excellent |
| **Claude 3.5 Sonnet** | Fallback/A-B testing | Input: $3, Output: $15 | Fast | Excellent |
| **GPT-3.5 Turbo** | Simple queries | Input: $0.50, Output: $1.50 | Fastest | Good |
| **Gemini 2.0 Flash** | Budget option | Input: $0.075, Output: $0.30 | Very Fast | Good |

**Cost Estimation** (average conversation):
- 10 message exchanges = ~3,000 tokens input + ~1,000 tokens output
- GPT-4 Turbo: $0.03 input + $0.03 output = **$0.06 per estimate**
- Gemini 2.0 Flash: $0.0002 input + $0.0003 output = **$0.0005 per estimate**

**Budget Control**:
- Set per-user monthly limits (e.g., 50 estimates for Free tier, unlimited for Pro)
- Cache common questions/responses
- Use cheaper models for simple queries (classification layer)
- Track usage in database for billing/analytics

### Alternative: Direct OpenAI API

If OpenRouter has limitations, use direct OpenAI API:
- More control over parameters
- Better error handling
- Official Ruby gem: `ruby-openai`
- Slightly more expensive but more stable

---

## Database Schema Changes

### New Tables

**chat_sessions** (conversation context)
```ruby
create_table :chat_sessions do |t|
  t.references :user, null: false, foreign_key: true
  t.string :title, null: false  # Auto-generated from first message
  t.string :status, null: false, default: "active"  # active, completed, abandoned
  t.string :locale, null: false, default: "en"  # User's language
  t.references :print_pricing, foreign_key: true  # Generated estimate (nullable)
  t.jsonb :context, default: {}  # Extracted data during conversation
  t.jsonb :metadata, default: {}  # User defaults, printer profiles, etc.
  t.integer :message_count, default: 0
  t.datetime :completed_at
  t.timestamps
end

add_index :chat_sessions, [:user_id, :created_at]
add_index :chat_sessions, :status
```

**chat_messages** (conversation history)
```ruby
create_table :chat_messages do |t|
  t.references :chat_session, null: false, foreign_key: true
  t.string :role, null: false  # user, assistant, system
  t.text :content, null: false
  t.jsonb :metadata, default: {}  # Tool calls, confidence scores, etc.
  t.integer :tokens_used  # For cost tracking
  t.timestamps
end

add_index :chat_messages, [:chat_session_id, :created_at]
add_index :chat_messages, :role
```

**ai_usage_logs** (cost tracking & analytics)
```ruby
create_table :ai_usage_logs do |t|
  t.references :user, null: false, foreign_key: true
  t.references :chat_session, foreign_key: true
  t.string :model_used, null: false  # gpt-4-turbo, claude-3.5-sonnet
  t.integer :input_tokens, null: false
  t.integer :output_tokens, null: false
  t.decimal :cost, precision: 10, scale: 6  # In USD
  t.string :operation_type  # conversation, extraction, validation
  t.jsonb :metadata, default: {}
  t.timestamps
end

add_index :ai_usage_logs, [:user_id, :created_at]
add_index :ai_usage_logs, :chat_session_id
```

### Model Associations

```ruby
# app/models/user.rb
has_many :chat_sessions, dependent: :destroy
has_many :ai_usage_logs, dependent: :destroy

def ai_estimates_this_month
  chat_sessions.where("created_at >= ?", Time.current.beginning_of_month)
    .where(status: "completed").count
end

def ai_budget_remaining?
  # Free: 10/month, Startup: 50/month, Pro: unlimited
  limit = subscription_plan_limits[:ai_estimates] || 10
  limit == Float::INFINITY || ai_estimates_this_month < limit
end

# app/models/chat_session.rb
belongs_to :user
belongs_to :print_pricing, optional: true
has_many :chat_messages, dependent: :destroy
has_many :ai_usage_logs, dependent: :destroy

validates :status, inclusion: { in: %w[active completed abandoned] }
validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }

def mark_completed!(pricing)
  update!(
    status: "completed",
    print_pricing: pricing,
    completed_at: Time.current
  )
end

# app/models/chat_message.rb
belongs_to :chat_session
validates :role, inclusion: { in: %w[user assistant system] }
validates :content, presence: true

# app/models/ai_usage_log.rb
belongs_to :user
belongs_to :chat_session, optional: true
validates :model_used, :input_tokens, :output_tokens, presence: true

def self.total_cost_this_month
  where("created_at >= ?", Time.current.beginning_of_month).sum(:cost)
end
```

---

## Conversation Flow Design

### AI System Prompt Template

```markdown
You are a helpful pricing assistant for CalcuMake, a 3D printing cost estimation platform.

Your role is to help users create accurate price estimates for 3D print jobs through natural conversation.

USER PROFILE:
- Name: {{user.name}}
- Currency: {{user.default_currency}}
- Energy cost: {{user.default_energy_cost_per_kwh}} {{currency}}/kWh
- Default markup: {{user.default_filament_markup_percentage}}%
- Available printers: {{user.printers.pluck(:name).join(", ")}}
- Available filaments: {{user.filaments.pluck(:name, :material_type)}}

CONVERSATION GUIDELINES:
1. Greet the user warmly and ask what they want to estimate
2. Gather required information through natural questions:
   - Job name/description
   - Which printer to use (from their list)
   - Number of build plates (1-10)
   - For each plate:
     * Print time (hours and minutes)
     * Technology: FDM or Resin
     * Materials used (filament weight in grams OR resin volume in ml)
   - Labor requirements (prep time, post-processing time)
   - Number of units to produce
   - Any special requirements (failure rate, platform fees, etc.)

3. Make intelligent suggestions based on user profile:
   - Default to their most-used printer if not specified
   - Suggest typical filament amounts based on print time
   - Apply their default markup percentages
   - Use their energy cost and labor rates

4. Confirm extracted information before generating estimate
5. Use structured output format when ready to generate:

{
  "ready_to_generate": true,
  "job_name": "string",
  "printer_id": integer,
  "units": integer,
  "plates": [
    {
      "printing_time_hours": integer,
      "printing_time_minutes": integer,
      "material_technology": "fdm" | "resin",
      "filaments": [
        {"filament_id": integer, "weight_grams": decimal, "markup_percentage": decimal}
      ],
      "resins": [
        {"resin_id": integer, "volume_ml": decimal, "markup_percentage": decimal}
      ]
    }
  ],
  "labor": {
    "prep_time_minutes": integer,
    "prep_cost_per_hour": decimal,
    "postprocessing_time_minutes": integer,
    "postprocessing_cost_per_hour": decimal
  },
  "costs": {
    "other_costs": decimal,
    "vat_percentage": decimal,
    "failure_rate_percentage": decimal,
    "listing_cost_percentage": decimal,
    "payment_processing_cost_percentage": decimal
  }
}

CONVERSATION STYLE:
- Friendly but professional
- Ask one question at a time (don't overwhelm)
- Provide helpful context (e.g., "Most PLA prints use 50-200g per plate")
- Confirm understanding with summaries
- Respond in the user's language: {{locale}}

IMPORTANT:
- Never make up printer or material IDs - only use those in the user profile
- If user mentions a printer/material not in their library, suggest they add it first
- Always validate print times are realistic (warn if > 72 hours)
- Default to user's profile settings when not specified
```

### Conversation Example (English)

**User**: "I need a price estimate for a custom phone case"

**AI**: "Great! I'd be happy to help you estimate the cost for a custom phone case. Let me gather some details.

Which printer would you like to use? I see you have:
- Prusa i3 MK3S+
- Bambu Lab X1 Carbon
- Creality Ender 3 V2"

**User**: "Use the Bambu Lab"

**AI**: "Perfect! The Bambu Lab X1 Carbon is a great choice for detailed prints.

How long does it take to print one phone case? (Please provide hours and minutes)"

**User**: "About 4 hours"

**AI**: "Got it - 4 hours print time.

How many grams of filament does it use? (Typical phone cases use 15-40g depending on design)"

**User**: "Around 25 grams of black PLA"

**AI**: "Excellent! I see you have Black PLA in your filament library.

Are you printing just one case, or multiple cases in a single batch?"

**User**: "Just one for now"

**AI**: "Understood. A few more quick questions:

1. Do you need any prep time before printing? (e.g., bed leveling, file preparation)
2. Will this need any post-processing? (e.g., support removal, sanding, painting)"

**User**: "Maybe 10 minutes prep, and 15 minutes to clean up supports"

**AI**: "Perfect! Let me confirm what I've gathered:

📋 **Job Summary**:
- **Job**: Custom Phone Case
- **Printer**: Bambu Lab X1 Carbon
- **Print Time**: 4 hours
- **Material**: 25g Black PLA
- **Prep Work**: 10 minutes
- **Post-Processing**: 15 minutes
- **Quantity**: 1 unit

**Estimated Costs**:
- Material: ¥62.50 (25g × ¥2.50/g)
- Electricity: ¥14.40 (4h × 0.3kW × ¥12/kWh)
- Labor: ¥312.50 (25min × ¥750/hr)
- Machine Upkeep: ¥180.00
- **Subtotal**: ¥569.40
- **VAT (20%)**: ¥113.88
- **Total**: ¥683.28

Does this look correct? Would you like me to save this estimate to your account?"

**User**: "Yes, save it"

**AI**: "✅ **Estimate saved!**

I've created a pricing record in your account titled "Custom Phone Case". You can:
- View it in your dashboard at `/print_pricings`
- Edit details if needed
- Create an invoice from it
- Use it as a template for similar jobs

Is there anything else you'd like to estimate?"

---

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)

**Goal**: Database schema, basic chat UI, AI service integration

**Tasks**:
1. Create database migrations for `chat_sessions`, `chat_messages`, `ai_usage_logs`
2. Build models with validations and associations
3. Integrate OpenRouter API via existing `open_router` gem
4. Create `AiAssistantService` for conversation management
5. Build basic chat UI with Stimulus controller
6. Implement Turbo Streams for real-time message updates
7. Add route `/ai-estimates` for logged-in users
8. Write unit tests for models and service classes

**Deliverables**:
- ✅ Database schema with migrations
- ✅ Working AI conversation (no data extraction yet)
- ✅ Chat UI with message history
- ✅ Cost tracking in database

### Phase 2: Data Extraction & Validation (Week 3-4)

**Goal**: Parse conversations into structured PrintPricing data

**Tasks**:
1. Design JSON schema for structured output
2. Implement `PrintPricingBuilderService` to parse AI output
3. Add validation and error handling
4. Build confirmation flow (show extracted data before saving)
5. Integrate with existing API (`POST /api/v1/print_pricings`)
6. Handle edge cases (missing printers, invalid materials, etc.)
7. Add retry logic for API failures
8. Write integration tests

**Deliverables**:
- ✅ Reliable data extraction from conversations
- ✅ Validation with user-friendly error messages
- ✅ Confirmation UI before saving estimates
- ✅ Integration with existing calculation engine

### Phase 3: User Experience & Optimization (Week 5-6)

**Goal**: Polish UX, add advanced features, optimize costs

**Tasks**:
1. Implement quick action buttons ("Use default printer", "Skip labor costs")
2. Add typing indicators and loading states
3. Build conversation history sidebar (show past chats)
4. Implement "Edit estimate" flow (modify saved records)
5. Add AI usage dashboard (costs, estimates this month, limits)
6. Optimize AI prompts to reduce token usage
7. Implement caching for common questions
8. Add model fallback logic (GPT-4 → GPT-3.5 if over budget)
9. Mobile responsive design
10. Write system tests (full conversation flows)

**Deliverables**:
- ✅ Polished chat interface
- ✅ Usage tracking dashboard
- ✅ Cost optimization strategies
- ✅ Mobile-friendly UI

### Phase 4: Multilingual & Advanced Features (Week 7-8)

**Goal**: Support all 7 languages, add advanced pricing scenarios

**Tasks**:
1. Translate chat UI to all 7 languages (ja, es, fr, ar, hi, zh-CN)
2. Configure AI to respond in user's locale
3. Add support for multi-plate conversations
4. Implement "Modify plate" conversational flow
5. Add support for complex pricing (failure rates, platform fees)
6. Build "Similar jobs" suggestion system
7. Implement export to PDF/CSV from chat
8. Add analytics tracking (conversation completion rate, avg messages, etc.)
9. Write documentation for users
10. Comprehensive testing across all languages

**Deliverables**:
- ✅ Full multilingual support
- ✅ Advanced pricing scenarios
- ✅ Analytics dashboard
- ✅ User documentation

### Phase 5: Production Deployment & Monitoring (Week 9-10)

**Goal**: Launch feature, monitor costs, gather feedback

**Tasks**:
1. Set up production environment variables
2. Configure OpenRouter API keys in Kamal secrets
3. Add feature flag for gradual rollout
4. Implement rate limiting per user tier
5. Set up cost alerts (Slack/email if spending > threshold)
6. Add admin dashboard for monitoring AI usage
7. Create usage reports for analytics
8. Gather user feedback via in-app surveys
9. Monitor error rates and AI accuracy
10. Optimize based on real-world usage patterns

**Deliverables**:
- ✅ Production-ready feature
- ✅ Cost monitoring system
- ✅ Admin analytics dashboard
- ✅ User feedback mechanism

---

## Security Considerations

### Authentication & Authorization

1. **Logged-in only**: Chat feature requires active user session
2. **Rate limiting**: Max 10 messages per minute per user
3. **Budget enforcement**: Check `user.ai_budget_remaining?` before each request
4. **Session validation**: Ensure user owns the chat session
5. **Token security**: Store OpenRouter API key in Rails credentials (encrypted)

### Data Privacy

1. **No PII in AI prompts**: Never send email, password, or payment info to AI
2. **Conversation encryption**: Store chat messages with `attr_encrypted` gem
3. **GDPR compliance**: Include chat history in user data export
4. **Data retention**: Auto-delete chat sessions > 90 days old
5. **Audit logging**: Track all AI API calls for compliance

### Input Validation

1. **Sanitize user messages**: Strip HTML, limit length to 1000 chars
2. **Validate AI output**: JSON schema validation before database insertion
3. **SQL injection protection**: Use parameterized queries (ActiveRecord default)
4. **XSS prevention**: Escape chat messages in views
5. **Content filtering**: Detect and block malicious prompts (prompt injection attacks)

### Cost Protection

1. **Per-user limits**: 10 estimates/month (Free), 50 (Startup), unlimited (Pro)
2. **Global spend cap**: Alert if daily spend > $100
3. **Timeout protection**: Abort AI requests > 30 seconds
4. **Token limits**: Max 4000 tokens per request (prevent runaway costs)
5. **Fallback models**: Use cheaper models when possible

### Monitoring & Alerts

1. **Error tracking**: Sentry integration for AI failures
2. **Cost alerts**: Daily email if spend > $50
3. **Abuse detection**: Flag users with >100 messages/day
4. **Model performance**: Track response times and accuracy
5. **Usage analytics**: Dashboard for admin monitoring

---

## Testing Strategy

### Unit Tests (Minitest)

**Models**:
```ruby
# test/models/chat_session_test.rb
test "validates status is in allowed values"
test "marks completed with print pricing"
test "calculates message count correctly"
test "soft deletes with dependent messages"

# test/models/chat_message_test.rb
test "validates role is user, assistant, or system"
test "sanitizes content before save"
test "tracks token usage"

# test/models/ai_usage_log_test.rb
test "calculates cost from tokens and model"
test "monthly cost aggregation"
test "groups by user for analytics"
```

**Services**:
```ruby
# test/services/ai_assistant_service_test.rb
test "builds context from user profile"
test "sends conversation to OpenRouter API"
test "parses structured JSON response"
test "handles API errors gracefully"
test "retries on timeout"

# test/services/print_pricing_builder_service_test.rb
test "parses AI JSON into PrintPricing attributes"
test "builds nested plates and filaments"
test "validates required fields present"
test "applies user defaults when missing"
test "handles invalid printer/filament IDs"
```

### Integration Tests

```ruby
# test/controllers/chat_sessions_controller_test.rb
test "creates new session for logged-in user"
test "sends message and receives AI response"
test "generates estimate and saves to database"
test "enforces budget limits"
test "blocks non-logged-in users"

# test/integration/ai_conversation_flow_test.rb
test "complete conversation from greeting to estimate"
test "handles multi-plate scenario"
test "corrects extracted data when user revises"
test "handles API timeout and retries"
```

### System Tests (Capybara)

```ruby
# test/system/ai_estimates_test.rb
test "user starts chat and gets estimate" do
  sign_in users(:pro_user)
  visit ai_estimates_path

  fill_in I18n.t('ai_chat.message_placeholder'), with: "I need a price for a phone case"
  click_button I18n.t('ai_chat.send')

  assert_text I18n.t('ai_chat.greeting')
  # ... continue conversation flow

  assert_selector ".estimate-summary"
  click_button I18n.t('ai_chat.save_estimate')

  assert_current_path print_pricings_path
  assert_text "Phone Case"
end
```

### AI Response Testing (WebMock)

Mock OpenRouter API responses for consistent testing:

```ruby
# test/support/ai_mocks.rb
module AiMocks
  def stub_ai_greeting
    stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
      .to_return(
        status: 200,
        body: {
          choices: [{
            message: {
              role: "assistant",
              content: "Hi! I'd be happy to help you estimate your 3D print job..."
            }
          }]
        }.to_json
      )
  end

  def stub_ai_structured_output(print_pricing_json)
    stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
      .to_return(
        status: 200,
        body: {
          choices: [{
            message: {
              role: "assistant",
              content: print_pricing_json.to_json
            }
          }]
        }.to_json
      )
  end
end
```

### Performance Testing

1. **Load test**: 100 concurrent users, measure response times
2. **Cost test**: Run 1000 estimate conversations, track total API cost
3. **Token optimization**: Measure avg tokens per conversation, optimize prompt
4. **Cache hit rate**: Track how often cached responses are used

---

## User Experience Design

### Chat Interface Components

**Location**: `/ai-estimates` (new page)

**Layout**:
```
┌─────────────────────────────────────────────────────────────┐
│ CalcuMake Header (standard nav)                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐  ┌───────────────────────────────┐   │
│  │  Conversations   │  │   Chat Area                   │   │
│  │  ──────────────  │  │                               │   │
│  │                  │  │  AI: Hi! What would you...    │   │
│  │  📝 Phone Case   │  │  ────────────────────────     │   │
│  │     Jan 15       │  │                               │   │
│  │                  │  │  You: I need a price for...   │   │
│  │  📝 Miniature    │  │  ────────────────────────     │   │
│  │     Jan 14       │  │                               │   │
│  │                  │  │  AI: Great! Which printer...  │   │
│  │  + New Chat      │  │  ────────────────────────     │   │
│  │                  │  │                               │   │
│  └──────────────────┘  │  [Type your message...]  [➤]  │   │
│                         └───────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Features**:
1. **Sidebar**: Conversation history (collapsible on mobile)
2. **Chat area**: Message thread with auto-scroll
3. **Input**: Text area with auto-resize, send button
4. **Quick actions**: Buttons for common responses ("Yes", "No", "Use default")
5. **Typing indicator**: "AI is typing..." animation
6. **Estimate preview**: Inline summary card when ready
7. **Error handling**: Friendly messages for API failures
8. **Mobile responsive**: Full-screen on mobile, sidebar becomes dropdown

### Message Components

**User Message**:
```html
<div class="message message-user">
  <div class="message-avatar">
    <img src="{{user.avatar}}" alt="{{user.name}}" />
  </div>
  <div class="message-content">
    <div class="message-text">I need a price estimate for a phone case</div>
    <div class="message-time">2:34 PM</div>
  </div>
</div>
```

**AI Message**:
```html
<div class="message message-assistant">
  <div class="message-avatar">
    <i class="bi bi-robot"></i>
  </div>
  <div class="message-content">
    <div class="message-text">
      Great! I'd be happy to help you estimate the cost for a phone case.

      Which printer would you like to use?
      <div class="quick-actions">
        <button class="btn btn-sm btn-outline-primary">Bambu Lab X1</button>
        <button class="btn btn-sm btn-outline-primary">Prusa MK3S+</button>
        <button class="btn btn-sm btn-outline-secondary">Other</button>
      </div>
    </div>
    <div class="message-time">2:34 PM</div>
  </div>
</div>
```

**Estimate Summary Card**:
```html
<div class="estimate-summary-card">
  <h5>📋 Estimate Summary</h5>
  <dl>
    <dt>Job:</dt><dd>Custom Phone Case</dd>
    <dt>Printer:</dt><dd>Bambu Lab X1 Carbon</dd>
    <dt>Material:</dt><dd>25g Black PLA</dd>
    <dt>Print Time:</dt><dd>4 hours</dd>
  </dl>
  <hr>
  <dl class="cost-breakdown">
    <dt>Material:</dt><dd>¥62.50</dd>
    <dt>Electricity:</dt><dd>¥14.40</dd>
    <dt>Labor:</dt><dd>¥312.50</dd>
    <dt>Machine:</dt><dd>¥180.00</dd>
  </dl>
  <hr>
  <dl class="total">
    <dt><strong>Total (incl. VAT):</strong></dt>
    <dd><strong>¥683.28</strong></dd>
  </dl>
  <div class="actions">
    <button class="btn btn-primary">Save Estimate</button>
    <button class="btn btn-outline-secondary">Edit Details</button>
  </div>
</div>
```

### Stimulus Controllers

**chat_controller.js**:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "send"]
  static values = { sessionId: Number }

  connect() {
    this.scrollToBottom()
  }

  async sendMessage(event) {
    event.preventDefault()
    const content = this.inputTarget.value.trim()
    if (!content) return

    // Append user message immediately
    this.appendMessage("user", content)
    this.inputTarget.value = ""

    // Show typing indicator
    this.showTypingIndicator()

    // Send to server
    const response = await fetch(`/chat_sessions/${this.sessionIdValue}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ content })
    })

    this.hideTypingIndicator()

    if (response.ok) {
      // Turbo Stream will append AI response
    } else {
      this.showError("Failed to send message. Please try again.")
    }
  }

  appendMessage(role, content) {
    const template = this.messageTemplate(role, content)
    this.messagesTarget.insertAdjacentHTML("beforeend", template)
    this.scrollToBottom()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  showTypingIndicator() {
    this.messagesTarget.insertAdjacentHTML("beforeend", `
      <div class="typing-indicator" data-chat-target="typing">
        <span></span><span></span><span></span>
      </div>
    `)
    this.scrollToBottom()
  }

  hideTypingIndicator() {
    this.typingTarget?.remove()
  }
}
```

### Navigation Integration

Add to main navigation (when logged in):

```erb
<li class="nav-item">
  <%= link_to ai_estimates_path, class: "nav-link" do %>
    <i class="bi bi-chat-dots"></i>
    <%= t('nav.ai_estimates') %>
    <% if current_user.ai_estimates_this_month > 0 %>
      <span class="badge bg-primary"><%= current_user.ai_estimates_this_month %></span>
    <% end %>
  <% end %>
</li>
```

---

## Integration Points

### Existing API Usage

The AI chat feature leverages the existing RESTful API:

**Create Estimate** (after conversation completes):
```ruby
# In PrintPricingBuilderService
def create_pricing(user, extracted_data)
  # Use internal API for consistency
  api_params = transform_to_api_format(extracted_data)

  # Create via API controller (ensures same validation)
  pricing = user.print_pricings.build(api_params)

  if pricing.save
    { success: true, pricing: pricing }
  else
    { success: false, errors: pricing.errors.full_messages }
  end
end

private

def transform_to_api_format(data)
  {
    job_name: data[:job_name],
    printer_id: data[:printer_id],
    units: data[:units],
    prep_time_minutes: data.dig(:labor, :prep_time_minutes),
    prep_cost_per_hour: data.dig(:labor, :prep_cost_per_hour),
    # ... other top-level attributes
    plates_attributes: data[:plates].map do |plate|
      {
        printing_time_hours: plate[:printing_time_hours],
        printing_time_minutes: plate[:printing_time_minutes],
        material_technology: plate[:material_technology],
        plate_filaments_attributes: plate[:filaments].map do |f|
          {
            filament_id: f[:filament_id],
            filament_weight: f[:weight_grams],
            markup_percentage: f[:markup_percentage]
          }
        end,
        plate_resins_attributes: plate[:resins].map do |r|
          {
            resin_id: r[:resin_id],
            resin_volume_ml: r[:volume_ml],
            markup_percentage: r[:markup_percentage]
          }
        end
      }
    end
  }
end
```

### User Profile Context

AI system prompt includes user's context:

```ruby
# In AiAssistantService
def build_system_prompt(user)
  {
    user_profile: {
      name: user.name,
      currency: user.default_currency,
      energy_cost: user.default_energy_cost_per_kwh,
      default_markup: user.default_filament_markup_percentage,
      printers: user.printers.map { |p| { id: p.id, name: p.name, type: p.technology } },
      filaments: user.filaments.map { |f| { id: f.id, name: f.name, material: f.material_type } },
      resins: user.resins.map { |r| { id: r.id, name: r.name, type: r.resin_type } },
      defaults: {
        vat: user.default_vat_percentage,
        prep_time: user.default_prep_time_minutes,
        prep_rate: user.default_prep_cost_per_hour,
        postprocessing_time: user.default_postprocessing_time_minutes,
        postprocessing_rate: user.default_postprocessing_cost_per_hour
      }
    }
  }
end
```

### Calculation Engine

Reuse existing calculation logic:

```ruby
# PrintPricing model already has all calculation methods
# AI just needs to populate the database correctly

# Example flow:
1. AI extracts data from conversation
2. PrintPricingBuilderService creates PrintPricing + Plates + PlateFilaments
3. PrintPricing model calculates costs automatically (existing logic)
4. Results displayed in chat
5. User confirms, record saved to database
```

---

## Rollout Strategy

### Feature Flag

Use Flipper gem for gradual rollout:

```ruby
# config/initializers/flipper.rb
Flipper.configure do |config|
  config.default do
    # Use database adapter
    adapter = Flipper::Adapters::ActiveRecord.new
    Flipper.new(adapter)
  end
end

# Enable for specific users
Flipper.enable(:ai_estimates, User.find_by(email: "beta@example.com"))

# Enable for Pro users
Flipper.enable_group(:ai_estimates, :pro_users)

# Enable for percentage of users
Flipper.enable_percentage_of_actors(:ai_estimates, 25)

# Check in controller
def index
  unless Flipper.enabled?(:ai_estimates, current_user)
    redirect_to root_path, alert: "Feature not available"
  end
end
```

### Beta Testing Plan

**Phase 1: Internal Testing** (Week 1)
- Enable for admin users only
- Test all 7 languages
- Verify cost tracking
- Fix bugs

**Phase 2: Beta Users** (Week 2-3)
- Invite 50 Pro plan users
- Gather feedback via in-app survey
- Monitor AI costs and accuracy
- Iterate on prompts

**Phase 3: Pro Plan Rollout** (Week 4)
- Enable for all Pro users
- Monitor usage and costs
- Optimize based on data

**Phase 4: Startup Plan** (Week 5-6)
- Enable for Startup users (limited to 50/month)
- Track conversion rates

**Phase 5: Free Tier** (Week 7+)
- Enable for Free users (limited to 10/month)
- Use as lead magnet for upgrades

### Monitoring Metrics

Track these KPIs:

1. **Adoption**: % of users who start a chat
2. **Completion**: % of chats that result in saved estimate
3. **Accuracy**: % of estimates not edited after saving
4. **Cost per estimate**: Average AI API cost
5. **Messages per estimate**: Average conversation length
6. **Response time**: AI response latency
7. **Error rate**: Failed API calls
8. **User satisfaction**: Post-chat rating (1-5 stars)
9. **Conversion**: Free → Startup → Pro upgrades attributed to AI feature

### Success Criteria

**Launch Goals** (Month 1):
- ✅ 30% of active users try AI estimates
- ✅ 60% completion rate (start → saved estimate)
- ✅ <$0.10 average cost per estimate
- ✅ <3s average AI response time
- ✅ <2% error rate
- ✅ 4.0+ average user rating

**Growth Goals** (Month 3):
- ✅ 50% of active users use AI estimates regularly
- ✅ 70% completion rate
- ✅ 20% reduction in pricing form abandonment
- ✅ 15% increase in Pro plan upgrades (attributed to AI feature)

---

## Cost Management

### Budget Allocation

**Monthly Budget by Plan**:
- **Free**: $10/month total (10 estimates × $0.10 avg, can use cheaper model)
- **Startup**: $50/month total (50 estimates × $0.10 avg)
- **Pro**: $500/month total (unlimited estimates, monitor outliers)

**Total Expected Monthly Cost**: $2,000-$5,000 depending on adoption

**Revenue Impact**:
- If AI feature drives 10% more Pro upgrades: +15 users × ¥1,500 = ¥22,500/month (+$150 USD)
- If 50% of Startup users engage with AI: retention improves, churn decreases

### Cost Optimization Strategies

1. **Model Selection**:
   - Use GPT-3.5 Turbo for simple queries (classification)
   - Reserve GPT-4 for complex pricing scenarios
   - Fallback to Gemini 2.0 Flash when near budget limits

2. **Prompt Optimization**:
   - Cache user profile data (don't repeat every message)
   - Use shorter system prompts (remove examples)
   - Compress conversation history after 10 messages

3. **Response Caching**:
   - Cache common questions ("What printer should I use?")
   - Cache material suggestions based on print time
   - Use Redis for fast lookup

4. **Smart Routing**:
   - Detect simple queries (e.g., "What's my limit?") → don't call AI
   - Use regex for common patterns before AI call
   - Implement keyword shortcuts ("/help", "/status")

5. **Batching**:
   - Process multiple questions in single AI request when possible
   - Reduce round-trips

### Monitoring & Alerts

**Daily Cost Report** (email to admin):
```
📊 AI Estimates - Daily Report

Date: 2026-01-16
──────────────────────────────
Total Estimates: 127
Completed Chats: 89 (70%)
Failed Chats: 12 (9%)
Abandoned: 26 (21%)

AI Costs:
- GPT-4 Turbo: $8.45 (67 requests)
- GPT-3.5 Turbo: $1.23 (45 requests)
- Gemini Flash: $0.15 (15 requests)
Total: $9.83

Avg Cost/Estimate: $0.078
Avg Messages/Chat: 8.5
Avg Response Time: 2.1s

Top Users:
1. user@example.com - 8 estimates
2. another@example.com - 6 estimates

⚠️ Alerts:
- User pro@example.com had 3 failed requests (check logs)
```

**Slack Alert** (when daily spend > $50):
```
🚨 AI Estimates: High Cost Alert

Today's spend: $67.50 (threshold: $50)
Estimated monthly: $2,025

Breakdown:
- GPT-4: $52.00 (320 requests)
- GPT-3.5: $8.50 (180 requests)
- Gemini: $7.00 (950 requests)

Action: Review usage patterns and consider model optimization
```

---

## Multilingual Support

### Language Detection

Use user's locale preference (already stored in session):

```ruby
# In ChatSessionsController
def create
  @chat_session = current_user.chat_sessions.create!(
    locale: I18n.locale,
    metadata: { user_defaults: current_user.pricing_defaults }
  )
end

# In AiAssistantService system prompt
def language_instruction(locale)
  case locale.to_s
  when "ja" then "Respond in Japanese (日本語)"
  when "es" then "Respond in Spanish (Español)"
  when "fr" then "Respond in French (Français)"
  when "ar" then "Respond in Arabic (العربية) with RTL formatting"
  when "hi" then "Respond in Hindi (हिन्दी)"
  when "zh-CN" then "Respond in Simplified Chinese (简体中文)"
  else "Respond in English"
  end
end
```

### Translation Integration

Reuse existing translation infrastructure:

```ruby
# config/locales/en/ai_chat.yml
en:
  ai_chat:
    title: "AI Price Estimates"
    new_chat: "New Conversation"
    message_placeholder: "Type your message..."
    send: "Send"
    greeting: "Hi! I'm your pricing assistant. What would you like to estimate today?"
    save_estimate: "Save Estimate"
    edit_details: "Edit Details"

    errors:
      budget_exceeded: "You've reached your monthly limit of %{limit} AI estimates. Upgrade to Pro for unlimited estimates!"
      api_failure: "Sorry, I'm having trouble connecting. Please try again in a moment."
      invalid_data: "I couldn't understand that. Could you rephrase?"

    usage:
      estimates_this_month: "AI Estimates This Month"
      limit: "%{count} / %{limit}"
      cost_this_month: "AI Cost This Month"

# Automatically translated to ja.yml, es.yml, etc. via bin/sync-translations
```

### RTL Support (Arabic)

```css
/* app/assets/stylesheets/ai_chat.css */
[dir="rtl"] .chat-container {
  direction: rtl;
}

[dir="rtl"] .message-user {
  flex-direction: row-reverse;
}

[dir="rtl"] .message-assistant {
  flex-direction: row;
}
```

---

## Documentation

### User-Facing Documentation

**Help Article**: "Getting Price Estimates with AI"

```markdown
# Getting Price Estimates with AI

CalcuMake's AI assistant helps you get accurate price estimates through natural conversation.

## How It Works

1. **Start a chat**: Click "AI Estimates" in the navigation
2. **Describe your project**: Tell the AI what you want to estimate
3. **Answer questions**: The AI asks about printer, materials, print time, etc.
4. **Review estimate**: Confirm the calculated price breakdown
5. **Save to account**: Estimate is saved to your dashboard

## Example Conversation

**You**: "I need a price for a custom phone case"

**AI**: "Great! Which printer would you like to use?"
- Bambu Lab X1 Carbon
- Prusa i3 MK3S+

**You**: "Bambu Lab"

**AI**: "How long does it take to print?"

**You**: "4 hours"

... (continues until estimate is complete)

## Tips for Best Results

- Mention print time if you know it
- Specify material type (PLA, ABS, resin, etc.)
- Include quantity if printing multiple units
- Ask AI to use your default settings if unsure

## Monthly Limits

- **Free Plan**: 10 AI estimates per month
- **Startup Plan**: 50 AI estimates per month
- **Pro Plan**: Unlimited AI estimates

## Privacy

Your conversations are private and encrypted. We only use your data to generate estimates - never for marketing or sharing with third parties.
```

### Developer Documentation

**Technical Guide**: `docs/AI_ESTIMATES_TECHNICAL.md`

Include:
- API endpoints
- Service class documentation
- Database schema
- Testing guidelines
- Prompt engineering tips
- Cost optimization strategies
- Troubleshooting guide

---

## Future Enhancements

### Phase 6+ (Post-Launch)

**Advanced Features**:
1. **Voice input**: Speak your estimate requirements (Web Speech API)
2. **Image upload**: Upload 3D model STL, AI estimates weight/time
3. **Multi-language switching**: Change language mid-conversation
4. **Estimate comparison**: "Compare this to my last phone case estimate"
5. **Batch estimates**: "Create 5 estimates for different filament colors"
6. **Template creation**: "Save this as a template for future phone cases"
7. **Invoice generation**: "Create an invoice from this estimate"
8. **Client integration**: "Send this estimate to my client John Doe"
9. **3D model analysis**: Upload STL → auto-detect weight, print time, support needs
10. **Marketplace integration**: "Find the cheapest filament supplier for this job"

**AI Improvements**:
1. **Learning from edits**: Track user corrections, improve accuracy
2. **Personalization**: Remember user preferences across conversations
3. **Proactive suggestions**: "You usually add 15% failure rate for this printer"
4. **Anomaly detection**: "This print time seems unusually long for 25g"
5. **Cost optimization**: "You could save ¥200 by using a different filament"

**Analytics & Insights**:
1. **Pricing trends**: "Your average phone case price has increased 10% this month"
2. **Material usage**: "You've used 2.5kg of PLA this quarter"
3. **Profitability**: "Your labor costs are above industry average"
4. **Forecasting**: "Based on current trends, you'll need to restock PLA in 2 weeks"

---

## Appendix: Technical Specifications

### API Endpoint Specifications

**Create Chat Session**:
```
POST /chat_sessions
Authorization: Required (logged-in user)

Response:
{
  "id": 123,
  "title": "New Conversation",
  "status": "active",
  "locale": "en",
  "created_at": "2026-01-16T10:30:00Z"
}
```

**Send Message**:
```
POST /chat_sessions/:id/messages
Authorization: Required (session owner)

Body:
{
  "content": "I need a price estimate for a phone case"
}

Response (Turbo Stream):
<turbo-stream action="append" target="chat_messages">
  <template>
    <div class="message message-assistant">...</div>
  </template>
</turbo-stream>
```

**Generate Estimate**:
```
POST /chat_sessions/:id/generate_estimate
Authorization: Required (session owner)

Response:
{
  "print_pricing_id": 456,
  "final_price": 683.28,
  "currency": "JPY",
  "url": "/print_pricings/456"
}
```

### Database Indexes

```ruby
# Optimize query performance
add_index :chat_sessions, [:user_id, :status, :created_at]
add_index :chat_sessions, [:print_pricing_id]
add_index :chat_messages, [:chat_session_id, :created_at]
add_index :ai_usage_logs, [:user_id, :created_at]
add_index :ai_usage_logs, [:created_at, :cost]  # For cost aggregation
```

### Environment Variables

```bash
# .env.local
OPENROUTER_API_KEY=sk-or-v1-xxxxx  # Already configured for translations
OPENROUTER_CHAT_MODEL=openai/gpt-4-turbo  # Default model for chat
OPENROUTER_FALLBACK_MODEL=openai/gpt-3.5-turbo  # Budget fallback
AI_ESTIMATES_DAILY_BUDGET=100.00  # USD, alert if exceeded
AI_ESTIMATES_ENABLED=true  # Feature flag override
```

### Service Class Interfaces

**AiAssistantService**:
```ruby
class AiAssistantService
  def initialize(user:, chat_session:)
  def send_message(content:)  # Returns AI response text
  def extract_pricing_data  # Returns structured JSON
  def conversation_history  # Returns messages array for context
  private
    def build_system_prompt
    def call_openrouter_api(messages:)
    def parse_structured_output(response)
    def handle_api_error(error)
end
```

**PrintPricingBuilderService**:
```ruby
class PrintPricingBuilderService
  def initialize(user:, extracted_data:)
  def build  # Returns PrintPricing instance (not saved)
  def validate  # Returns validation result
  def save!  # Saves to database, returns result
  private
    def transform_to_api_format(data)
    def apply_user_defaults(data)
    def validate_printer_exists(printer_id)
    def validate_materials_exist(materials)
end
```

---

## Summary & Next Steps

### Implementation Summary

This plan provides a complete roadmap for adding AI-powered price estimate chat to CalcuMake:

✅ **Database Schema**: New tables for chat sessions, messages, and usage tracking
✅ **AI Integration**: OpenRouter API with GPT-4/Claude/Gemini model selection
✅ **Conversation Flow**: Natural language interface with structured data extraction
✅ **API Integration**: Leverages existing RESTful API and calculation engine
✅ **Security**: Authentication, rate limiting, budget controls, data encryption
✅ **Testing**: Comprehensive unit, integration, and system test strategy
✅ **UX Design**: Chat interface with real-time updates and mobile support
✅ **Multilingual**: Supports all 7 CalcuMake languages
✅ **Cost Management**: Budget tracking, optimization strategies, monitoring alerts
✅ **Rollout Plan**: Phased deployment with feature flags and beta testing

### Estimated Timeline

- **Phase 1**: Core Infrastructure (2 weeks)
- **Phase 2**: Data Extraction (2 weeks)
- **Phase 3**: UX & Optimization (2 weeks)
- **Phase 4**: Multilingual & Advanced (2 weeks)
- **Phase 5**: Production Deployment (2 weeks)

**Total**: 10 weeks from start to production launch

### Estimated Costs

**Development**:
- 400 development hours × $100/hr = $40,000 (if outsourced)
- Internal development: 10 weeks of dedicated development time

**Operational** (monthly):
- AI API costs: $2,000-$5,000/month (depends on adoption)
- Server costs: Negligible (uses existing infrastructure)
- Monitoring: Included in existing Sentry/analytics

**ROI Potential**:
- If 20% adoption → 10% increase in Pro conversions = +¥37,500/month revenue
- Improved user experience → reduced churn → +5% retention = +¥15,000/month
- Competitive advantage → market differentiation

### Next Steps

1. **Review this plan** with stakeholders and get approval
2. **Set up development environment** with OpenRouter API key
3. **Create database migrations** for new tables
4. **Build Phase 1 prototype** for internal testing
5. **Iterate based on feedback** from beta users
6. **Launch to Pro users first**, then expand to other tiers

### Questions to Resolve

Before starting implementation:

1. **Model selection**: GPT-4 Turbo or Claude 3.5 Sonnet as default?
2. **Free tier limits**: 10 estimates/month or start with 5?
3. **Conversation retention**: Keep for 90 days or longer?
4. **Budget allocation**: What's the max monthly AI spend?
5. **Feature priority**: Voice input in Phase 6 or later?
6. **Analytics integration**: Google Analytics or custom dashboard?
7. **Beta testing**: How many users for initial beta?

---

**End of Plan**

This comprehensive plan provides everything needed to implement AI-powered price estimates in CalcuMake. The feature integrates seamlessly with existing infrastructure, provides significant value to users, and positions CalcuMake as an innovative leader in 3D printing cost estimation tools.
