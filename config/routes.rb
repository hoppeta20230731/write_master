Rails.application.routes.draw do
  get 'calendar/show'
  devise_for :users
  resources :posts do
    collection do
      get :dashboard
    end
    
    member do
      post :generate_ai_feedback
      get :feedback_status
    end
  end

  post '/auth/slack', as: :slack_login
  get '/auth/slack/callback', to: 'slack_authentications#create'

  root 'posts#index'

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
