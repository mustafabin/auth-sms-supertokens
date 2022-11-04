Rails.application.routes.draw do
  resources :supertokens
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "/all", to: "users#all" 
  get "/me", to: "users#me" 
  post "/login", to: "users#login" 
  post "/signup", to: "users#signup" 
  # Defines the root path route ("/")
  # root "articles#index"
end
