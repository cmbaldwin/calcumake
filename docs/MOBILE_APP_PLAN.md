# CalcuMake Mobile Apps - Comprehensive Development Plan

## Executive Summary

CalcuMake has a **production-ready REST API** (95% feature coverage) and solid infrastructure for mobile development. This plan outlines three strategic approaches for building Android and iOS apps, with timeline estimates and resource requirements.

---

## Current State Assessment

### What's Already Mobile-Ready

| Component | Status | Notes |
|-----------|--------|-------|
| REST API | ✅ Production | JSON:API compliant, versioned (`/api/v1`), 234 tests |
| Bearer Auth | ✅ Complete | SHA-256 hashed tokens, expiration options |
| PWA | ✅ Live | Installable, offline-capable, service worker |
| Multi-language | ✅ 7 languages | en, ja, es, fr, ar, hi, zh-CN |
| Multi-currency | ✅ Complete | User-configurable defaults |
| Subscription System | ✅ Stripe | Free, Startup (¥150), Pro (¥1,500) |

### API Endpoints Available

```
User & Auth:     GET/PATCH /api/v1/me, /me/usage, /me/export
Print Pricings:  Full CRUD + duplicate, increment/decrement
Plates:          Full CRUD (nested under print_pricings)
Invoices:        Full CRUD + status transitions
Line Items:      Full CRUD (nested under invoices)
Printers:        Full CRUD
Filaments:       Full CRUD + duplicate
Resins:          Full CRUD + duplicate
Clients:         Full CRUD
API Tokens:      Create, list, revoke
Health Check:    GET /api/v1/health (public)
Calculator:      POST /api/v1/calculator (public)
```

### Gaps to Address

| Gap | Priority | Effort |
|-----|----------|--------|
| Push notifications | High | 1-2 weeks |
| OAuth mobile flow | High | 1 week |
| File upload API | Medium | 1 week |
| Subscription API | Medium | 1-2 weeks |
| Rate limit headers | Low | 2 days |
| WebSocket/webhooks | Low | 2 weeks |

---

## Development Approaches

### Option 1: Native Apps (Recommended)

**Build separate native iOS and Android apps**

#### Pros
- Best performance and UX
- Full access to device features (camera, biometrics, push)
- App Store optimization (ASO)
- Offline-first architecture possible
- Native UI follows platform conventions

#### Cons
- Highest development cost
- Two codebases to maintain
- Longest time to market

#### Tech Stack

**iOS:**
- Language: Swift 5+
- UI Framework: SwiftUI
- Architecture: MVVM + Combine
- Networking: URLSession or Alamofire
- Local Storage: Core Data or SwiftData
- Auth: Keychain for tokens, ASWebAuthenticationSession for OAuth
- Push: Apple Push Notification Service (APNs)
- Payments: StoreKit 2 (for in-app) or Stripe iOS SDK

**Android:**
- Language: Kotlin
- UI Framework: Jetpack Compose
- Architecture: MVVM + Kotlin Coroutines
- Networking: Retrofit + OkHttp
- Local Storage: Room
- Auth: EncryptedSharedPreferences, Custom Tabs for OAuth
- Push: Firebase Cloud Messaging (FCM)
- Payments: Google Play Billing or Stripe Android SDK

#### Timeline: 6-8 months
- API enhancements: 2-4 weeks
- iOS development: 3-4 months
- Android development: 3-4 months (parallel)
- Testing & launch: 4-6 weeks

#### Cost Estimate: ¥15-25M
- iOS developer(s): ¥6-10M
- Android developer(s): ¥6-10M
- Backend work: ¥2-3M
- Testing/launch: ¥1-2M

---

### Option 2: Cross-Platform (React Native or Flutter)

**Single codebase for both platforms**

#### Pros
- Single codebase (faster development)
- Lower cost than native
- Easier to maintain consistency
- Good community and libraries

#### Cons
- Slightly lower performance than native
- Platform-specific features may require native bridges
- UI may not feel 100% native

#### Tech Stack Options

**React Native:**
- JavaScript/TypeScript
- React Navigation
- Redux or Zustand for state
- AsyncStorage + encrypted storage
- Firebase for push
- Stripe React Native SDK

**Flutter:**
- Dart language
- Material Design 3 / Cupertino widgets
- Riverpod or BLoC for state
- sqflite or Hive for local storage
- Firebase for push
- Stripe Flutter SDK

#### Timeline: 4-6 months
- API enhancements: 2-4 weeks
- Cross-platform development: 2.5-3.5 months
- Platform-specific polish: 2-3 weeks
- Testing & launch: 4-6 weeks

#### Cost Estimate: ¥8-15M
- Cross-platform developer(s): ¥5-9M
- Backend work: ¥2-3M
- Testing/launch: ¥1-3M

---

### Option 3: Progressive Web App (PWA) Enhancement

**Enhance existing PWA, wrap with Capacitor for app stores**

#### Pros
- Fastest time to market
- Lowest cost
- Existing codebase (Rails + Stimulus)
- Already works offline
- Single codebase for web + mobile

#### Cons
- Limited native features
- Performance not as good as native
- iOS Safari limitations
- May not feel like a "real" app
- App Store approval can be challenging

#### Tech Stack
- Existing Rails + Stimulus app
- Capacitor for native wrapper
- Capacitor plugins for:
  - Push notifications
  - Biometric auth
  - Secure storage
  - Camera access

#### Timeline: 2-3 months
- PWA enhancements: 2-4 weeks
- Capacitor integration: 2-3 weeks
- Native feature plugins: 2-3 weeks
- Testing & launch: 3-4 weeks

#### Cost Estimate: ¥3-6M
- Full-stack developer: ¥2-4M
- Testing/launch: ¥1-2M

---

### Option 4: Hotwire Native (RECOMMENDED)

**Wrap existing Rails + Turbo app in native iOS/Android shells**

> CalcuMake already uses Turbo + Stimulus, making Hotwire Native the **ideal choice**.

#### What is Hotwire Native?

[Hotwire Native](https://native.hotwired.dev/) is 37signals' framework for building native iOS and Android apps that wrap your existing Hotwire web application. It combines:
- **Turbo Native** - Native navigation with web views
- **Bridge Components** (formerly Strada) - Native UI controls driven by web

Used in production by **Basecamp**, **HEY Mail**, **HEY Calendar**, and **The StoryGraph**.

#### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                  Native Shell (Swift/Kotlin)            │
│  ┌─────────────────────────────────────────────────┐    │
│  │              Native Navigation Bar              │    │
│  ├─────────────────────────────────────────────────┤    │
│  │                                                 │    │
│  │              WKWebView / WebView                │    │
│  │         (Your existing Rails views!)            │    │
│  │                                                 │    │
│  │    Turbo intercepts links → Native transitions  │    │
│  │                                                 │    │
│  ├─────────────────────────────────────────────────┤    │
│  │              Native Tab Bar                     │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

1. **Single WebView** managed across multiple view controllers/fragments
2. **Turbo.js adapter** intercepts link clicks → pushes native screens
3. **Native navigation** (back buttons, tab bars, modals) with web content
4. **Bridge Components** enable native controls (buttons, menus) driven by Stimulus

#### Pros
- **Reuse 100% of existing Rails views** - No UI rewrite needed
- **Fastest time to market** - 4-8 weeks for basic app
- **Ship updates without App Store review** - HTML changes deploy instantly
- **Single codebase** - Web + iOS + Android share views
- **Native navigation UX** - Platform-appropriate transitions
- **Bridge Components** - Add native buttons, menus, forms when needed
- **Production-proven** - Powers 37signals apps at scale
- **Low maintenance** - One Rails codebase to maintain
- **Perfect fit** - CalcuMake already uses Turbo + Stimulus

#### Cons
- **WebView performance** - Not as fast as fully native (acceptable for forms/calculators)
- **Limited offline** - Requires network for most operations
- **Some native features harder** - Camera, complex gestures need bridging
- **Learning curve** - Swift/Kotlin basics needed for shell app
- **App Store guidelines** - Must provide native value (navigation counts)

#### Tech Stack

**iOS ([hotwire-native-ios](https://github.com/hotwired/hotwire-native-ios)):**
- Swift 5.3+, iOS 14+
- WKWebView with Turbo adapter
- Path Configuration for navigation rules
- Bridge Components for native controls
- Latest: v1.2.2 (July 2025)

**Android ([hotwire-native-android](https://github.com/hotwired/hotwire-native-android)):**
- Kotlin, Android SDK 28+
- WebView with Turbo adapter
- Navigation Fragments
- Bridge Components
- Latest: v1.2.4 (July 2025)

**Rails Backend:**
- Turbo 7+ (already have ✅)
- Stimulus controllers (already have ✅)
- `turbo_native_app?` helper for mobile-specific logic
- Path configuration JSON endpoint

#### Timeline: 4-8 weeks

| Phase | Duration | Tasks |
|-------|----------|-------|
| Setup | Week 1 | iOS/Android projects, signing, basic shell |
| Navigation | Week 2 | Path configuration, tab bar, modals |
| Auth | Week 1-2 | OAuth flow, secure token storage |
| Bridge Components | Week 2-3 | Native buttons, forms, menus |
| Push Notifications | Week 1 | Firebase/APNs integration |
| Polish & Testing | Week 1-2 | Platform-specific fixes, beta |
| **Total** | **4-8 weeks** | |

#### Cost Estimate: ¥2-5M
- iOS/Android developer (same person possible): ¥1.5-3M
- Backend adjustments: ¥0.5-1M
- Testing/launch: ¥0.5-1M

#### What Changes in Rails

**1. Path Configuration** (JSON file served by Rails):
```json
{
  "rules": [
    { "patterns": ["/"], "properties": { "presentation": "default" } },
    { "patterns": ["/print_pricings/new"], "properties": { "presentation": "modal" } },
    { "patterns": ["/profile"], "properties": { "presentation": "replace" } },
    { "patterns": ["/sign_in", "/sign_up"], "properties": { "presentation": "replace_root" } }
  ]
}
```

**2. Mobile-specific view tweaks:**
```erb
<% if turbo_native_app? %>
  <%# Hide web navigation - native shell provides it %>
  <% content_for :hide_navbar, true %>
<% end %>
```

**3. Bridge Components** (optional, for native controls):
```erb
<%# In your view %>
<div data-controller="bridge--button"
     data-bridge--button-title-value="Save"
     data-action="bridge--button:connect->form#enableSubmit">
</div>
```

```javascript
// Stimulus controller bridges to native button
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "button"
  // Native button appears in navigation bar
}
```

---

## Recommended Approach

### For CalcuMake: **Option 4 (Hotwire Native)** ⭐

**This is the clear winner for CalcuMake because:**

1. **Already using Turbo + Stimulus** - Zero UI rewrite needed
2. **Fastest to market** - 4-8 weeks vs 4-6 months for Flutter
3. **Lowest cost** - ¥2-5M vs ¥8-15M for cross-platform
4. **Instant updates** - Deploy Rails changes without App Store review
5. **Single codebase** - Web + iOS + Android share the same views
6. **Production-proven** - 37signals uses this for all their apps
7. **Feature parity guaranteed** - Same code runs everywhere
8. **Existing team can build it** - Rails devs + basic Swift/Kotlin

**Comparison Matrix:**

| Factor | Native | Flutter | PWA+Capacitor | Hotwire Native |
|--------|--------|---------|---------------|----------------|
| Time to market | 6-8 mo | 4-6 mo | 2-3 mo | **4-8 weeks** |
| Cost | ¥15-25M | ¥8-15M | ¥3-6M | **¥2-5M** |
| UI rewrite needed | 100% | 100% | 0% | **0%** |
| Native UX | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | **⭐⭐⭐⭐** |
| Maintenance | High | Medium | Low | **Very Low** |
| Fits CalcuMake | ✓ | ✓ | ✓ | **✓✓✓** |

### When to Choose Flutter Instead

Consider Flutter if you need:
- Complex offline-first functionality
- Heavy use of device sensors/camera
- Gaming-level animations
- Complete independence from web app

---

## Implementation Plan (Hotwire Native)

### Phase 0: Rails Preparation (Week 1)

#### Mobile Detection & Layout
- [ ] Add `turbo_native_app?` detection (built into Turbo)
- [ ] Create mobile-specific layout variant
  ```erb
  <%# app/views/layouts/application.html.erb %>
  <% if turbo_native_app? %>
    <%= render "layouts/mobile_chrome" %>
  <% else %>
    <%= render "layouts/web_chrome" %>
  <% end %>
  ```
- [ ] Hide web navigation when in native app
- [ ] Adjust touch targets for mobile (44pt minimum)
- [ ] Test responsive layouts on mobile viewports

#### Path Configuration Endpoint
- [ ] Create `/api/mobile/path_configuration.json` endpoint
- [ ] Define navigation rules for all routes:
  ```json
  {
    "settings": {
      "screenshots_enabled": true
    },
    "rules": [
      { "patterns": ["/"], "properties": { "presentation": "default" } },
      { "patterns": ["/print_pricings", "/invoices", "/printers"],
        "properties": { "presentation": "default" } },
      { "patterns": ["/**/new", "/**/edit"],
        "properties": { "presentation": "modal" } },
      { "patterns": ["/users/sign_in", "/users/sign_up"],
        "properties": { "presentation": "replace_root", "context": "modal" } },
      { "patterns": ["/profile"],
        "properties": { "presentation": "replace" } }
    ]
  }
  ```
- [ ] Add path configuration caching

### Phase 1: iOS App (Weeks 2-3)

#### Project Setup
- [ ] Create Xcode project with Swift
- [ ] Add Hotwire Native iOS via Swift Package Manager
  ```swift
  // Package.swift dependency
  .package(url: "https://github.com/hotwired/hotwire-native-ios", from: "1.2.0")
  ```
- [ ] Configure app signing (Apple Developer account required)
- [ ] Set up basic SceneDelegate with Hotwire

#### Navigation Structure
- [ ] Configure UITabBarController with 4 tabs:
  - Dashboard (`/dashboard`)
  - Calculations (`/print_pricings`)
  - Invoices (`/invoices`)
  - Settings (`/profile`)
- [ ] Load path configuration from Rails server
- [ ] Configure modal presentation for new/edit screens
- [ ] Handle authentication redirects

#### Authentication
- [ ] Implement OAuth flow using ASWebAuthenticationSession
- [ ] Store session cookies securely in Keychain
- [ ] Handle `Sign in with Apple` (required for App Store)
- [ ] Implement token-based session management

#### Native Enhancements
- [ ] Add pull-to-refresh (native UIRefreshControl)
- [ ] Configure user agent for `turbo_native_app?` detection
- [ ] Handle external links (open in Safari)
- [ ] Add loading indicators during navigation

### Phase 2: Android App (Weeks 3-4)

#### Project Setup
- [ ] Create Android Studio project with Kotlin
- [ ] Add Hotwire Native Android dependency
  ```kotlin
  // build.gradle
  implementation("dev.hotwire:core:1.2.4")
  implementation("dev.hotwire:navigation-fragments:1.2.4")
  ```
- [ ] Configure app signing (Google Play Console)
- [ ] Set up MainActivity with Hotwire

#### Navigation Structure
- [ ] Configure BottomNavigationView with 4 destinations
- [ ] Create navigation graph with fragments
- [ ] Load path configuration from Rails server
- [ ] Handle fragment transactions for modals

#### Authentication
- [ ] Implement OAuth flow using Custom Tabs
- [ ] Store session cookies in encrypted preferences
- [ ] Handle Google Sign-In integration
- [ ] Implement WebView cookie management

#### Native Enhancements
- [ ] Add SwipeRefreshLayout for pull-to-refresh
- [ ] Configure user agent string
- [ ] Handle deep links
- [ ] Material Design 3 theming

### Phase 3: Bridge Components (Week 5)

#### Button Component
- [ ] Create native toolbar button component
- [ ] Stimulus controller for button bridge
  ```javascript
  // app/javascript/controllers/bridge/button_controller.js
  import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

  export default class extends BridgeComponent {
    static component = "button"
    static values = { title: String }

    connect() {
      super.connect()
      this.send("connect", { title: this.titleValue })
    }
  }
  ```
- [ ] iOS: UIBarButtonItem integration
- [ ] Android: Toolbar menu integration

#### Form Component
- [ ] Native form submission handling
- [ ] Keyboard management (dismiss on submit)
- [ ] Input validation feedback

#### Menu Component (Optional)
- [ ] Native action sheet / bottom sheet
- [ ] Share functionality
- [ ] Export options (PDF, CSV)

### Phase 4: Push Notifications (Week 6)

#### Backend Setup
- [ ] Add `webpush` or `rpush` gem to Rails
- [ ] Create device registration endpoint
  ```ruby
  # POST /api/v1/devices
  def create
    current_user.devices.create!(
      token: params[:token],
      platform: params[:platform]  # ios or android
    )
  end
  ```
- [ ] Implement notification triggers:
  - Invoice status changes
  - Print job reminders
  - Subscription alerts

#### iOS Push (APNs)
- [ ] Configure push notification capability
- [ ] Request notification permissions
- [ ] Register device token with backend
- [ ] Handle notification tap → deep link

#### Android Push (FCM)
- [ ] Add Firebase SDK
- [ ] Configure FCM in Google Cloud Console
- [ ] Register device token
- [ ] Handle notification intent

### Phase 5: Testing & Polish (Weeks 7-8)

#### iOS Testing
- [ ] Test on multiple iPhone sizes
- [ ] Test on iPad (if supporting)
- [ ] Verify OAuth flows work correctly
- [ ] Test offline behavior (graceful degradation)
- [ ] Accessibility audit (VoiceOver)

#### Android Testing
- [ ] Test on multiple screen densities
- [ ] Test on tablets (if supporting)
- [ ] Verify OAuth flows work correctly
- [ ] Test back button behavior
- [ ] Accessibility audit (TalkBack)

#### App Store Preparation
- [ ] Create app icons (all sizes)
- [ ] Screenshot all screens
- [ ] Write App Store description (all 7 languages)
- [ ] Prepare privacy policy URL
- [ ] Submit to TestFlight / Google Play Beta
- [ ] Address reviewer feedback

#### Launch
- [ ] Submit to App Store (expect 1-2 week review)
- [ ] Submit to Google Play (expect 1-3 day review)
- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Gather user feedback

---

## App Architecture (Hotwire Native)

### How It Works

```
┌──────────────────────────────────────────────────────────────────┐
│                     Native Shell (Swift/Kotlin)                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                   Native Tab Bar Controller                │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │  │
│  │  │Dashboard │ │  Calcs   │ │ Invoices │ │ Settings │       │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │                                                            │  │
│  │                    WKWebView / WebView                     │  │
│  │              (Rails HTML rendered by Turbo)                │  │
│  │                                                            │  │
│  │    ┌─────────────────────────────────────────────────┐     │  │
│  │    │  Link clicked → Turbo intercepts → Native push  │     │  │
│  │    │  Form submitted → Turbo handles → Native dismiss│     │  │
│  │    │  Bridge message → Stimulus → Native UI update   │     │  │
│  │    └─────────────────────────────────────────────────┘     │  │
│  │                                                            │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │                   Native Navigation Bar                    │  │
│  │  [← Back]                              [Native Buttons]    │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│                      CalcuMake Rails Server                      │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Same views for web + mobile (with turbo_native_app?)    │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

### Navigation Flow (Path Configuration)

```
User taps link in WebView
         │
         ▼
┌─────────────────────────────┐
│   Turbo.js intercepts tap   │
│   Extracts destination URL  │
└─────────────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Path Configuration Lookup  │
│  Match URL against patterns │
└─────────────────────────────┘
         │
    ┌────┴────────────────────────────┐
    ▼                                 ▼
┌─────────────┐              ┌─────────────┐
│  "default"  │              │   "modal"   │
│  Push new   │              │  Present    │
│  screen     │              │  modally    │
└─────────────┘              └─────────────┘
         │                           │
         ▼                           ▼
┌─────────────────────────────────────────────┐
│   Native ViewController/Fragment created    │
│   WebView navigates to destination URL      │
│   Native navigation bar appears             │
└─────────────────────────────────────────────┘
```

### Authentication (Cookie-Based)

```
┌──────────────────────────────────────────────────────────┐
│                    Native App Launched                   │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │ Check for valid       │
              │ session cookie        │
              └───────────────────────┘
                    │           │
          ┌─────────┘           └─────────┐
          ▼                               ▼
   ┌──────────────┐               ┌──────────────┐
   │ Cookie valid │               │ No cookie /  │
   │ Load /dashboard│             │ Expired      │
   └──────────────┘               └──────────────┘
                                          │
                                          ▼
                              ┌───────────────────────┐
                              │ Load /users/sign_in   │
                              │ (replace_root mode)   │
                              └───────────────────────┘
                                          │
                          ┌───────────────┴───────────────┐
                          ▼                               ▼
                   ┌──────────────┐               ┌──────────────┐
                   │ Email/Pass   │               │    OAuth     │
                   │ in WebView   │               │ Opens Safari │
                   └──────────────┘               └──────────────┘
                          │                               │
                          └───────────────┬───────────────┘
                                          ▼
                              ┌───────────────────────┐
                              │ Devise sets session   │
                              │ cookie in WebView     │
                              └───────────────────────┘
                                          │
                                          ▼
                              ┌───────────────────────┐
                              │ Store in Keychain/    │
                              │ Keystore (optional)   │
                              └───────────────────────┘
                                          │
                                          ▼
                              ┌───────────────────────┐
                              │ Navigate to /dashboard│
                              │ (replace_root mode)   │
                              └───────────────────────┘
```

### Bridge Components Communication

```
┌─────────────────────────────────────────────────────────────┐
│                        Rails View                           │
│  <div data-controller="bridge--button"                      │
│       data-bridge--button-title-value="Save">               │
│  </div>                                                     │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   Stimulus Controller                        │
│  export default class extends BridgeComponent {             │
│    connect() {                                              │
│      this.send("connect", { title: "Save" })                │
│    }                                                        │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                  ┌───────────────┐
                  │  JavaScript   │
                  │    Bridge     │
                  └───────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Native Component                          │
│  iOS:  UIBarButtonItem(title: "Save", ...)                  │
│  Android:  toolbar.menu.add("Save", ...)                    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                  ┌───────────────┐
                  │  User taps    │
                  │  native button│
                  └───────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   Stimulus Controller                        │
│  handleButtonTap(event) {                                   │
│    this.element.querySelector('form').requestSubmit()       │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Resource Requirements (Hotwire Native)

### Team Structure

| Role | Count | Duration | Notes |
|------|-------|----------|-------|
| Swift/Kotlin Developer | 1 | 6-8 weeks | Can be same person for both platforms |
| Rails Developer | 0.25 | 1-2 weeks | Mobile layout + path config |
| QA Engineer | 0.25 | 1-2 weeks | Device testing |

**Note:** A single developer with Swift + Kotlin experience can build both apps. Joe Masilotti's book targets Rails developers with zero mobile experience.

### Learning Resources

| Resource | Type | Link |
|----------|------|------|
| Official Documentation | Docs | [native.hotwired.dev](https://native.hotwired.dev/) |
| Joe Masilotti's Blog | Tutorials | [masilotti.com/articles](https://masilotti.com/articles/) |
| "Hotwire Native for Rails Developers" | Book | Coming soon |
| Learn Hotwire | Course | [learnhotwire.com](https://learnhotwire.com/) |
| The Rails and Hotwire Codex | Book | [railsandhotwirecodex.com](https://railsandhotwirecodex.com/) |

### Infrastructure Needs

| Service | Purpose | Est. Cost |
|---------|---------|-----------|
| Apple Developer Account | App Store publishing | ¥12,000/year |
| Google Play Console | Play Store publishing | ¥2,500 one-time |
| Firebase (optional) | Push notifications, analytics | Free tier |
| Existing Rails server | No changes needed | ¥0 |
| CI/CD (GitHub Actions) | Build apps | Existing / Free |

---

## Success Metrics

### Launch Targets (First 3 Months)

| Metric | Target |
|--------|--------|
| App Store rating | ≥ 4.0 stars |
| Downloads | 1,000+ |
| DAU/MAU ratio | > 20% |
| Crash-free rate | > 99% |
| API latency (p95) | < 500ms |

### Business Targets (First Year)

| Metric | Target |
|--------|--------|
| Mobile signups | 20% of total signups |
| Mobile DAU | 30% of total DAU |
| Subscription conversions | Same rate as web |
| Feature parity | 100% of core features |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| OAuth complexity on mobile | Use proven SDKs (flutter_appauth, sign_in_with_apple) |
| Offline sync conflicts | Server-wins strategy, clear user feedback |
| App Store rejection | Follow guidelines strictly, beta test thoroughly |
| Performance issues | Profile early, optimize list rendering |
| API rate limiting | Implement exponential backoff, cache aggressively |

---

## Decision Points

With Hotwire Native, most decisions are simpler:

### 1. Development Approach ✅ DECIDED
**Hotwire Native** - Best fit for CalcuMake (already using Turbo + Stimulus)

### 2. Feature Priority
Since you're reusing existing views, you get **100% feature parity immediately**.
- Week 4: Basic app with all web features
- Week 6: Add bridge components for native polish
- Week 8: Push notifications + App Store launch

### 3. Offline Support
**Recommendation: Defer**
- Hotwire Native works best with connectivity
- PWA already provides basic offline caching
- Can add offline queue post-launch if needed

### 4. Push Notifications
**Recommendation: Include in v1.0**
- 1 week of additional work
- High user value (invoice status, reminders)
- Easy to implement with Firebase/APNs

### 5. In-App Purchases
**Recommendation: Redirect to web**
- Stripe already works on mobile web
- Avoid 15-30% App Store/Play Store fees
- Simpler implementation
- Apple allows this for "reader" apps

### 6. Bridge Components
**Recommendation: Start minimal, add as needed**
- Week 5: Add native save/cancel buttons
- Post-launch: Add share sheet, bottom sheets
- Only add what improves UX significantly

### 7. Timeline
**Realistic Estimate: 6-8 weeks**
| Week | Milestone |
|------|-----------|
| 1 | Rails prep + iOS project setup |
| 2 | iOS navigation + tabs |
| 3 | iOS auth + Android project setup |
| 4 | Android navigation + tabs |
| 5 | Bridge components (both) |
| 6 | Push notifications |
| 7 | Testing + polish |
| 8 | Beta + App Store submission |

---

## Next Steps

### Immediate Actions (This Week)
1. **Review this plan** and confirm Hotwire Native approach
2. **Set up Apple Developer account** if not already (¥12,000/year)
3. **Set up Google Play Console** if not already (¥2,500 one-time)

### Week 1 Start
4. **Create iOS Xcode project** with Hotwire Native
5. **Add path configuration endpoint** to Rails
6. **Test `turbo_native_app?` detection** in views

### Learning Path (If Needed)
7. **Read official docs**: [native.hotwired.dev](https://native.hotwired.dev/)
8. **Follow Joe Masilotti's tutorials**: [masilotti.com/articles](https://masilotti.com/articles/)
9. **Try the demo apps**: Both repos include working examples

---

## Appendix: Key Resources

### Official Documentation
- [Hotwire Native Docs](https://native.hotwired.dev/)
- [iOS Getting Started](https://native.hotwired.dev/ios/getting-started)
- [Android Getting Started](https://native.hotwired.dev/android/getting-started)
- [Path Configuration](https://native.hotwired.dev/ios/path-configuration)
- [Bridge Components](https://native.hotwired.dev/ios/bridge-components)

### GitHub Repositories
- [hotwired/hotwire-native-ios](https://github.com/hotwired/hotwire-native-ios) - iOS framework (v1.2.2)
- [hotwired/hotwire-native-android](https://github.com/hotwired/hotwire-native-android) - Android framework (v1.2.4)

### Learning Resources
- [37signals Announcement](https://dev.37signals.com/announcing-hotwire-native/)
- [Joe Masilotti's Roadmap](https://masilotti.com/turbo-native-app-roadmap/)
- [Turbo Native in 15 Minutes](https://masilotti.com/turbo-native-apps-in-15-minutes/)
- [Rails World 2025 Keynote](https://www.rubyevents.org/talks/keynote-hotwire-native-a-rails-developer-s-secret-tool-for-building-mobile-apps)
- [The Rails and Hotwire Codex](https://railsandhotwirecodex.com/)
- [Learn Hotwire Course](https://learnhotwire.com/)

### CalcuMake API Reference
See `/docs/API_DESIGN.md` for complete API specification (2,420 lines).

Key endpoints (also work in mobile WebView):
- Authentication: Cookie-based via Devise
- User: `GET/PATCH /api/v1/me`
- Calculations: `GET/POST/PATCH/DELETE /api/v1/print_pricings`
- Invoices: `GET/POST/PATCH/DELETE /api/v1/invoices`
- Resources: `/printers`, `/filaments`, `/resins`, `/clients`

---

*Document created: 2025-12-28*
*Last updated: 2025-12-28*
*Recommended approach: Hotwire Native*
