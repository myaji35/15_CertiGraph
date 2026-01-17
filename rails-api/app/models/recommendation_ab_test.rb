# app/models/recommendation_ab_test.rb
class RecommendationAbTest < ApplicationRecord
  belongs_to :user
  belongs_to :learning_recommendation, optional: true

  validates :test_name, presence: true
  validates :variant_name, presence: true,
            inclusion: { in: %w[control variant_a variant_b variant_c] }
  validates :status, presence: true,
            inclusion: { in: %w[active completed cancelled] }

  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :for_test, ->(test_name) { where(test_name: test_name) }
  scope :for_variant, ->(variant) { where(variant_name: variant) }
  scope :recent, -> { order(created_at: :desc) }

  # Start a new A/B test
  def self.start_test(user:, test_name:, variant_name:, config: {})
    create!(
      user: user,
      test_name: test_name,
      variant_name: variant_name,
      status: 'active',
      variant_config: config,
      started_at: Time.current
    )
  end

  # Complete test and record results
  def complete!(metrics: {})
    update!(
      status: 'completed',
      ended_at: Time.current,
      result_metrics: metrics
    )
  end

  # Get test results summary
  def self.results_summary(test_name)
    tests = for_test(test_name).completed

    variants = tests.group_by(&:variant_name)
    summary = {}

    variants.each do |variant, test_records|
      metrics = test_records.map { |t| t.result_metrics || {} }

      summary[variant] = {
        count: test_records.size,
        avg_ctr: calculate_avg(metrics, 'ctr'),
        avg_completion_rate: calculate_avg(metrics, 'completion_rate'),
        avg_rating: calculate_avg(metrics, 'rating'),
        avg_time_spent: calculate_avg(metrics, 'time_spent')
      }
    end

    summary
  end

  # Calculate average for a metric
  def self.calculate_avg(metrics, key)
    values = metrics.map { |m| m[key] }.compact
    return 0.0 if values.empty?

    (values.sum / values.size.to_f).round(2)
  end

  # Assign user to variant (A/B/C testing)
  def self.assign_variant(user, test_name, variants: %w[control variant_a variant_b])
    # Use user ID for consistent assignment
    variant_index = user.id % variants.size
    variants[variant_index]
  end
end
