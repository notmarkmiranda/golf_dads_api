Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  mount_avo
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # API routes
  namespace :api do
    post 'auth/signup', to: 'auth#signup'
    post 'auth/login', to: 'auth#login'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path returns API status
  root to: proc { [200, { 'Content-Type' => 'application/json' }, [{ status: 'ok', message: 'Golf Dads API is running' }.to_json]] }
end
