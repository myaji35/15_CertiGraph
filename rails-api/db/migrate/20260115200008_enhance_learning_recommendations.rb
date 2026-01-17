# db/migrate/20260115200001_enhance_learning_recommendations.rb
class EnhanceLearningRecommendations < ActiveRecord::Migration[7.2]
  def change
    # Create recommendation_feedbacks table for tracking user interactions
    create_table :recommendation_feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :learning_recommendation, null: false, foreign_key: true
      t.string :feedback_type, null: false # clicked, completed, dismissed, rated
      t.integer :rating # 1-5
      t.text :comment
      t.float :time_spent_seconds
      t.boolean :was_helpful
      t.json :interaction_metadata
      t.timestamps
    end

    # Create recommendation_metrics table for tracking performance
    create_table :recommendation_metrics do |t|
      t.references :learning_recommendation, null: false, foreign_key: true
      t.date :metric_date, null: false
      t.integer :impressions, default: 0
      t.integer :clicks, default: 0
      t.integer :completions, default: 0
      t.integer :dismissals, default: 0
      t.float :ctr # Click-through rate
      t.float :completion_rate
      t.float :avg_rating
      t.float :avg_time_spent
      t.json :performance_data
      t.timestamps
    end

    # Create user_similarity_scores table for collaborative filtering
    create_table :user_similarity_scores do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :similar_user_id, null: false
      t.float :similarity_score, null: false
      t.string :similarity_type # cosine, pearson, jaccard
      t.integer :common_concepts_count
      t.json :similarity_breakdown
      t.datetime :calculated_at
      t.timestamps
    end

    # Create recommendation_ab_tests table for A/B testing
    create_table :recommendation_ab_tests do |t|
      t.string :test_name, null: false
      t.string :variant_name, null: false # control, variant_a, variant_b
      t.references :user, null: false, foreign_key: true
      t.references :learning_recommendation, foreign_key: true
      t.string :status, default: 'active' # active, completed, cancelled
      t.json :variant_config
      t.json :result_metrics
      t.datetime :started_at
      t.datetime :ended_at
      t.timestamps
    end

    # Add indexes for performance
    add_index :recommendation_feedbacks, [:user_id, :feedback_type]
    add_index :recommendation_feedbacks, :created_at
    add_index :recommendation_metrics, [:metric_date, :learning_recommendation_id],
              name: 'idx_metrics_date_recommendation'
    add_index :user_similarity_scores, [:user_id, :similar_user_id], unique: true
    add_index :user_similarity_scores, [:similarity_score], order: { similarity_score: :desc }
    add_index :recommendation_ab_tests, [:test_name, :variant_name]
    add_index :recommendation_ab_tests, [:user_id, :status]

    # Add new columns to learning_recommendations for enhanced tracking
    add_column :learning_recommendations, :recommendation_algorithm, :string # cf, cb, hybrid
    add_column :learning_recommendations, :algorithm_version, :string
    add_column :learning_recommendations, :confidence_level, :float, default: 0.0
    add_column :learning_recommendations, :diversity_score, :float, default: 0.0
    add_column :learning_recommendations, :novelty_score, :float, default: 0.0
    add_column :learning_recommendations, :explanation_text, :text
    add_column :learning_recommendations, :similar_users_count, :integer, default: 0
    add_column :learning_recommendations, :cf_score, :float # collaborative filtering score
    add_column :learning_recommendations, :cb_score, :float # content-based score
    add_column :learning_recommendations, :hybrid_weight_cf, :float, default: 0.8
    add_column :learning_recommendations, :hybrid_weight_cb, :float, default: 0.2
    add_column :learning_recommendations, :impressions_count, :integer, default: 0
    add_column :learning_recommendations, :clicks_count, :integer, default: 0

    # Add indexes for new columns
    add_index :learning_recommendations, :recommendation_algorithm
    add_index :learning_recommendations, :confidence_level
    add_index :learning_recommendations, [:impressions_count, :clicks_count]

    # Add foreign key for similar_user_id in user_similarity_scores
    add_foreign_key :user_similarity_scores, :users, column: :similar_user_id
  end
end
