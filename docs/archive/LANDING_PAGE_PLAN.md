# CalcuMake Landing Page & Feature Enhancement Plan

**Branch**: `paid` - All SaaS transformation features developed on this branch
**Current Status**: Planning phase complete, ready for implementation
**Base Branch**: `master` (production CalcuMake app)

## Project Overview

Transform CalcuMake from an internal tool to a commercial SaaS product with:

- Professional landing page with conversion optimization
- Freemium pricing model with ads
- OAuth authentication for quick onboarding
- Email confirmation via Resend
- Interactive demo page
- SEO optimization for 3D printing keywords

## 1. Landing Page Strategy

### Primary Goal

Convert 3D printing enthusiasts into CalcuMake users by showcasing the pain points we solve.

### Target Audience

- **Hobbyist 3D Printers**: Need cost tracking for personal projects
- **Small Print Services**: Require professional pricing for customers
- **Makerspaces**: Want standardized pricing across multiple printers
- **Etsy Sellers**: Need accurate cost calculations for product pricing

### Landing Page Sections

#### Hero Section

- **Headline**: "Make 3D Printing Profitable"
- **Subheadline**: "Stay competitive. Professional cost calculator with multi-currency and multi-lingual support, printer management, and instant invoicing."
- **CTA Button**: "Start Calculating Free" (leads to OAuth signup)
- **Hero Visual**: Interactive cost calculator preview or before/after pricing comparison

#### Problem Statement

- "Are you losing money on 3D prints?"
- Pain points:
  - Manual calculation errors
  - Forgetting electricity costs
  - Inconsistent pricing
  - Time wasted on spreadsheets
  - Stay organized, your data in one place.

#### Solution Showcase (Features)

1. **Accurate Cost Calculation**

   - Filament weight + spool cost
   - Electricity consumption tracking
   - Labor time (prep + post-processing)
   - Machine depreciation

2. **Multi-Printer Management**

   - Track different power consumptions
   - ROI tracking per printer
   - Bulk print job organization

3. **Professional Invoicing**

   - Auto-generated PDF invoices
   - Custom company branding
   - Multi-currency support

4. **Project Organization**
   - Search and filter print jobs
   - Duplicate similar projects
   - Print history tracking

#### Social Proof

- Will need to do this in the future!
- User testimonials (need to collect)
- "Trusted by 1000+ makers worldwide"
- Before/after cost accuracy stories

#### Pricing Tiers (Freemium Model)

**Free Tier:**

- **First month**: Full Startup tier access (trial period)
- **After trial**: Up to 5 print calculations per month
- 1 printer profile
- 4 filament types
- 5 invoices per month
- CalcuMake branding on invoices
- **Ads** (Note: AdSense implementation pending approval - can take weeks)

**Startup Tier ($0.99/month):**

- Up to 50 print calculations per month
- Up to 10 printer profiles
- Up to 16 filament types
- Remove CalcuMake branding
- **No ads**

**Pro Tier ($9.99/month):**

- Unlimited print calculations
- Unlimited printers
- Unlimited filaments and invoices
- Remove CalcuMake branding
- **No ads**
- Priority support
- Advanced analytics
- Bulk import/export
- Future premium features

#### Trust Signals

- "No credit card required - start with full Startup features for 30 days"
- "Cancel anytime"
- "Your data stays private"
- SSL security badge
- Privacy policy link

#### FAQ Section

- "How accurate are the calculations?"
- "Can I use different currencies?"
- "Do you support [printer brand]?"
- "How do electricity costs work?"
- "Can I customize invoices?"

#### Footer CTA

- "Ready to stop losing money on 3D prints?"

### Landing Page Technical Requirements

- **New Route**: `GET /` → `pages#landing` (when not authenticated)
- **Responsive Design**: Mobile-first with Moab theme
- **SEO Optimization**: Structured data, meta tags for "3D print cost calculator"
- **Analytics**: Google Analytics conversion tracking
- **A/B Testing**: Headline and CTA variations

## 2. Demo Page Strategy

### Purpose

Allow users to experience CalcuMake without signup via pre-populated demo data.

### Demo Features

1. **Read-Only Calculations**: Show realistic print job with all costs
2. **Interactive Elements**: Change filament weight, see cost update
3. **Sample Invoice**: Generate and download demo PDF
4. **Multiple Scenarios**: Show different project types (miniatures, functional parts, art)

### Demo Page Structure

- **Route**: `GET /demo` → `pages#demo`
- **Demo Data**: Pre-loaded printer, filaments, and sample print jobs
- **Limitations**: Cannot save, edit, or create new calculations
- **CTA**: "Sign up to save your calculations"
- **Watermarked**: All PDFs show "DEMO MODE"

### Technical Implementation

- Demo controller with hardcoded sample data
- Same UI as regular app but with disabled forms
- Demo-specific CSS classes for styling differences
- JavaScript to show "login to try for free" modals on restricted actions

## 3. Pricing Tier Implementation

### Database Schema Changes

```ruby
# Add to users table
add_column :users, :plan, :string, default: 'free', null: false
add_column :users, :plan_expires_at, :datetime
add_column :users, :trial_ends_at, :datetime
add_column :users, :stripe_customer_id, :string

# Usage tracking
create_table :usage_trackings do |t|
  t.references :user, null: false, foreign_key: true
  t.string :resource_type, null: false # 'print_pricing', 'invoice', etc.
  t.integer :count, default: 0
  t.date :period_start, null: false
  t.timestamps
end
```

### Plan Limits

```ruby
class PlanLimits
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
  def self.limits_for_user(user)
    return STARTUP_LIMITS if user.in_trial_period?

    case user.plan
    when 'free' then FREE_LIMITS
    when 'startup' then STARTUP_LIMITS
    when 'pro' then PRO_LIMITS
    else FREE_LIMITS
    end
  end
end
```

### Ad Integration (Free Users)

- **Google AdSense**: Add ads to sidebar and between content sections
- **Ad Placement**: Non-intrusive, following Google policies
- **Ad-Free Experience**: Immediate benefit of Pro upgrade
- **Implementation Note**: AdSense approval can take 2-4 weeks and requires substantial content. Plan to launch freemium model without ads initially, then add ads after approval.

### Billing Integration

- **Stripe**: Handle Pro plan subscriptions
- **Webhook Handling**: Plan upgrades/downgrades
- **Grace Period**: 3 days after plan expiration

## 4. OAuth Authentication Strategy

### Supported Providers

1. **Google OAuth** (Primary): Most 3D printing content is on YouTube
2. **GitHub OAuth**: Developer-friendly audience
3. **Microsoft OAuth**: Business users

### Benefits

- **Faster Onboarding**: Reduce signup friction from 5 steps to 1 click
- **Trust**: Users trust established providers
- **Pre-filled Data**: Get user name/email automatically

### Technical Implementation

```ruby
# Gemfile
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-github'
gem 'omniauth-microsoft_graph'
gem 'omniauth-rails_csrf_protection'

# Routes
devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

# User model
def self.from_omniauth(auth)
  where(email: auth.info.email).first_or_create do |user|
    user.email = auth.info.email
    user.name = auth.info.name
    user.provider = auth.provider
    user.uid = auth.uid
    # Skip email confirmation for OAuth users
    user.skip_confirmation!
  end
end
```

### Landing Page Integration

- **Prominent OAuth Buttons**: "Continue with Google", "Continue with GitHub"
- **Fallback**: Traditional email signup below OAuth options
- **Progressive Enhancement**: OAuth buttons work without JavaScript

## 5. Email Confirmation with Resend

### Why Resend over ActionMailer

- **Deliverability**: Better inbox placement than self-hosted
- **Analytics**: Open rates, click tracking
- **Templates**: Professional email design
- **Compliance**: Built-in unsubscribe handling

### Implementation

```ruby
# Gemfile
gem 'resend'

# config/initializers/resend.rb
Resend.api_key = Rails.application.credentials.resend.api_key

# Custom mailer
class ResendMailer
  def self.confirmation_instructions(user, token)
    Resend::Emails.send({
      from: "CalcuMake <noreply@calcumake.com>",
      to: [user.email],
      subject: "Confirm your CalcuMake account",
      html: ApplicationController.render(
        template: "devise/mailer/confirmation_instructions",
        assigns: { user: user, token: token }
      )
    })
  end
end
```

### Email Templates

- **Confirmation**: Branded HTML template with clear CTA
- **Welcome Series**: 3-email onboarding sequence
- **Upgrade Prompts**: When approaching plan limits
- **Feature Announcements**: New calculator features

### Email Strategy

1. **Immediate**: Account confirmation
2. **Day 1**: "Your first print calculation" guide
3. **Day 3**: "Advanced features you might have missed"
4. **Day 7**: "Upgrade to Pro" with specific benefits
5. **Monthly**: Feature updates and 3D printing tips

## 6. SEO Strategy

### Target Keywords

**Primary:** "3D print cost calculator"
**Secondary:** "3D printing calculator", "filament cost calculator", "3D printer cost estimation"
**Long-tail:** "how to calculate 3D printing costs", "3D printing business pricing"

### Content Strategy

- **Landing Page**: Optimize for primary keywords
- **Blog Section**: 3D printing cost guides, pricing strategies
- **FAQ Pages**: Answer specific calculation questions
- **Tool Pages**: Separate pages for different calculators

### Technical SEO

- **Structured Data**: Calculator, Organization, FAQPage schemas
- **Meta Tags**: Optimized titles and descriptions
- **Sitemap**: Dynamic sitemap generation
- **Page Speed**: Optimize images, minimize JavaScript
- **Mobile**: Perfect mobile experience

## 7. Technical Implementation Plan

### Phase 1: Foundation (Week 1-2)

1. Create landing page controller and routes
2. Design and implement landing page HTML/CSS
3. Add Google Analytics and AdSense
4. Set up basic SEO structure

### Phase 2: Authentication (Week 3)

1. Add OAuth gems and configuration
2. Implement OAuth callback controllers
3. Update user registration flow
4. Integrate Resend email service

### Phase 3: Pricing & Demo (Week 4-5)

1. Implement plan limits and usage tracking
2. Add billing integration with Stripe
3. Create demo page with sample data
4. Implement ad display logic for free users

### Phase 4: Polish & Launch (Week 6)

1. Add email template designs
2. Implement conversion tracking
3. SEO optimization and testing
4. Performance optimization
5. Launch and monitor metrics

## 8. Success Metrics

### Conversion Funnel

1. **Landing Page Views**: Organic search + direct traffic
2. **Demo Interactions**: Demo page engagement time
3. **Signups**: OAuth vs email registration rates
4. **Activation**: First print calculation completed
5. **Retention**: Return visits within 7 days
6. **Upgrade**: Free to Pro conversion rate

### Target KPIs

- **Conversion Rate**: 3-5% landing page to signup
- **Activation Rate**: 60% of signups complete first calculation
- **Free to Pro**: 5% monthly conversion rate
- **Retention**: 40% weekly active users

### A/B Tests

1. **Landing Page Headlines**: "Make 3D Printing Profitable" vs "Stop Guessing Print Costs"
2. **CTA Colors**: Primary red vs secondary orange
3. **Pricing Positions**: Monthly vs annual emphasis
4. **Social Proof**: Testimonials vs statistics

## 9. Risk Mitigation

### Technical Risks

- **OAuth Failures**: Fallback to email signup always available
- **Email Deliverability**: Monitor Resend analytics, have backup SMTP
- **AdSense Approval Delays**: Can take 2-4 weeks and requires quality content. Launch freemium without ads first, add ads post-approval
- **Plan Limits**: Graceful degradation when limits exceeded

### Business Risks

- **Low Conversion**: A/B testing and user feedback loops
- **Competition**: Focus on unique multi-plate system and accuracy
- **Churn**: Onboarding email sequence and feature discovery

### Launch Risks

- **Traffic Spikes**: Ensure hosting can handle load
- **Bug Reports**: Comprehensive testing and user feedback channels
- **SEO Penalties**: Follow Google guidelines strictly

## 10. Next Steps

1. **Review and Approve Plan**: Get stakeholder buy-in on strategy
2. **Design Mockups**: Create visual designs for landing page
3. **Content Creation**: Write copy for all landing page sections
4. **Technical Setup**: Begin Phase 1 implementation
5. **User Research**: Interview potential users about pain points
6. **Competitive Analysis**: Review similar tools' pricing and features

This plan transforms CalcuMake into a commercial-ready SaaS product while maintaining the excellent technical foundation already built.
