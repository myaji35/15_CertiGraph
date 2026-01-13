class StudySet < ApplicationRecord
  belongs_to :user
  has_many :study_materials, dependent: :destroy
  has_many :questions, through: :study_materials
  has_many :exam_sessions, dependent: :destroy

  validates :title, presence: true

  def certification_display_name
    case certification
    when 'social_worker_1'
      '사회복지사 1급'
    when 'social_worker_2'
      '사회복지사 2급'
    when 'care_worker'
      '요양보호사'
    when 'childcare_teacher'
      '보육교사'
    when 'other'
      '기타'
    else
      certification
    end
  end
end
