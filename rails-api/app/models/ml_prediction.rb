class MlPrediction < ApplicationRecord
  belongs_to :ml_model
  belongs_to :user
  belongs_to :study_material, optional: true
  belongs_to :question, optional: true

  validates :prediction_type, presence: true
  validates :predicted_at, presence: true

  # Scopes
  scope :validated, -> { where.not(validated_at: nil) }
  scope :correct, -> { where(was_correct: true) }
  scope :incorrect, -> { where(was_correct: false) }
  scope :recent, -> { order(predicted_at: :desc) }
  scope :by_type, ->(type) { where(prediction_type: type) }

  # Validation
  def validate_prediction(actual_outcome)
    prediction_correct = (prediction_result['predicted_class'] == actual_outcome)

    update!(
      actual_outcome: actual_outcome,
      was_correct: prediction_correct,
      validated_at: Time.current,
      prediction_error: calculate_error(actual_outcome)
    )

    # Notify model to update metrics
    ml_model.update_accuracy_metrics if ml_model.respond_to?(:update_accuracy_metrics)
  end

  private

  def calculate_error(actual)
    predicted = prediction_result['predicted_value'] || prediction_result['predicted_class']
    return nil unless predicted && actual

    if predicted.is_a?(Numeric) && actual.is_a?(Numeric)
      (predicted - actual).abs
    else
      predicted == actual ? 0.0 : 1.0
    end
  end
end
