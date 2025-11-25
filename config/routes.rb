Rails.application.routes.draw do
  # GDPR Compliance routes
  resources :user_consents, only: [ :create ]
  get "cookie-policy", to: "privacy#cookie_policy", as: :cookie_policy
  get "terms-of-service", to: "privacy#terms_of_service", as: :terms_of_service
  get "data-export", to: "privacy#data_export", as: :data_export
  post "data-deletion", to: "privacy#data_deletion", as: :data_deletion
  get "data-deletion", to: "privacy#data_deletion"
  resources :clients
  resources :filaments do
    member do
      post :duplicate
    end
  end
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  # OAuth profile completion (for providers that don't provide email)
  namespace :users do
    namespace :omniauth do
      get "complete_profile", to: "complete_profile#show", as: :complete_profile
      post "complete_profile", to: "complete_profile#create"
    end
  end

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

  # Standalone invoices route for global invoice management
  resources :invoices, only: [ :index ]

  resources :printers

  resource :user_profile, only: [ :show, :edit, :update, :destroy ], path: "profile"

  # Subscription management
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

  # Stripe webhooks
  post "webhooks/stripe", to: "webhooks/stripe#create"

  # Legal pages
  get "privacy-policy", to: "legal#privacy_policy", as: :privacy_policy
  get "user-agreement", to: "legal#user_agreement", as: :user_agreement
  get "support", to: "legal#support", as: :support
  get "commerce-disclosure", to: "legal#commerce_disclosure", as: :commerce_disclosure

  # Locale switching
  post "switch_locale", to: "application#switch_locale"

  # Landing page and pricing calculator
  get "landing", to: "pages#landing", as: :landing
  get "3d-print-pricing-calculator", to: "pages#pricing_calculator", as: :pricing_calculator

  # Blog routes with locale support
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get "blog", to: "articles#index", as: :blog
    get "blog/:slug", to: "articles#show", as: :article
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "pages#landing"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
