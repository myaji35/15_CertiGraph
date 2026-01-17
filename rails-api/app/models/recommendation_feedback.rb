# app/models/recommendation_feedback.rb
class RecommendationFeedback < ApplicationRecord
  belongs_to :user
  belongs_to :learning_recommendation

  validates :feedback_type, presence: true,
            inclusion: { in: %w[clicked completed dismissed rated viewed accepted] }
  validates :rating, numericality: { greater_than_or_equal_to: 1,
                                    less_than_or_equal_to: 5,
                                    allow_nil: true }

  scope :clicked, -> { where(feedback_type: 'clicked') }
  scope :completed, -> { where(feedback_type: 'completed') }
  scope :dismissed, -> { where(feedback_type: 'dismissed') }
  scope :rated, -> { where(feedback_type: 'rated') }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_recommendation, ->(rec_id) { where(learning_recommendation_id: rec_id) }
  scope :positive, -> { where(was_helpful: true) }
  scope :negative, -> { where(was_helpful: false) }

  # Calculate average rating for a recommendation
  def self.average_rating_for(recommendation)
    where(learning_recommendation: recommendation, feedback_type: 'rated')
      .average(:rating)&.round(2) || 0.0
  end

  # Get feedback summary for a recommendation
  def self.summary_for(recommendation)
    feedbacks = where(learning_recommendation: recommendation)

    {
      total_feedbacks: feedbacks.count,
      clicks: feedbacks.clicked.count,
      completions: feedbacks.completed.count,
      dismissals: feedbacks.dismissed.count,
      ratings: feedbacks.rated.count,
      avg_rating: feedbacks.average(:rating)&.round(2) || 0.0,
      helpful_count: feedbacks.positive.count,
      not_helpful_count: feedbacks.negative.count,
      avg_time_spent: feedbacks.average(:time_spent_seconds)&.round(2) || 0.0
    }
  end

  # Track interaction
  def self.track_interaction(user:, recommendation:, type:, metadata: {})
    create!(
      user: user,
      learning_recommendation: recommendation,
      feedback_type: type,
      interaction_metadata: metadata,
      time_spent_seconds: metadata[:time_spent_seconds]
    )
  end
end
