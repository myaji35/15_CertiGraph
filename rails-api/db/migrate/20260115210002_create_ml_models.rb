class CreateMlModels < ActiveRecord::Migration[7.2]
  def change
    create_table :ml_models do |t|
      t.string :name, null: false
      t.string :model_type, null: false # 'pattern_classifier', 'error_predictor', 'time_series', 'anomaly_detector'
      t.text :description

      # Model details
      t.string :algorithm # 'random_forest', 'kmeans', 'isolation_forest', 'lstm', 'arima'
      t.string :version, null: false
      t.string :status, default: 'untrained' # untrained, training, trained, deployed, deprecated

      # Training data
      t.integer :training_samples_count, default: 0
      t.integer :validation_samples_count, default: 0
      t.integer :test_samples_count, default: 0

      # Model artifacts (stored as JSON for SQLite compatibility)
      t.json :model_parameters, default: {} # Hyperparameters
      t.json :model_weights, default: {} # Serialized model weights/state
      t.json :feature_importance, default: {}
      t.json :training_history, default: []

      # Performance metrics
      t.float :accuracy, default: 0.0
      t.float :precision, default: 0.0
      t.float :recall, default: 0.0
      t.float :f1_score, default: 0.0
      t.float :mae # Mean Absolute Error
      t.float :rmse # Root Mean Squared Error
      t.json :confusion_matrix, default: {}

      # Training configuration
      t.json :features, default: [] # List of features used
      t.json :target_variable
      t.json :preprocessing_config, default: {}

      # Deployment
      t.datetime :trained_at
      t.datetime :deployed_at
      t.datetime :last_used_at
      t.integer :prediction_count, default: 0

      # Versioning
      t.references :parent_model, foreign_key: { to_table: :ml_models }
      t.boolean :is_active, default: false

      # Metadata
      t.references :trained_by, foreign_key: { to_table: :users }
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :ml_models, :name
    add_index :ml_models, :model_type
    add_index :ml_models, :status
    add_index :ml_models, :version
    add_index :ml_models, [:model_type, :is_active]
    add_index :ml_models, :accuracy
  end
end
