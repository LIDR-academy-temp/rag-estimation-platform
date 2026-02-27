Rails.application.routes.draw do
  root "pages#landing"

  # Auth
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "register", to: "registrations#new"
  post "register", to: "registrations#create"

  # App
  get "dashboard", to: "dashboard#index"

  get "ingest", to: "ingest#index"
  post "ingest", to: "ingest#create"

  get "estimate", to: "estimates#index"
  get "estimates/new", to: "estimates#new", as: :new_estimate
  post "estimates", to: "estimates#create", as: :estimates
  get "estimates/:id", to: "estimates#show", as: :estimate_detail
  post "estimates/:id/retry", to: "estimates#retry_estimation", as: :retry_estimate
  patch "estimates/:id/structure", to: "estimates#update_structure", as: :update_estimate_structure
  patch "estimates/:id/estimation", to: "estimates#update_estimation", as: :update_estimate_estimation

  get "search", to: "searches#index"

  get "estimaciones", to: "estimations#index", as: :estimations
  get "estimaciones/:id/edit", to: "estimations#edit", as: :edit_estimation
  patch "estimaciones/:id", to: "estimations#update", as: :estimation_update
  delete "estimaciones/:id", to: "estimations#destroy", as: :estimation_destroy

  resources :documents, only: [:index, :show, :destroy]

  # Health
  get "up" => "rails/health#show", as: :rails_health_check
end
