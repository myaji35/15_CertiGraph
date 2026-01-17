class MlModel < ApplicationRecord
  belongs_to :parent_model, class_name: 'MlModel', optional: true
  belongs_to :trained_by, class_name: 'User', optional: true
  has_many :ml_predictions, dependent: :destroy
  has_many :child_models, class_name: 'MlModel', foreign_key: 'parent_model_id'

  # Validations
  validates :name, presence: true
  validates :model_type, presence: true, inclusion: {
    in: %w[pattern_classifier error_predictor time_series anomaly_detector]
  }
  validates :version, presence: true
  validates :status, inclusion: {
    in: %w[untrained training trained deployed deprecated]
  }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :deployed, -> { where(status: 'deployed') }
  scope :by_type, ->(type) { where(model_type: type) }

  # State management
  def start_training!
    update!(
      status: 'training',
      trained_at: Time.current
    )
  end

  def mark_trained!
    update!(
      status: 'trained',
      trained_at: Time.current
    )
  end

  def deploy!
    return false unless status == 'trained'

    # Deactivate other models of same type
    MlModel.where(model_type: model_type, is_active: true)
           .where.not(id: id)
           .update_all(is_active: false)

    update!(
      status: 'deployed',
      deployed_at: Time.current,
      is_active: true
    )
  end

  def deprecate!
    update!(
      status: 'deprecated',
      is_active: false
    )
  end

  # Prediction interface
  def predict(input_features, user: nil, context: {})
    raise "Model not trained" unless %w[trained deployed].include?(status)

    # This is a placeholder - actual prediction would use stored weights
    # In production, this would call Python ML service or use Ruby ML library
    prediction_result = perform_prediction(input_features)

    # Record prediction
    prediction = ml_predictions.create!(
      user: user,
      prediction_type: context[:prediction_type] || 'general',
      input_features: input_features,
      prediction_result: prediction_result,
      confidence_score: prediction_result[:confidence],
      predicted_at: Time.current,
      study_material_id: context[:study_material_id],
      question_id: context[:question_id],
      context_type: context[:context_type],
      context_id: context[:context_id]
    )

    # Update usage stats
    increment!(:prediction_count)
    touch(:last_used_at)

    prediction_result
  end

  # Validation
  def validate_prediction(prediction_id, actual_outcome)
    prediction = ml_predictions.find(prediction_id)
    prediction_correct = (prediction.prediction_result['predicted_class'] == actual_outcome)

    prediction.update!(
      actual_outcome: actual_outcome,
      was_correct: prediction_correct,
      validated_at: Time.current
    )

    # Update model accuracy metrics
    update_accuracy_metrics
  end

  # Performance metrics
  def calculate_performance_metrics
    validated_predictions = ml_predictions.where.not(validated_at: nil)
    return nil if validated_predictions.count < 10

    total = validated_predictions.count
    correct = validated_predictions.where(was_correct: true).count

    accuracy = (correct.to_f / total * 100).round(2)

    # Update stored metrics
    update!(
      accuracy: accuracy,
      metadata: metadata.merge(
        last_metrics_update: Time.current,
        total_validated: total
      )
    )

    {
      accuracy: accuracy,
      total_predictions: prediction_count,
      validated_predictions: total,
      correct_predictions: correct
    }
  end

  # Model versioning
  def create_new_version
    new_model = dup
    new_model.parent_model = self
    new_model.version = increment_version(version)
    new_model.status = 'untrained'
    new_model.is_active = false
    new_model.trained_at = nil
    new_model.deployed_at = nil
    new_model.prediction_count = 0

    new_model.save!
    new_model
  end

  private

  def perform_prediction(input_features)
    # Placeholder for actual ML prediction logic
    # In production, this would:
    # 1. Load model weights from model_weights JSON
    # 2. Perform feature preprocessing
    # 3. Run prediction algorithm
    # 4. Return structured results

    case model_type
    when 'pattern_classifier'
      classify_pattern(input_features)
    when 'error_predictor'
      predict_error(input_features)
    when 'anomaly_detector'
      detect_anomaly(input_features)
    when 'time_series'
      forecast_time_series(input_features)
    else
      { predicted_class: 'unknown', confidence: 0.0 }
    end
  end

  def classify_pattern(features)
    # Simplified pattern classification
    error_count = features['error_count'].to_i
    accuracy = features['accuracy'].to_f

    pattern = if error_count > 10 && accuracy < 60
                'high_risk'
              elsif error_count > 5 && accuracy < 75
                'moderate_risk'
              else
                'low_risk'
              end

    {
      predicted_class: pattern,
      confidence: 0.75,
      probabilities: {
        high_risk: error_count > 10 ? 0.7 : 0.2,
        moderate_risk: error_count > 5 ? 0.6 : 0.3,
        low_risk: error_count < 5 ? 0.7 : 0.1
      }
    }
  end

  def predict_error(features)
    # Simplified error prediction
    {
      predicted_class: features['previous_errors'] > 3 ? 'likely_error' : 'likely_correct',
      confidence: 0.68
    }
  end

  def detect_anomaly(features)
    # Simplified anomaly detection
    {
      predicted_class: features['z_score'].to_f.abs > 2.5 ? 'anomaly' : 'normal',
      confidence: 0.82,
      anomaly_score: features['z_score'].to_f.abs
    }
  end

  def forecast_time_series(features)
    # Simplified forecasting
    current_value = features['current_value'].to_f
    trend = features['trend'].to_f

    {
      predicted_value: current_value + trend,
      confidence: 0.70,
      confidence_interval: [current_value + trend - 5, current_value + trend + 5]
    }
  end

  def update_accuracy_metrics
    metrics = calculate_performance_metrics
    return unless metrics

    update!(
      accuracy: metrics[:accuracy],
      last_used_at: Time.current
    )
  end

  def increment_version(current_version)
    # Simple version incrementing: "1.0" -> "1.1" -> "2.0"
    major, minor = current_version.split('.').map(&:to_i)
    minor += 1
    if minor >= 10
      major += 1
      minor = 0
    end
    "#{major}.#{minor}"
  end
end
