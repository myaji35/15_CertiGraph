class AbTest < ApplicationRecord
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :ab_test_assignments, dependent: :destroy
  has_many :users, through: :ab_test_assignments

  # Status management
  validates :name, presence: true
  validates :test_type, presence: true, inclusion: { in: %w[algorithm ui recommendation learning_path] }
  validates :status, inclusion: { in: %w[draft running paused completed cancelled] }

  # Scopes
  scope :running, -> { where(status: 'running') }
  scope :completed, -> { where(status: 'completed') }
  scope :active, -> { where(status: ['running', 'paused']) }

  # State transitions
  def start!
    return false unless status == 'draft'

    update!(
      status: 'running',
      started_at: Time.current
    )
  end

  def pause!
    return false unless status == 'running'

    update!(status: 'paused')
  end

  def resume!
    return false unless status == 'paused'

    update!(status: 'running')
  end

  def complete!
    return false unless %w[running paused].include?(status)

    update!(
      status: 'completed',
      ended_at: Time.current
    )
  end

  def cancel!
    update!(
      status: 'cancelled',
      ended_at: Time.current
    )
  end

  # Assignment logic
  def assign_user(user)
    return ab_test_assignments.find_by(user: user) if ab_test_assignments.exists?(user: user)

    # Randomly assign to a variant
    variant = select_variant_for_user(user)

    ab_test_assignments.create!(
      user: user,
      variant: variant,
      assigned_at: Time.current
    )
  end

  # Statistics
  def conversion_rate(variant_name = nil)
    assignments = variant_name ? ab_test_assignments.where(variant: variant_name) : ab_test_assignments
    total = assignments.count
    return 0.0 if total.zero?

    converted = assignments.where(converted: true).count
    (converted.to_f / total * 100).round(2)
  end

  def variant_statistics
    variants.keys.map do |variant_name|
      assignments = ab_test_assignments.where(variant: variant_name)
      {
        variant: variant_name,
        sample_size: assignments.count,
        conversions: assignments.where(converted: true).count,
        conversion_rate: conversion_rate(variant_name),
        avg_interactions: assignments.average(:interaction_count)&.round(2) || 0
      }
    end
  end

  # Statistical significance testing
  def calculate_statistical_significance
    control_assignments = ab_test_assignments.where(variant: 'control')
    control_conversions = control_assignments.where(converted: true).count
    control_total = control_assignments.count

    return nil if control_total < 100 # Need minimum sample size

    results = {}

    variants.keys.reject { |k| k == 'control' }.each do |treatment_variant|
      treatment_assignments = ab_test_assignments.where(variant: treatment_variant)
      treatment_conversions = treatment_assignments.where(converted: true).count
      treatment_total = treatment_assignments.count

      next if treatment_total < 100

      # Chi-square test
      chi_square, p_value = perform_chi_square_test(
        control_conversions, control_total,
        treatment_conversions, treatment_total
      )

      results[treatment_variant] = {
        chi_square: chi_square,
        p_value: p_value,
        is_significant: p_value < 0.05,
        control_rate: (control_conversions.to_f / control_total * 100).round(2),
        treatment_rate: (treatment_conversions.to_f / treatment_total * 100).round(2)
      }
    end

    # Update test results
    update!(
      results: results,
      is_significant: results.values.any? { |r| r[:is_significant] },
      winner_variant: determine_winner(results)
    )

    results
  end

  private

  def select_variant_for_user(user)
    # Simple random assignment based on user ID
    variant_keys = variants.keys
    index = user.id % variant_keys.length
    variant_keys[index]
  end

  def perform_chi_square_test(control_conv, control_total, treatment_conv, treatment_total)
    # Observed values
    o11 = control_conv
    o12 = control_total - control_conv
    o21 = treatment_conv
    o22 = treatment_total - treatment_conv

    total = control_total + treatment_total
    row1_total = o11 + o21
    row2_total = o12 + o22

    # Expected values
    e11 = (control_total * row1_total).to_f / total
    e12 = (control_total * row2_total).to_f / total
    e21 = (treatment_total * row1_total).to_f / total
    e22 = (treatment_total * row2_total).to_f / total

    # Chi-square statistic
    chi_square = ((o11 - e11)**2 / e11) +
                 ((o12 - e12)**2 / e12) +
                 ((o21 - e21)**2 / e21) +
                 ((o22 - e22)**2 / e22)

    # Approximate p-value using chi-square distribution with 1 degree of freedom
    # For simplicity, using a lookup table approximation
    p_value = approximate_p_value(chi_square)

    [chi_square.round(4), p_value.round(4)]
  end

  def approximate_p_value(chi_square)
    # Chi-square critical values for df=1
    # This is a simplified approximation
    case chi_square
    when 0..0.004 then 0.95
    when 0.004..0.02 then 0.90
    when 0.02..0.06 then 0.80
    when 0.06..0.15 then 0.70
    when 0.15..0.46 then 0.50
    when 0.46..1.07 then 0.30
    when 1.07..1.64 then 0.20
    when 1.64..2.71 then 0.10
    when 2.71..3.84 then 0.05
    when 3.84..5.02 then 0.025
    when 5.02..6.63 then 0.01
    when 6.63..7.88 then 0.005
    else 0.001
    end
  end

  def determine_winner(results)
    # Find the treatment with highest conversion rate that is statistically significant
    significant_results = results.select { |_, v| v[:is_significant] }
    return nil if significant_results.empty?

    winner = significant_results.max_by { |_, v| v[:treatment_rate] }
    winner&.first
  end
end
