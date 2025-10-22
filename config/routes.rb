Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  devise_for :users

  resources :print_pricings do
    member do
      patch :increment_times_printed
      patch :decrement_times_printed
      get :invoice
    end
    resources :invoices do
      member do
        patch :mark_as_sent
        patch :mark_as_paid
        patch :mark_as_cancelled
      end
    end
  end
  resources :printers

  resource :user_profile, only: [ :show, :edit, :update ], path: "profile"

  # Legal pages
  get "privacy-policy", to: "legal#privacy_policy", as: :privacy_policy
  get "user-agreement", to: "legal#user_agreement", as: :user_agreement
  get "support", to: "legal#support", as: :support

  # Locale switching
  post "switch_locale", to: "application#switch_locale"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "print_pricings#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
