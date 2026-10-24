Rails.application.routes.draw do
  # Rutas API v1 para recibir órdenes (sin auth por ahora)
  namespace :api do
    namespace :v1 do
      resources :orders, only: [:create]
    end
  end

  # Rutas web: Auth por sesión/cookies; solo para dashboard web
  get '/login',  to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  # Dashboard (vistas HTML, requiere login)
  resources :orders, only: %i[index show]
  root 'orders#index'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
