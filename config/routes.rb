Rails.application.routes.draw do
  # =============================================================================
  # API ROUTES - RESTful JSON API (v1)
  # =============================================================================
  # All API routes are versioned, JSON-only, and require Bearer token authentication
  # (except public endpoints: health, calculator)
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # Public endpoints (no authentication)
      get :health, to: "health#show"                      # Load balancer health check
      post :calculator, to: "calculator#create"           # Public pricing calculator

      # User endpoints
      resource :me, controller: "users", only: %i[show update] do
        get :export, action: :export_data                # GDPR data export
        get :usage, action: :usage_stats                 # Usage statistics
      end

      # API token management (for API access)
      resources :api_tokens, only: %i[index create destroy]

      # Print pricing calculations
      resources :print_pricings do
        member do
          post :duplicate
          patch :increment_times_printed
          patch :decrement_times_printed
        end
        resources :plates, shallow: true, only: %i[index show]
        resources :invoices, shallow: true do
          member do
            patch :mark_as_sent
            patch :mark_as_paid
            patch :mark_as_cancelled
          end
        end
      end

      # Resources
      resources :printers
      resources :filaments do
        member do
          post :duplicate
        end
      end
      resources :resins do
        member do
          post :duplicate
        end
      end
      resources :clients
      resources :printer_profiles, only: [ :index ]

      # Combined materials library (filaments + resins)
      resources :materials, only: [ :index ]

      # Invoices (top-level and nested)
      resources :invoices, only: [ :index ] do
        resources :line_items, controller: "invoice_line_items", shallow: true
      end
    end
  end

  # =============================================================================
  # WEB APPLICATION ROUTES
  # =============================================================================

  # ---------------------------------------------------------------------------
  # Authentication & User Management
  # ---------------------------------------------------------------------------
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # OAuth profile completion (for providers that don't provide email)
  namespace :users do
    namespace :omniauth do
      get "complete_profile", to: "complete_profile#show", as: :complete_profile
      post "complete_profile", to: "complete_profile#create"
    end
  end

  # User profile management
  resource :user_profile, only: [ :show, :edit, :update, :destroy ], path: "profile"

  # Onboarding walkthrough for new users
  resource :onboarding, only: [ :show, :update ], controller: "onboarding" do
    post :skip_step
    post :skip_walkthrough
    post :complete
  end

  # API Token management (Web UI for creating/managing tokens)
  resources :api_tokens, only: %i[index new create destroy]

  # Admin dashboard (requires admin: true)
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"

  # ---------------------------------------------------------------------------
  # Core Application Resources (Web UI)
  # ---------------------------------------------------------------------------

  # Print pricing calculations
  resources :print_pricings do
    member do
      patch :increment_times_printed
      patch :decrement_times_printed
      post :duplicate
    end
    resources :invoices do
      member do
        patch :mark_as_sent
        patch :mark_as_paid
        patch :mark_as_cancelled
      end
    end
  end

  # Invoices (standalone for global invoice list)
  resources :invoices, only: [ :index ]

  # Resources
  resources :printers
  resources :printer_profiles, only: [ :index ]
  resources :clients
  resources :filaments do
    member do
      post :duplicate
    end
  end
  resources :resins do
    member do
      post :duplicate
    end
  end

  # Combined materials library (filaments + resins)
  resources :materials, only: [ :index ]

  # ---------------------------------------------------------------------------
  # Subscription & Billing
  # ---------------------------------------------------------------------------
  resources :subscriptions, only: [] do
    collection do
      get :pricing
      post :create_checkout_session
      get :success
      get :manage
      get :confirm_upgrade
      post :upgrade
      post :downgrade
      post :cancel
    end
  end

  # Stripe webhooks (checkout.session.completed, customer.subscription.*, etc.)
  post "webhooks/stripe", to: "webhooks/stripe#create"

  # ---------------------------------------------------------------------------
  # GDPR & Privacy Compliance
  # ---------------------------------------------------------------------------
  resources :user_consents, only: [ :create ]
  get "cookie-policy", to: "privacy#cookie_policy", as: :cookie_policy
  get "terms-of-service", to: "privacy#terms_of_service", as: :terms_of_service
  get "data-export", to: "privacy#data_export", as: :data_export
  post "data-deletion", to: "privacy#data_deletion", as: :data_deletion  # POST to process
  get "data-deletion", to: "privacy#data_deletion"                     # GET for display form

  # ---------------------------------------------------------------------------
  # Legal Pages
  # ---------------------------------------------------------------------------
  get "privacy-policy", to: "legal#privacy_policy", as: :privacy_policy
  get "user-agreement", to: "legal#user_agreement", as: :user_agreement
  get "support", to: "legal#support", as: :support
  get "commerce-disclosure", to: "legal#commerce_disclosure", as: :commerce_disclosure
  get "api-documentation", to: "legal#api_documentation", as: :api_documentation

  # ---------------------------------------------------------------------------
  # Public Pages & Marketing
  # ---------------------------------------------------------------------------
  # Redirect /landing to root for SEO consolidation (avoid duplicate content)
  # Google Search Console flagged this as "Duplicate, Google chose different canonical"
  get "landing", to: redirect("/", status: 301), as: :landing
  get "dashboard", to: "pages#dashboard", as: :dashboard
  get "3d-print-pricing-calculator", to: "pages#pricing_calculator", as: :pricing_calculator

  # Blog routes with locale support
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get "blog", to: "articles#index", as: :blog
    get "blog/:slug", to: "articles#show", as: :article
  end

  # ---------------------------------------------------------------------------
  # Internationalization
  # ---------------------------------------------------------------------------
  post "switch_locale", to: "application#switch_locale"

  # ---------------------------------------------------------------------------
  # System Routes
  # ---------------------------------------------------------------------------
  root "pages#landing"

  # Health check for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA manifest and service worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
