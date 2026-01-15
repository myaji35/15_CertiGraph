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

  # User Dashboard (Epic 15)
  resources :dashboard, only: [:index] do
    collection do
      get :statistics
      get :progress
      get :learning_patterns
      get :achievements
      get :recent_activity
    end
  end

  # Payment routes (Epic 16)
  resources :payments, only: [:index, :show] do
    collection do
      get :checkout
      post :request, to: 'payments#request_payment'
      post :confirm
      get :success
      get :fail
      get :history
      get 'subscription/status', to: 'payments#subscription_status'
      get 'subscription/manage', to: 'payments#manage_subscription'
      post 'subscription/upgrade', to: 'payments#upgrade_subscription'
    end
    member do
      post :cancel
      post :refund
      post :retry, to: 'payments#retry_payment'
    end
  end

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

  # Certification Information Hub (Epic 18)
  resources :certifications, only: [:index, :show] do
    member do
      get :exam_schedules
      get :upcoming_exams
    end
    collection do
      post :sync
      get :search
    end
  end

  resources :exam_schedules, only: [:index, :show] do
    member do
      post :register_notification
    end
    collection do
      get :upcoming
      get :open_registrations
      get 'calendar/:year/:month', to: 'exam_schedules#calendar'
      get :years
    end
  end

  # Test Questions
  resources :test_questions, only: [] do
    member do
      patch :mark
    end
  end

  # Knowledge Map Visualization (Epic 14)
  resources :knowledge_map, only: [] do
    member do
      get '', to: 'knowledge_visualization#show', as: ''
    end
  end

  # Smart Recommendations (Epic 13)
  resources :recommendations, only: [:index, :show] do
    collection do
      post :generate
      get :learning_path
      get :personalized
      get :similar_users
      get :trending
      get :next_steps
      post :batch_generate
    end
    member do
      post :accept
      post :complete
      post :dismiss
    end
  end

  # API routes (for future AJAX calls)
  namespace :api do
    # Knowledge Visualization API
    get 'knowledge_visualization/:id/graph_data', to: 'knowledge_visualization#graph_data'
    get 'knowledge_visualization/:id/nodes/:node_id', to: 'knowledge_visualization#node_detail'
    get 'knowledge_visualization/:id/statistics', to: 'knowledge_visualization#statistics'
    post 'knowledge_visualization/:id/filter', to: 'knowledge_visualization#filter_nodes'

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

      # Knowledge Graph
      resources :study_sets do
        resources :study_materials do
          resources :knowledge_graphs, only: [:show] do
            collection do
              get :nodes
              get :edges
              get :statistics
              get :analysis
              get :concept_map
              get :learning_strategy
              post :build
            end
          end
        end
      end

      # Knowledge Nodes
      resources :knowledge_nodes, only: [:show] do
        member do
          get :prerequisites
          get :dependents
        end
      end

      # User Masteries
      resources :knowledge_nodes do
        resources :masteries, controller: 'user_masteries', only: [:show, :update]
      end

      get 'study_materials/:study_material_id/masteries', to: 'user_masteries#study_material_masteries'
      get 'masteries/by_status/:status', to: 'user_masteries#by_status'
      get 'masteries/weak_areas', to: 'user_masteries#weak_areas'
      get 'masteries/strong_areas', to: 'user_masteries#strong_areas'
      get 'masteries/statistics', to: 'user_masteries#statistics'

      # Legacy routes (for backward compatibility)
      get 'knowledge_graph', to: 'knowledge_graphs#show'
      get 'weak_points', to: 'user_masteries#weak_areas'

      # PDF Processing (Epic 3)
      resources :pdf_processing, only: [:create, :show, :index] do
        member do
          post :retry
          delete :cancel
        end
        collection do
          get :stats
        end
      end

      # Knowledge Graph (Epic 6)
      resources :study_materials, only: [] do
        resource :knowledge_graph, only: [:show], controller: 'knowledge_graph' do
          post :build
          get :stats
          get :nodes
          get 'nodes/:node_id', to: 'knowledge_graph#node_detail', as: :node_detail
          get :learning_path
          post :extract_from_question
          get :weak_concepts
          get :mastered_concepts
        end
      end

      # Weakness Analysis (Epic 12)
      resources :study_materials, only: [] do
        resource :weakness_analysis, only: [], controller: 'weakness_analysis' do
          post :analyze
          post :analyze_error
          get :weak_concepts
          post :generate_learning_path
          get :error_patterns
          get :recommendations
          get :history
        end
      end

      get 'weakness_analysis/user_overall_analysis', to: 'weakness_analysis#user_overall_analysis'
    end
  end
end
