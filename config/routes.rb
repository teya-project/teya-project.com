Rails.application.routes.draw do
  root "websites#index"

  get "/add_domains", to: "websites#add_domains"
  post "/add_domains", to: "websites#create_domains"
  get "/update_all", to: "websites#update_all"
  get "/destroy_all", to: "websites#destroy_all"
  get "/load_demo", to: "websites#load_demo"
  get "/websites/:id/destroy", to: "websites#destroy"
  resources :websites
  get "/websites/:id/rkn_ignore", to: "websites#rkn_ignore"
  get "/websites/:id/whois_update", to: "websites#whois_update"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
