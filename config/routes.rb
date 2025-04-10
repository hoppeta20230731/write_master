Rails.application.routes.draw do
  devise_for :users
  resources :posts

  post '/auth/slack', as: :slack_login
  get '/auth/slack/callback', to: 'slack_authentications#create'
  
  root 'posts#index'
end
