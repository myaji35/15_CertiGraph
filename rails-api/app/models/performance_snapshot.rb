class PerformanceSnapshot < ApplicationRecord
  belongs_to :user
  belongs_to :study_set, optional: true

  validates :snapshot_date, presence: true
  validates :period_type, inclusion: { in: %w[daily weekly monthly] }
  validates :user_id, uniqueness: { scope: [:snapshot_date, :study_set_id, :period_type] }

  scope :daily, -> { where(period_type: 'daily') }
  scope :weekly, -> { where(period_type: 'weekly') }
  scope :monthly, -> { where(period_type: 'monthly') }
  scope :for_date, ->(date) { where(snapshot_date: date) }
  scope :date_range, ->(start_date, end_date) { where(snapshot_date: start_date..end_date) }
  scope :recent, ->(days = 30) { where('snapshot_date >= ?', days.days.ago).order(snapshot_date: :desc) }
  scope :by_study_set, ->(study_set_id) { where(study_set_id: study_set_id) }

  # Best performance time of day
  def best_time_of_day
    times = {
      'morning' => morning_accuracy,
      'afternoon' => afternoon_accuracy,
      'evening' => evening_accuracy,
      'night' => night_accuracy
    }
    times.max_by { |_k, v| v }&.first
  end

  # Most productive time of day (by study minutes)
  def most_productive_time
    times = {
      'morning' => morning_study_minutes,
      'afternoon' => afternoon_study_minutes,
      'evening' => evening_study_minutes,
      'night' => night_study_minutes
    }
    times.max_by { |_k, v| v }&.first
  end

  # Overall performance grade
  def performance_grade
    case overall_mastery_level
    when 0.9..1.0 then 'A+'
    when 0.85..0.9 then 'A'
    when 0.8..0.85 then 'A-'
    when 0.75..0.8 then 'B+'
    when 0.7..0.75 then 'B'
    when 0.65..0.7 then 'B-'
    when 0.6..0.65 then 'C+'
    when 0.55..0.6 then 'C'
    when 0.5..0.55 then 'C-'
    else 'D'
    end
  end

  # Trending direction
  def trending_direction
    if mastery_change > 0.05
      'up'
    elsif mastery_change < -0.05
      'down'
    else
      'stable'
    end
  end

  # Study efficiency (correct answers per minute)
  def study_efficiency
    return 0.0 if total_study_minutes.zero?
    (total_correct.to_f / total_study_minutes * 60).round(2)
  end

  # Completion status
  def completion_status
    case completion_percentage
    when 0..25 then 'just_started'
    when 25..50 then 'in_progress'
    when 50..75 then 'halfway'
    when 75..95 then 'almost_done'
    when 95..100 then 'completed'
    else 'unknown'
    end
  end

  # Generate summary text
  def summary_text
    "#{performance_grade} grade with #{overall_accuracy.round(1)}% accuracy. " \
    "Mastered #{mastered_nodes_count} concepts, #{completion_percentage.round(1)}% complete. " \
    "Trending #{trending_direction}."
  end

  # To JSON with calculated fields
  def as_json(options = {})
    super(options).merge(
      best_time_of_day: best_time_of_day,
      most_productive_time: most_productive_time,
      performance_grade: performance_grade,
      trending_direction: trending_direction,
      study_efficiency: study_efficiency,
      completion_status: completion_status,
      summary_text: summary_text
    )
  end

  # Class method to get trend data
  def self.trend_data(user_id, study_set_id: nil, days: 30, period: 'daily')
    scope = where(user_id: user_id, period_type: period)
    scope = scope.where(study_set_id: study_set_id) if study_set_id
    scope.where('snapshot_date >= ?', days.days.ago)
         .order(snapshot_date: :asc)
  end

  # Compare with previous snapshot
  def compare_with_previous
    previous = self.class.where(user_id: user_id, study_set_id: study_set_id, period_type: period_type)
                         .where('snapshot_date < ?', snapshot_date)
                         .order(snapshot_date: :desc)
                         .first

    return nil unless previous

    {
      mastery_change: overall_mastery_level - previous.overall_mastery_level,
      accuracy_change: overall_accuracy - previous.overall_accuracy,
      attempts_change: total_attempts - previous.total_attempts,
      mastered_nodes_change: mastered_nodes_count - previous.mastered_nodes_count,
      study_time_change: total_study_minutes - previous.total_study_minutes,
      days_between: (snapshot_date - previous.snapshot_date).to_i
    }
  end
end
