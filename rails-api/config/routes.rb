Rails.application.routes.draw do
  devise_scope :user do
    get 'signin', to: 'users/sessions#new', as: :new_user_session
    get 'login', to: 'users/sessions#new'  # Alias for signin
    get 'signup', to: 'users/registrations#new', as: :new_user_registration
  end

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations'
  }, skip: [:sessions, :registrations]

  devise_scope :user do
    post 'signin', to: 'users/sessions#create', as: :user_session
    delete 'logout', to: 'users/sessions#destroy', as: :destroy_user_session
    post 'signup', to: 'users/registrations#create', as: :user_registration

    # Email Verification routes
    get 'verify-email', to: 'users/confirmations#verify', as: :verify_email
    post 'users/confirmation/resend', to: 'users/confirmations#resend', as: :resend_confirmation

    # Two-Factor Authentication routes
    post 'users/two_factor/verify_login', to: 'users/sessions#verify_two_factor', as: :verify_two_factor_login
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

  # User Management Routes (Epic 1: User Authentication)
  namespace :users do
    # Two-Factor Authentication
    resource :two_factor, only: [], controller: 'two_factor' do
      get :status
      post :setup
      post :enable
      post :verify
      delete :disable
      post 'backup_codes/regenerate', to: 'two_factor#regenerate_backup_codes'
      get :backup_codes
    end

    # Profile Management
    resource :profile, only: [:show, :update], controller: 'profile' do
      post :upload_avatar
      delete :delete_avatar
      get :login_history
      patch :update_preferences
      patch :update_notification_settings
      patch :update_password
      post :deactivate_account
      post :reactivate_account
      post :request_deletion
      delete :cancel_deletion
    end

    # Session Management
    resource :sessions, only: [], controller: 'sessions' do
      get :active_sessions, on: :collection
      delete :revoke_all_sessions, on: :collection
    end
  end

  # User Dashboard (Epic 15)
  resources :dashboard, only: [:index] do
    collection do
      get :statistics
      get :progress
      get :learning_patterns
      get :achievements
      get :recent_activity
      get :charts
      get :comparison
      get :predictions
      get :realtime_status
      post :export
      get :filter
      post :set_goal, path: 'goal'
      get :notifications
      get :profile
    end
  end

  # Dashboard Widgets (Epic 15)
  resources :widgets do
    member do
      post :toggle_visibility
      post :reset
    end
    collection do
      post :batch_update
      post :reorder
      get :presets
      post :apply_preset
      get 'data/:id', to: 'widgets#widget_data', as: :widget_data
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

  # Exam Schedules (Epic 18) - Consolidated routes
  resources :exam_schedules, only: [:index, :show] do
    member do
      post :register_notification
    end
    collection do
      get :upcoming
      get :open_registrations
      get :years
      get 'calendar/:year/:month', to: 'exam_schedules#calendar', as: :monthly_calendar
      get :my_schedules
      post :add_interest
      delete :remove_interest
    end
  end

  # Standalone study_materials upload route (Epic 2 Test Compatibility)
  get '/study-materials/upload', to: 'study_materials#upload_form', as: :upload_study_materials

  resources :study_sets do
    # Knowledge Analysis
    resource :knowledge_analysis, only: [:show], controller: 'knowledge_analysis'
    
    # Questions collection route
    resources :questions, only: [:index]
    
    # Epic 2: Enhanced Upload Routes
    resources :uploads, only: [] do
      collection do
        post :prepare
        post :validate, to: 'uploads#validate_file'
        get :storage_stats
        post :cleanup_storage
      end
      member do
        post :complete
        post :upload_chunk
        post :complete_multipart
        get :upload_status
        post :pause_upload
        post :resume_upload
        delete :cancel_upload
      end
    end

    resources :study_materials do
      post 'upload', on: :member
      post 'process', to: 'study_materials#process_pdf', on: :member
      member do
        post :reprocess
        post :extract_concepts
        get :processing_status
        get :export
      end
      
      # Knowledge Graph Visualization (Web UI)
      resources :knowledge_graphs, only: [:show]
      
      resources :questions do
        member do
          post :validate_question
          post :add_passage
          delete 'remove_passage/:passage_id', to: 'questions#remove_passage'
        end
        collection do
          post :batch_create
          post :extract
          post :validate_all
          get :stats
        end
      end
      resources :passages, only: [:index, :show, :create, :update, :destroy]
    end
    resources :exams
    resources :exam_sessions, only: [:new, :create]
  end

  # Standalone Exam Routes (for test compatibility)
  resources :exams, only: [:index, :show, :new, :create] do
    collection do
      # get :create, to: 'exams#new', as: :new_form  # Not needed - :new already generates /exams/new
    end
    member do
      post :start
      get :result
      post :retake
    end
  end

  # Wrong Answers / Odasnote
  resources :wrong_answers do
    member do
      post :mark_reviewed
      post :add_tag
      delete :remove_tag
    end
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
      get :years
    end
    collection do
      post :sync
      get :search
      get :upcoming
      get :open_registrations
    end
  end

  # Marketplace (Epic 17)
  resources :marketplace, only: [:index, :show] do
    collection do
      get :search
      get :facets
      get :popular
      get :top_rated
      get :recent
      get :categories
      get :my_materials
      get :purchased
      get :stats
    end
    member do
      post :purchase
      post :toggle_publish
      patch :update_listing
      get :download
    end
  end

  # Reviews (Epic 17)
  resources :reviews, only: [:show, :update, :destroy] do
    member do
      post :vote
      delete :remove_vote
    end
    collection do
      get :my_reviews
    end
  end

  resources :study_materials, only: [] do
    resources :reviews, only: [:index, :create]
  end


  # Questions (standalone routes)
  resources :questions, only: [:show] do
    collection do
      get :search
      get 'by_material/:material_id', to: 'questions#by_material', as: :by_material
    end
  end

  # Test Sessions (CBT Mode - Epic 9)
  resources :test_sessions, only: [:show, :update] do
    member do
      post :pause
      post :resume
      post :auto_save
      post :complete
      post :abandon
      post :submit_answer
      get :statistics
      get :navigation_grid
      post :jump_to_question
      post :next_unanswered
      post :keyboard_shortcut
      get :result
    end

    # Bookmarks for test sessions
    resources :bookmarks, only: [:index, :create, :show, :update, :destroy] do
      collection do
        post :toggle
        get :summary
        post :batch_create
        delete :batch_destroy
      end
    end
  end

  # User bookmarks (all test sessions)
  get 'users/:user_id/bookmarks', to: 'bookmarks#all_user_bookmarks'

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
      # Original endpoints
      post :generate
      get :learning_path
      get :personalized
      get :similar_users
      get :trending
      get :next_steps
      post :batch_generate

      # Algorithm-specific generation
      post :cf_generate
      post :cb_generate
      post :hybrid_generate
      post :ensemble_generate
      post :adaptive_generate

      # Learning path optimization
      get :optimal_path
      get :prioritized_concepts
      post :study_schedule
      get :next_concept

      # Metrics and analytics
      get :top_performing
      get :algorithm_comparison
      get :user_engagement
      get :daily_report

      # User similarity
      get :similarity_scores
      post :calculate_similarities

      # Async processing
      post :batch_generate_async
    end
    member do
      # Original member routes
      post :accept
      post :complete
      post :dismiss

      # Tracking and metrics
      post :track_impression
      post :track_click
      post :track_completion
      post :track_dismissal
      post :rate
      get :metrics
    end
  end

  # Epic 5: Tags and Content Structuring
  resources :tags do
    collection do
      get :popular
      get :contexts
      get :search
      post :apply
      delete :remove
      post :auto_tag
      post :merge
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
      # Epic 5: Tags API
      resources :tags do
        collection do
          get :popular
          get :contexts
          get :search
          post :apply
          delete :remove
          post :auto_tag
          post :merge
        end
      end

      # Content Structuring API
      resources :study_materials, only: [] do
        member do
          post :classify
          post :extract_metadata
          post :structure_content
          get :content_metadata
        end
      end
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

      # Knowledge Graph (Stage 3 - Direct API access)
      resources :knowledge_graphs, only: [:show] do
        member do
          get :nodes
          get :edges
          get :statistics
          get :weak_concepts
          get :learning_path
          post :analyze_weakness
        end
      end

      # Knowledge Graph (Nested under study materials - legacy)
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

      # A/B Testing (Epic 12 - Enhanced)
      resources :ab_tests do
        member do
          post :start
          post :pause
          post :complete
          get :results
          post :assign_variant
          post :track_event
          get :early_stopping_check
          get :report
        end
        collection do
          get :templates
        end
      end

      # ML Models (Epic 12 - Enhanced)
      resources :ml_models do
        member do
          post :train
          post :deploy
          post :predict
          post :validate
          get :metrics
          post :create_version
        end
      end

      # Weakness Reports (Epic 12 - Enhanced)
      resources :weakness_reports, only: [:index, :show, :create] do
        member do
          post :generate_pdf
          get :download_pdf
        end
      end

      # Enhanced Learning Recommendations (Epic 12)
      resources :study_materials, only: [] do
        resource :enhanced_recommendations, only: [], controller: 'enhanced_recommendations' do
          post :generate
          get :learning_paths
          get :optimal_sequence
          get :spaced_repetition_schedule
          get :practice_questions
          get :review_schedule
          get :personalization
        end
      end

      # ML Pattern Detection (Epic 12)
      get 'ml_patterns/detect', to: 'ml_patterns#detect'
      get 'ml_patterns/cluster_errors', to: 'ml_patterns#cluster_errors'
      get 'ml_patterns/classify_errors', to: 'ml_patterns#classify_errors'
      get 'ml_patterns/time_series', to: 'ml_patterns#time_series'
      get 'ml_patterns/anomalies', to: 'ml_patterns#anomalies'
      get 'ml_patterns/predictions', to: 'ml_patterns#predictions'

      # Cheat Sheet Generator (Pre-Exam Summary)
      resources :study_sets, only: [] do
        member do
          get 'cheat_sheet', to: 'cheat_sheet#show'
          get 'cheat_sheet/pdf', to: 'cheat_sheet#pdf'
        end
      end


      # Performance Tracking (Epic 11)
      resources :performance, only: [] do
        collection do
          get :comprehensive_report
          get :quick_summary
          get :subject_breakdown
          get :chapter_breakdown
          get :concept_analysis
          get :strengths_weaknesses
          get :time_analysis
          get :daily_patterns
          get :weekly_patterns
          get :time_of_day
          get :consistency
          get :predictions
          get :exam_score_prediction
          get :mastery_timeline
          get :goal_achievement
          get :risk_assessment
          get :snapshots
          get 'snapshot/:id', to: 'performance#snapshot', as: :snapshot
          post :generate_snapshot
          get :chart_data
          get :comparison
        end
      end

      # Concept Extraction (Epic 7)
      resources :study_materials, only: [] do
        resources :concepts, only: [:index, :create], controller: 'concepts' do
          collection do
            post :extract_all
            post :normalize_all
            get :cluster
            get :hierarchy
            get :gaps
            get :statistics
          end
        end
      end

      resources :concepts, only: [:show, :update, :destroy], controller: 'concepts' do
        member do
          get :synonyms
          post :add_synonym
          get :related
          get :questions
        end
        collection do
          post :search
          post :merge
        end
      end

      # Prerequisite Mapping (Epic 8)
      resources :prerequisites, only: [:destroy], controller: 'prerequisites'

      resources :study_materials, only: [] do
        resources :prerequisites, only: [], controller: 'prerequisites' do
          collection do
            post :analyze_all
            get :graph_data
            get :validate_graph
            post :fix_cycles
            post :batch_analyze
          end
        end

        resources :nodes, only: [], controller: 'prerequisites' do
          member do
            post :analyze, to: 'prerequisites#analyze_node'
            get :prerequisites, to: 'prerequisites#node_prerequisites'
            get :dependents, to: 'prerequisites#node_dependents'
            get :depth, to: 'prerequisites#calculate_depth'
            post :generate_paths, to: 'prerequisites#generate_paths'
          end
        end

        resources :paths, only: [:create], controller: 'prerequisites' do
          collection do
            post :create, to: 'prerequisites#create_path'
          end
        end
      end

      # Learning Paths
      resources :learning_paths, only: [:show], controller: 'prerequisites' do
        member do
          get '', to: 'prerequisites#show_path'
          patch :progress, to: 'prerequisites#update_path_progress'
          post :abandon, to: 'prerequisites#abandon_path'
          get :alternatives, to: 'prerequisites#path_alternatives'
        end
      end

      get 'users/learning_paths', to: 'prerequisites#user_paths'

      # Randomization API (Epic 10)
      namespace :randomization do
        post 'randomize_question', to: 'randomization#randomize_question'
        post 'randomize_exam', to: 'randomization#randomize_exam'
        get 'session/:id', to: 'randomization#session_randomization'
        post 'restore', to: 'randomization#restore_order'
        post 'analyze/:study_material_id', to: 'randomization#analyze'
        get 'report/:study_material_id', to: 'randomization#report'
        get 'stats/:study_material_id', to: 'randomization#stats'
        get 'question_stats/:study_material_id/:question_id', to: 'randomization#question_stats'
        post 'test_uniformity', to: 'randomization#test_uniformity'
        put 'toggle/:exam_session_id', to: 'randomization#toggle_randomization'
        put 'set_strategy/:exam_session_id', to: 'randomization#set_strategy'
        post 'analyze_job/:study_material_id', to: 'randomization#analyze_job'
      end
    end
  end

  # Randomization web routes (non-API)
  resources :randomization, only: [] do
    collection do
      post :randomize_question
      post :randomize_exam
      get 'session/:id', to: 'randomization#session_randomization'
      post :restore_order
      post 'analyze/:study_material_id', to: 'randomization#analyze', as: :analyze_material
      get 'report/:study_material_id', to: 'randomization#report', as: :report_material
      get 'stats/:study_material_id', to: 'randomization#stats', as: :stats_material
      get 'question_stats/:study_material_id/:question_id', to: 'randomization#question_stats', as: :question_stats
      post :test_uniformity
      put 'toggle/:exam_session_id', to: 'randomization#toggle_randomization', as: :toggle_session
      put 'set_strategy/:exam_session_id', to: 'randomization#set_strategy', as: :set_strategy_session
      post 'analyze_job/:study_material_id', to: 'randomization#analyze_job', as: :analyze_job_material
    end
  end
end
