class RandomizationStat < ApplicationRecord
  belongs_to :study_material
  belongs_to :question

  validates :option_id, presence: true
  validates :option_label, presence: true
  validates :bias_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :by_material, ->(material_id) { where(study_material_id: material_id) }
  scope :by_question, ->(question_id) { where(question_id: question_id) }
  scope :biased, -> { where('bias_score > ?', 20.0) }
  scope :uniform, -> { where(is_uniform: true) }
  scope :non_uniform, -> { where(is_uniform: false) }
  scope :recently_analyzed, -> { where('last_analyzed_at > ?', 1.hour.ago) }

  # Get position count by position index
  def position_count(position)
    return 0 unless (0..4).include?(position)
    send("position_#{position}_count")
  end

  # Set position count by position index
  def set_position_count(position, count)
    return unless (0..4).include?(position)
    send("position_#{position}_count=", count)
  end

  # Calculate expected frequency for chi-square test
  def expected_frequency
    return 0 if total_randomizations.zero?
    total_randomizations.to_f / 5.0 # Assuming 5 positions
  end

  # Get all position counts as array
  def position_counts
    [position_0_count, position_1_count, position_2_count, position_3_count, position_4_count]
  end

  # Check if distribution is significantly biased
  def significantly_biased?
    p_value < 0.05 && bias_score > 15.0
  end

  # Get quality rating based on bias score
  def quality_rating
    case bias_score
    when 0..5
      'excellent'
    when 5..10
      'good'
    when 10..20
      'acceptable'
    when 20..30
      'poor'
    else
      'very_poor'
    end
  end

  # Get human-readable distribution summary
  def distribution_summary
    counts = position_counts
    total = counts.sum
    return "No data" if total.zero?

    percentages = counts.map { |c| ((c.to_f / total) * 100).round(1) }
    "Positions: #{percentages.map.with_index { |p, i| "#{i + 1}: #{p}%" }.join(', ')}"
  end

  # Calculate variance from uniform distribution
  def distribution_variance
    counts = position_counts
    mean = counts.sum.to_f / counts.size
    return 0.0 if mean.zero?

    variance = counts.map { |count| (count - mean)**2 }.sum / counts.size
    variance
  end

  # Get the most frequent position (0-indexed)
  def most_frequent_position
    position_counts.each_with_index.max_by { |count, _| count }[1]
  end

  # Get the least frequent position (0-indexed)
  def least_frequent_position
    position_counts.each_with_index.min_by { |count, _| count }[1]
  end

  # Calculate coefficient of variation (CV)
  def coefficient_of_variation
    counts = position_counts
    mean = counts.sum.to_f / counts.size
    return 0.0 if mean.zero?

    std_dev = Math.sqrt(distribution_variance)
    (std_dev / mean) * 100
  end
end
