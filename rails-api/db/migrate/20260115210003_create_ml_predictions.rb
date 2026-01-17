class CreateMlPredictions < ActiveRecord::Migration[7.2]
  def change
    create_table :ml_predictions do |t|
      t.references :ml_model, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # Prediction details
      t.string :prediction_type, null: false # 'error_pattern', 'weakness_severity', 'improvement_forecast'
      t.json :input_features, default: {}
      t.json :prediction_result, default: {}

      # Confidence and probability
      t.float :confidence_score, default: 0.0
      t.json :probability_distribution, default: {}

      # Context
      t.references :study_material
      t.references :question
      t.string :context_type # 'exam_session', 'practice', 'review'
      t.bigint :context_id

      # Validation
      t.string :actual_outcome
      t.boolean :was_correct
      t.float :prediction_error

      # Timing
      t.integer :inference_time_ms
      t.datetime :predicted_at, null: false
      t.datetime :validated_at

      t.timestamps
    end

    add_index :ml_predictions, :prediction_type
    add_index :ml_predictions, :predicted_at
    add_index :ml_predictions, [:user_id, :prediction_type]
    add_index :ml_predictions, [:ml_model_id, :was_correct]
  end
end
