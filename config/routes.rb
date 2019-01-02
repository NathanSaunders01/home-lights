Rails.application.routes.draw do
  devise_for :owners
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  devise_scope :owner do
    authenticated :owner do
      root 'home#index', as: :authenticated_root
    end
  
    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
  
  get "/home", to: "home#index"
  get '/callback', to: "home#auth"
  post "change_light_state", to: "home#change_light_state"
  post "toggle_light", to: "home#toggle_light"
  
  
end
