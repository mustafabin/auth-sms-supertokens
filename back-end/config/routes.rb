Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get "/all", to: "users#all" 
  get "/me", to: "users#me" 
  post "/login", to: "users#login" 
  post "/signup", to: "users#signup" 
  post "/text", to: "users#text" # get sms text
  get "/verify", to: "users#verify_sms" # valid the sms token
  # Defines the root path route ("/")
  # root "articles#index"
end
