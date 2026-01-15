class Certification < ApplicationRecord
  # Associations
  has_many :exam_schedules, dependent: :destroy
  has_many :study_sets # 자격증별 학습세트

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :organization, presence: true

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :national, -> { where(is_national: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :popular, -> { where.not(annual_applicants: nil).order(annual_applicants: :desc) }
  scope :with_high_pass_rate, -> { where('pass_rate > ?', 50.0) }

  # Class methods
  def self.categories
    distinct.pluck(:category).compact
  end

  def self.organizations
    distinct.pluck(:organization).compact
  end

  # Instance methods
  def upcoming_exams(year = nil)
    year ||= Date.current.year
    exam_schedules
      .where(year: year)
      .where('exam_date >= ?', Date.current)
      .order(exam_date: :asc)
  end

  def next_exam
    exam_schedules
      .where('exam_date >= ?', Date.current)
      .order(exam_date: :asc)
      .first
  end

  def next_registration
    exam_schedules
      .where('registration_start_date >= ?', Date.current)
      .order(registration_start_date: :asc)
      .first
  end

  def average_pass_rate
    schedules_with_rate = exam_schedules.where.not(pass_rate: nil)
    return nil if schedules_with_rate.empty?

    schedules_with_rate.average(:pass_rate).round(1)
  end

  def total_applicants(year = nil)
    scope = exam_schedules
    scope = scope.where(year: year) if year
    scope.sum(:applicants_count)
  end

  def display_name
    name_en.present? ? "#{name} (#{name_en})" : name
  end

  def to_json_summary
    {
      id: id,
      name: name,
      name_en: name_en,
      organization: organization,
      category: category,
      series: series,
      annual_applicants: annual_applicants,
      pass_rate: pass_rate,
      next_exam: next_exam&.exam_date,
      website_url: website_url
    }
  end
end