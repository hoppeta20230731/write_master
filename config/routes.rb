Rails.application.routes.draw do
  get 'calendar/show'
  devise_for :users
  resources :posts do
    member do
      post :generate_ai_feedback
    end
  end

  post '/auth/slack', as: :slack_login
  get '/auth/slack/callback', to: 'slack_authentications#create'

  root 'posts#index'

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
