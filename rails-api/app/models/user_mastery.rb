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
  def update_with_attempt(correct:, time_minutes: 0)
    self.attempts += 1
    self.correct_attempts += 1 if correct
    self.total_time_minutes += time_minutes
    self.last_tested_at = Time.current

    # 숙달도 계산
    calculate_mastery_level

    # 색상 업데이트
    update_color

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
