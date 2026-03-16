Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  get "health", to: proc { [200, {}, ["OK"]] }

  # API routes
  namespace :api do
    namespace :v1 do
      # Players
      post "players/register", to: "players#register"
      post "players/upload_csv", to: "players#upload_csv"
      get "players", to: "players#index"
      get "players/:nickname", to: "players#show"
      
      # Distributions
      post "distributions/run", to: "distributions#run"
      get "distributions/latest", to: "distributions#latest"
      
      # Configs
      get "configs", to: "configs#index"
      get "configs/:key", to: "configs#show"
      put "configs/:key", to: "configs#update"
      
      # Building troop types (обновленные маршруты)
      get "building_troop_types", to: "building_troop_types#index"
      get "building_troop_types/slot/:slot", to: "building_troop_types#by_slot"
      get "building_troop_types/:slot/:building", to: "building_troop_types#show"
      put "building_troop_types/:slot/:building", to: "building_troop_types#update"
    end
  end

  # Маршруты с поддержкой локали
  scope "(:locale)", locale: /en|ru|ko|ja/ do
    root "pages#index"
    get "register", to: "pages#register"
    get "admin", to: "pages#admin"
    get "results", to: "pages#results"
get "instructions", to: "pages#instructions", as: :instructions
  end
end