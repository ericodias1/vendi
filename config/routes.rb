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

    resource :onboarding, only: [:show], controller: "onboarding" do
      collection do
        post :complete_step_1
        post :complete_step_2
      end
    end

    resource :account_config, only: [:show, :edit, :update]

    resources :products, except: [] do
      resource :stock_adjustment, only: %i[edit update], controller: "products/stock_adjustments"
      collection do
        get :low_stock
        get :export_csv
        patch :update_view_mode
      end
    end
    resources :product_imports, only: [:index, :new, :create, :show, :update] do
      collection do
        post :calculate_prices
      end
      resource :pricing, only: [:show, :update], controller: "product_imports/automatic_pricing" do
        get :close
        post :apply
      end
      member do
        post :process_import
        post :revert
      end
    end
    resources :sales, only: [:index, :show, :new, :create, :destroy] do
      resources :items, only: [:create, :update, :destroy], controller: "sales/items"
      member do
        patch :complete
        post :send_payment_link
      end
      
      # Steps como nested resources
      resource :products, only: [:edit, :update], controller: "sales/products"
      resource :details, only: [:edit], controller: "sales/details" do
        member do
          put :update_payment
          put :update_discount
          put :update_customer
        end
      end
      resource :finalize, only: [:edit, :update], controller: "sales/finalize"
    end
    resources :customers, only: [:index, :create] do
      collection do
        get :search
      end
    end

    resources :reports, only: [:index] do
      collection do
        # Relatórios individuais
        get "daily_summary", to: "reports/daily_summary#show", as: :daily_summary
        get "top_profit", to: "reports/top_profit#show", as: :top_profit
        get "critical_stock", to: "reports/critical_stock#show", as: :critical_stock
        get "stagnant_products", to: "reports/stagnant_products#show", as: :stagnant_products
        get "replenishment_suggestion", to: "reports/replenishment_suggestion#show", as: :replenishment_suggestion
        get "sales_ranking", to: "reports/sales_ranking#show", as: :sales_ranking
      end

      # Rotas de exportação (preparar para futuro)
      # member do
      #   get :export_csv
      #   get :export_pdf
      #   post :send_email
      # end
    end

    resources :accounts do
      member do
        post :impersonate
      end

      collection do
        delete :stop_impersonation
      end
    end

    resources :users
  end

  # Defines the root path route ("/")
  root "backoffice/dashboard#index"
end
