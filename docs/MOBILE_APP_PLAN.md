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

## Recommended Approach

### For CalcuMake: **Option 2 (Cross-Platform) with Flutter**

**Rationale:**
1. **Cost-effective**: ~50% of native development cost
2. **Fast to market**: 4-6 months vs 6-8 months
3. **Good enough performance**: Calculator and forms don't need native performance
4. **Single codebase**: Easier maintenance for a small team
5. **Strong ecosystem**: Stripe, Firebase, OAuth all have Flutter SDKs
6. **Material Design 3**: Excellent fit for a professional B2B app

---

## Implementation Plan

### Phase 0: Planning & Design (2 weeks)

#### Week 1: Design System
- [ ] Create Figma/Sketch mockups for all screens
- [ ] Define navigation structure (bottom tabs recommended)
- [ ] Design component library (buttons, cards, forms)
- [ ] Create dark mode variants
- [ ] Define touch targets and accessibility

#### Week 2: Technical Setup
- [ ] Set up Flutter project with clean architecture
- [ ] Configure CI/CD (GitHub Actions → App Store Connect / Play Console)
- [ ] Set up Firebase project (push, analytics, crashlytics)
- [ ] Create API client scaffold with token handling
- [ ] Configure code signing for both platforms

### Phase 1: API Enhancements (2-4 weeks)

#### Week 1-2: Core Enhancements
- [ ] Add push notification device token endpoints
  ```
  POST /api/v1/devices       # Register device token
  DELETE /api/v1/devices/:id # Unregister
  ```
- [ ] Add OAuth mobile flow (custom URL scheme callback)
- [ ] Add `X-RateLimit-*` response headers
- [ ] Create OpenAPI/Swagger documentation

#### Week 3-4: Extended Features
- [ ] Add file upload support (multipart form)
  ```
  POST /api/v1/me/logo      # Upload company logo
  ```
- [ ] Add subscription management endpoints
  ```
  GET /api/v1/subscription        # Current plan status
  POST /api/v1/subscription/portal # Stripe billing portal URL
  ```
- [ ] Add webhook endpoints for real-time updates (optional)

### Phase 2: Core App Development (8-10 weeks)

#### Weeks 1-2: Foundation
- [ ] Authentication flow
  - Email/password login
  - OAuth providers (Google, Apple, GitHub)
  - Secure token storage (Keychain/Keystore)
  - Biometric unlock (optional)
- [ ] API client with error handling
  - Automatic token refresh
  - Offline request queue
  - Error mapping to user-friendly messages

#### Weeks 3-4: Dashboard & Navigation
- [ ] Bottom tab navigation
  - Home (dashboard)
  - New Calculation
  - Invoices
  - Settings
- [ ] Dashboard screen
  - Usage stats cards
  - Recent calculations
  - Quick actions
- [ ] Pull-to-refresh pattern

#### Weeks 5-6: Print Pricing (Core Feature)
- [ ] Calculation list with search/filter
- [ ] New calculation wizard
  - Printer selection
  - Plate management (add/remove 1-10)
  - Filament selection (multi-select 1-16)
  - Time input (hours/minutes)
  - Cost parameters
- [ ] Real-time cost calculation
- [ ] Calculation detail view
- [ ] Edit and duplicate functionality

#### Weeks 7-8: Invoice Management
- [ ] Invoice list with status filters
- [ ] Create invoice from calculation
  - Auto-generate line items
  - Client selection
  - Tax percentage
- [ ] Invoice detail view
- [ ] Status transitions (draft → sent → paid)
- [ ] Manual line item editing

#### Weeks 9-10: Settings & Resources
- [ ] User profile management
- [ ] Printer CRUD
- [ ] Filament/Resin CRUD
- [ ] Client CRUD
- [ ] Language/currency preferences
- [ ] API token management
- [ ] Subscription status & upgrade

### Phase 3: Advanced Features (2-3 weeks)

#### Week 1: Offline Support
- [ ] Local SQLite database (drift or sqflite)
- [ ] Offline queue for writes
- [ ] Sync on connectivity restore
- [ ] Conflict resolution (server wins)
- [ ] Cache invalidation strategy

#### Week 2: Push Notifications
- [ ] Firebase Cloud Messaging setup
- [ ] Device token registration
- [ ] Notification handlers (foreground/background)
- [ ] Deep linking from notifications
- [ ] Notification preferences

#### Week 3: Export Features
- [ ] PDF generation for invoices
- [ ] Share sheet integration
- [ ] CSV export for calculations
- [ ] Email invoice directly

### Phase 4: Testing & Polish (3-4 weeks)

#### Week 1: Testing
- [ ] Unit tests (business logic)
- [ ] Widget tests (UI components)
- [ ] Integration tests (API flows)
- [ ] E2E tests (critical paths)
- [ ] Performance profiling

#### Week 2: Accessibility & Localization
- [ ] Screen reader support
- [ ] Dynamic type sizing
- [ ] RTL layout for Arabic
- [ ] All 7 languages integrated
- [ ] Date/number/currency formatting

#### Week 3-4: Launch Preparation
- [ ] App Store screenshots & metadata
- [ ] Play Store listing
- [ ] Privacy policy updates
- [ ] Beta testing (TestFlight / Play Console Beta)
- [ ] Final QA pass
- [ ] Submit for review

---

## App Architecture

### Screen Structure

```
├── Auth
│   ├── Login (email + OAuth)
│   ├── Register
│   ├── Forgot Password
│   └── Email Verification
│
├── Main (Bottom Tabs)
│   ├── Dashboard
│   │   ├── Usage Stats
│   │   ├── Recent Calculations
│   │   └── Quick Actions
│   │
│   ├── Calculations
│   │   ├── List (search, filter)
│   │   ├── New/Edit Wizard
│   │   └── Detail View
│   │
│   ├── Invoices
│   │   ├── List (status filter)
│   │   ├── New from Calculation
│   │   └── Detail + Line Items
│   │
│   └── Settings
│       ├── Profile
│       ├── Printers
│       ├── Filaments
│       ├── Resins
│       ├── Clients
│       ├── API Tokens
│       ├── Language/Currency
│       ├── Subscription
│       └── About/Legal
```

### Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter   │────▶│  API Layer  │────▶│  CalcuMake  │
│     App     │◀────│  (REST/v1)  │◀────│   Backend   │
└─────────────┘     └─────────────┘     └─────────────┘
       │                                       │
       ▼                                       ▼
┌─────────────┐                         ┌─────────────┐
│  Local DB   │                         │  PostgreSQL │
│  (SQLite)   │                         │             │
└─────────────┘                         └─────────────┘
       │
       ▼
┌─────────────┐
│ Sync Queue  │
│  (Offline)  │
└─────────────┘
```

### Authentication Flow

```
┌──────────────────────────────────────────────────────────┐
│                    Mobile App                            │
└──────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │  Email/  │   │  OAuth   │   │ Biometric│
    │ Password │   │ (Google, │   │  Unlock  │
    │          │   │  Apple)  │   │          │
    └──────────┘   └──────────┘   └──────────┘
          │               │               │
          ▼               ▼               │
    ┌──────────────────────────┐          │
    │    POST /api/v1/login    │          │
    │    (returns API token)   │          │
    └──────────────────────────┘          │
                    │                     │
                    ▼                     │
            ┌──────────────┐              │
            │ Secure Store │◀─────────────┘
            │ (Keychain/   │
            │  Keystore)   │
            └──────────────┘
                    │
                    ▼
         ┌─────────────────────┐
         │ Bearer Token Header │
         │ All API Requests    │
         └─────────────────────┘
```

---

## Resource Requirements

### Team Structure (Recommended)

| Role | Count | Duration | Notes |
|------|-------|----------|-------|
| Flutter Developer (Lead) | 1 | 4-6 months | Architecture, core features |
| Flutter Developer | 1 | 3-5 months | Features, testing |
| Backend Developer | 0.5 | 2-4 weeks | API enhancements |
| UI/UX Designer | 0.25 | 2-4 weeks | Design system, screens |
| QA Engineer | 0.5 | 4-6 weeks | Testing phase |
| Product Manager | 0.25 | Throughout | Requirements, prioritization |

### Infrastructure Needs

| Service | Purpose | Est. Monthly Cost |
|---------|---------|-------------------|
| Firebase | Push, Analytics, Crashlytics | Free tier / ¥3,000 |
| Apple Developer | App Store publishing | ¥12,000/year |
| Google Play Console | Play Store publishing | ¥2,500 one-time |
| CI/CD (GitHub Actions) | Build & deploy | Existing / Free |
| TestFlight | iOS beta testing | Free (with Apple Dev) |

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

## Decision Points for User

Before proceeding, we need your input on:

1. **Development Approach**
   - [ ] Native (separate iOS + Android)
   - [ ] Cross-platform (Flutter recommended)
   - [ ] PWA + Capacitor (fastest/cheapest)

2. **Feature Priority**
   - [ ] All features at launch (longer timeline)
   - [ ] MVP first, iterate (faster launch)

3. **Offline Support**
   - [ ] Required (adds 2-3 weeks)
   - [ ] Nice-to-have (defer)

4. **Push Notifications**
   - [ ] Required for launch
   - [ ] Post-launch feature

5. **In-App Purchases**
   - [ ] Use App Store/Play Store billing
   - [ ] Redirect to web for Stripe (simpler)

6. **Timeline Preference**
   - [ ] Fast launch (MVP in 3-4 months)
   - [ ] Full feature (complete in 5-6 months)

---

## Next Steps

1. **Review this plan** and provide feedback
2. **Answer decision points** above
3. **Create design mockups** (Figma recommended)
4. **Begin API enhancements** (can start immediately)
5. **Set up Flutter project** once approach confirmed
6. **Hire/assign developers** if needed

---

## Appendix: API Documentation Reference

See `/docs/API_DESIGN.md` for complete API specification (2,420 lines).

Key endpoints for mobile:
- Authentication: Token-based via `POST /api/v1/api_tokens`
- User: `GET/PATCH /api/v1/me`
- Calculations: `GET/POST/PATCH/DELETE /api/v1/print_pricings`
- Invoices: `GET/POST/PATCH/DELETE /api/v1/invoices`
- Resources: `/printers`, `/filaments`, `/resins`, `/clients`

---

*Document created: 2025-12-27*
*Last updated: 2025-12-27*
