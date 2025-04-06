Rails.application.routes.draw do
  devise_for :users
  resources :posts, only: [:index, :new, :create, :show]
  
  root 'posts#index'
end
