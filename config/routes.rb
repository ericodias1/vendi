Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # Registration
  get "signup", to: "registrations#new", as: :signup
  post "signup", to: "registrations#create", as: :registration

  # Password Reset
  get "forgot-password", to: "password_resets#new", as: :forgot_password
  post "password-resets", to: "password_resets#create", as: :password_resets
  get "password-resets/:token/edit", to: "password_resets#edit", as: :edit_password_reset
  patch "password-resets/:token", to: "password_resets#update", as: :password_reset

  # Backoffice
  namespace :backoffice do
    root "dashboard#index"

    resource :account_config, only: [:show, :edit, :update]

    resources :products, except: [] do
      resource :stock_adjustment, only: %i[edit update], controller: "products/stock_adjustments"
      collection do
        get :low_stock
      end
    end
    resources :sales, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  end

  # Defines the root path route ("/")
  root "backoffice/dashboard#index"
end
