Rails.application.routes.draw do
  devise_scope :user do
    get 'signin', to: 'devise/sessions#new', as: :new_user_session
    get 'signup', to: 'devise/registrations#new', as: :new_user_registration
  end

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }, skip: [:sessions, :registrations]

  devise_scope :user do
    post 'signin', to: 'devise/sessions#create', as: :user_session
    delete 'logout', to: 'devise/sessions#destroy', as: :destroy_user_session
    post 'signup', to: 'devise/registrations#create', as: :user_registration
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "home#index"

  # Session routes (handled by Devise now)
  # post "login", to: "sessions#create"
  # delete "logout", to: "sessions#destroy"

  # User Dashboard
  resources :dashboard, only: [:index]

  # Exam Schedules
  resources :exam_schedules, only: [:index, :show] do
    collection do
      get :calendar
      get :my_schedules
      post :add_interest
      delete :remove_interest
    end
  end

  resources :study_sets do
    resources :study_materials do
      post 'upload', on: :member
      post 'process', to: 'study_materials#process_pdf', on: :member
    end
    resources :exams
    resources :exam_sessions, only: [:new, :create]
  end

  # Exam Sessions (non-nested routes)
  resources :exam_sessions, only: [:show, :update] do
    member do
      post :submit_answer
      post :complete
      post :abandon
      get :result
    end
  end

  # Test Questions
  resources :test_questions, only: [] do
    member do
      patch :mark
    end
  end

  # API routes (for future AJAX calls)
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      get 'auth/me', to: 'auth#me'

      # Study Sets
      resources :study_sets do
        resources :study_materials do
          post 'upload', on: :member
          get 'status', on: :member
        end
      end

      # Questions
      resources :questions, only: [:index, :show]

      # Exams
      resources :exams do
        post 'submit', on: :member
      end

      # Knowledge Graph (future)
      get 'knowledge_graph', to: 'knowledge_graph#show'
      get 'weak_points', to: 'weak_points#index'
    end
  end
end
