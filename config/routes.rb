Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  mount_avo
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # API routes - v1
  namespace :api do
    namespace :v1 do
      post 'auth/signup', to: 'auth#signup'
      post 'auth/login', to: 'auth#login'
      post 'auth/google', to: 'auth#google'

      resources :groups do
        get 'invitations', to: 'group_invitations#index_for_group'
        post 'invitations', to: 'group_invitations#create'
      end

      resources :group_invitations, only: [:index, :show] do
        member do
          post 'accept'
          post 'reject'
        end
      end

      resources :tee_time_postings do
        collection do
          get 'my_postings'
        end
      end
      resources :reservations do
        collection do
          get 'my_reservations'
        end
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path returns API status
  root to: proc { [200, { 'Content-Type' => 'application/json' }, [{ status: 'ok', message: 'Golf Dads API is running' }.to_json]] }
end
