class AbTestAssignment < ApplicationRecord
  belongs_to :ab_test
  belongs_to :user

  validates :variant, presence: true
  validates :user_id, uniqueness: { scope: :ab_test_id }

  # Scopes
  scope :converted, -> { where(converted: true) }
  scope :by_variant, ->(variant) { where(variant: variant) }

  # Track interaction
  def record_interaction(conversion_data = {})
    update!(
      last_interaction_at: Time.current,
      interaction_count: interaction_count + 1,
      first_interaction_at: first_interaction_at || Time.current
    )

    # Check if this interaction counts as conversion
    check_conversion(conversion_data) if conversion_data.present?
  end

  # Mark as converted
  def convert!(conversion_data = {})
    return if converted?

    update!(
      converted: true,
      converted_at: Time.current,
      conversion_data: conversion_data
    )
  end

  # Record specific metrics
  def record_metric(metric_name, value)
    current_metrics = metrics || {}
    current_metrics[metric_name] = value

    update!(metrics: current_metrics)
  end

  private

  def check_conversion(conversion_data)
    # Conversion logic based on test type and primary metrics
    primary_metrics = ab_test.primary_metrics

    converted = false

    primary_metrics.each do |metric|
      case metric
      when 'accuracy_improvement'
        converted ||= conversion_data['accuracy_improvement'].to_f > 10.0
      when 'engagement'
        converted ||= conversion_data['session_duration'].to_i > 300
      when 'completion_rate'
        converted ||= conversion_data['completed'] == true
      end
    end

    convert!(conversion_data) if converted
  end
end
