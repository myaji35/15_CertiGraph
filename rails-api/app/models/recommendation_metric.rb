# app/models/recommendation_metric.rb
class RecommendationMetric < ApplicationRecord
  belongs_to :learning_recommendation

  validates :metric_date, presence: true
  validates :impressions, numericality: { greater_than_or_equal_to: 0 }
  validates :clicks, numericality: { greater_than_or_equal_to: 0 }
  validates :completions, numericality: { greater_than_or_equal_to: 0 }

  scope :for_date, ->(date) { where(metric_date: date) }
  scope :recent, ->(days = 7) { where('metric_date >= ?', days.days.ago.to_date) }
  scope :for_recommendation, ->(rec_id) { where(learning_recommendation_id: rec_id) }

  before_save :calculate_rates

  # Calculate CTR and completion rate
  def calculate_rates
    self.ctr = impressions > 0 ? (clicks.to_f / impressions * 100).round(2) : 0.0
    self.completion_rate = clicks > 0 ? (completions.to_f / clicks * 100).round(2) : 0.0
  end

  # Record impression
  def record_impression!
    increment!(:impressions)
    calculate_rates
    save
  end

  # Record click
  def record_click!
    increment!(:clicks)
    calculate_rates
    save
  end

  # Record completion
  def record_completion!
    increment!(:completions)
    calculate_rates
    save
  end

  # Record dismissal
  def record_dismissal!
    increment!(:dismissals)
    save
  end

  # Get or create metric for today
  def self.for_today(recommendation)
    find_or_create_by(
      learning_recommendation: recommendation,
      metric_date: Date.current
    )
  end

  # Aggregate metrics for a period
  def self.aggregate_metrics(recommendation, start_date, end_date)
    metrics = where(learning_recommendation: recommendation)
              .where(metric_date: start_date..end_date)

    {
      total_impressions: metrics.sum(:impressions),
      total_clicks: metrics.sum(:clicks),
      total_completions: metrics.sum(:completions),
      total_dismissals: metrics.sum(:dismissals),
      avg_ctr: metrics.average(:ctr)&.round(2) || 0.0,
      avg_completion_rate: metrics.average(:completion_rate)&.round(2) || 0.0,
      avg_rating: metrics.average(:avg_rating)&.round(2) || 0.0
    }
  end
end
