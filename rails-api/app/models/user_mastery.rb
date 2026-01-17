class UserMastery < ApplicationRecord
  belongs_to :user
  belongs_to :knowledge_node

  validates :mastery_level, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :status, inclusion: { in: %w(untested learning mastered weak) }
  validates :color, inclusion: { in: %w(gray green red yellow) }

  scope :by_status, ->(status) { where(status: status) }
  scope :by_color, ->(color) { where(color: color) }
  scope :recently_tested, -> { where('last_tested_at > ?', 7.days.ago) }
  scope :weak_areas, -> { where(color: 'red') }
  scope :mastered_areas, -> { where(color: 'green') }
  scope :learning_areas, -> { where(color: 'yellow') }

  # 정확도 계산
  def accuracy
    return 0.0 if attempts.zero?
    (correct_attempts.to_f / attempts * 100).round(2)
  end

  # 상태 업데이트
  def update_with_attempt(correct:, time_minutes: 0, time_seconds: nil)
    self.attempts += 1
    self.correct_attempts += 1 if correct
    self.total_time_minutes += time_minutes
    self.last_tested_at = Time.current

    # Update streaks
    update_streak(correct: correct)

    # Update solve times if provided
    update_solve_time(time_seconds) if time_seconds

    # Update study streak
    if last_review_date != Date.today
      self.study_streak_days = (study_streak_days || 0) + 1
    end

    # Update best time of day
    self.time_of_day_best_performance = best_time_of_day

    # 숙달도 계산
    calculate_mastery_level

    # 색상 업데이트
    update_color

    # Update review schedule
    update_review_schedule

    # Calculate retention score
    calculate_retention_score

    # 이력 기록
    add_to_history(correct, time_minutes)

    save
  end

  # 숙달도 계산 (여러 요소 고려)
  def calculate_mastery_level
    return if attempts.zero?

    accuracy_ratio = correct_attempts.to_f / attempts

    # 최근 성과에 더 가중치 주기 (지수 평균)
    recent_weight = 0.7
    historical_weight = 1.0 - recent_weight

    self.mastery_level = (
      (accuracy_ratio * recent_weight) +
      (self.mastery_level * historical_weight)
    ).round(3)

    # 상태 업데이트
    update_status
  end

  def update_status
    case mastery_level
    when 0.8..1.0
      self.status = 'mastered'
    when 0.6..0.8
      self.status = 'learning'
    when 0..0.4
      self.status = 'weak'
    else
      self.status = 'learning'
    end
  end

  def update_color
    case mastery_level
    when 0.8..1.0
      self.color = 'green'
    when 0.5..0.8
      self.color = 'yellow'
    when 0..0.5
      self.color = 'red'
    else
      self.color = 'gray'
    end
  end

  def add_to_history(correct, time_minutes)
    history_entry = {
      timestamp: Time.current.iso8601,
      correct: correct,
      time_minutes: time_minutes,
      mastery_level: mastery_level,
      accuracy: accuracy
    }

    current_history = history || []
    self.history = (current_history + [history_entry]).last(100) # 최근 100개만 유지
  end

  # 학습 통계
  def days_since_last_test
    return nil unless last_tested_at
    ((Time.current - last_tested_at) / 1.day).ceil
  end

  def recent_performance(days: 7)
    return [] unless history.present?

    cutoff_date = days.days.ago
    history.select do |entry|
      Time.parse(entry['timestamp']) > cutoff_date
    end
  end

  def recent_accuracy(days: 7)
    recent = recent_performance(days: days)
    return 0.0 if recent.empty?

    correct_count = recent.count { |entry| entry['correct'] }
    (correct_count.to_f / recent.length * 100).round(2)
  end

  # Enhanced performance tracking methods
  def update_streak(correct:)
    if correct
      self.consecutive_correct = (consecutive_correct || 0) + 1
      self.consecutive_incorrect = 0
    else
      self.consecutive_incorrect = (consecutive_incorrect || 0) + 1
      self.consecutive_correct = 0
    end
  end

  def update_solve_time(seconds)
    self.fastest_solve_seconds = [fastest_solve_seconds || seconds, seconds].min

    # Calculate running average
    if avg_solve_seconds.nil?
      self.avg_solve_seconds = seconds
    else
      # Weighted average: 80% old, 20% new
      self.avg_solve_seconds = (avg_solve_seconds * 0.8 + seconds * 0.2).round
    end
  end

  def update_review_schedule
    self.last_review_date = Date.today

    # Spaced repetition algorithm (simplified)
    interval = case mastery_level
    when 0.9..1.0 then 30.days
    when 0.8..0.9 then 14.days
    when 0.6..0.8 then 7.days
    when 0.4..0.6 then 3.days
    else 1.day
    end

    self.next_review_date = Date.today + interval
  end

  def calculate_retention_score
    return 0.0 if last_tested_at.nil?

    days_since = days_since_last_test
    decay_factor = Math.exp(-days_since / 30.0) # Exponential decay

    self.retention_score = (mastery_level * decay_factor).round(3)
  end

  def best_time_of_day
    return nil unless history.present?

    time_performance = Hash.new { |h, k| h[k] = { correct: 0, total: 0 } }

    history.each do |entry|
      hour = Time.parse(entry['timestamp']).hour
      period = case hour
      when 6..11 then 'morning'
      when 12..17 then 'afternoon'
      when 18..23 then 'evening'
      else 'night'
      end

      time_performance[period][:total] += 1
      time_performance[period][:correct] += 1 if entry['correct']
    end

    best = time_performance.max_by do |_period, stats|
      stats[:total] > 0 ? stats[:correct].to_f / stats[:total] : 0
    end

    best ? best[0] : nil
  end

  def performance_trend(days: 14)
    recent = recent_performance(days: days)
    return 'insufficient_data' if recent.length < 3

    first_half = recent.first(recent.length / 2)
    second_half = recent.last(recent.length / 2)

    first_accuracy = first_half.count { |e| e['correct'] }.to_f / first_half.length
    second_accuracy = second_half.count { |e| e['correct'] }.to_f / second_half.length

    if second_accuracy > first_accuracy + 0.1
      'improving'
    elsif second_accuracy < first_accuracy - 0.1
      'declining'
    else
      'stable'
    end
  end

  def needs_review?
    return true if attempts.zero?
    return true if next_review_date && next_review_date <= Date.today
    return true if last_tested_at && last_tested_at < 7.days.ago && mastery_level < 0.8
    false
  end

  def learning_efficiency
    return 0.0 if total_time_minutes.zero?

    # Mastery gained per hour of study
    (mastery_level / (total_time_minutes / 60.0)).round(3)
  end

  def to_json(*args)
    {
      id: id,
      user_id: user_id,
      knowledge_node_id: knowledge_node_id,
      knowledge_node_name: knowledge_node.name,
      mastery_level: mastery_level,
      status: status,
      color: color,
      attempts: attempts,
      correct_attempts: correct_attempts,
      accuracy: accuracy,
      last_tested_at: last_tested_at,
      total_time_minutes: total_time_minutes,
      recent_accuracy_7d: recent_accuracy(days: 7),
      days_since_last_test: days_since_last_test
    }
  end
end
