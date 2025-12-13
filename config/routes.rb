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

      get 'users/me', to: 'users#me'
      patch 'users/me', to: 'users#update'

      resources :groups do
        member do
          post 'regenerate_code'
          get 'tee_time_postings'
          get 'members'
          post 'leave'
          delete 'members/:user_id', to: 'groups#remove_member', as: 'remove_member'
          post 'transfer_ownership'
          patch 'notification_settings', to: 'groups#update_notification_settings'
        end
        collection do
          post 'join_with_code'
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

      resources :golf_courses, only: [] do
        collection do
          get 'search'
          get 'nearby'
          post 'cache'
        end
      end

      resources :favorite_golf_courses, only: [:index, :create, :destroy]

      resources :device_tokens, only: [:create] do
        collection do
          delete ':token', to: 'device_tokens#destroy'
        end
      end

      resource :notification_preferences, only: [:show, :update]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path returns API status
  root to: proc { [200, { 'Content-Type' => 'application/json' }, [{ status: 'ok', message: 'Golf Dads API is running' }.to_json]] }
end
