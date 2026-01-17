class Passage < ApplicationRecord
  belongs_to :study_material
  has_many :question_passages, dependent: :destroy
  has_many :questions, through: :question_passages

  validates :content, presence: true

  before_save :calculate_character_count
  before_save :detect_features

  scope :with_images, -> { where(has_image: true) }
  scope :with_tables, -> { where(has_table: true) }
  scope :by_position, -> { order(:position) }

  def calculate_character_count
    self.character_count = content.to_s.length
  end

  def detect_features
    return unless content.present?

    self.has_image = content.include?('![') || content.include?('[image')
    self.has_table = content.include?('|') || content.match?(/\(\s*[ㄱ-ㅎ]\s*\)/)
  end

  def add_question(question, is_primary: false, relevance_score: 100)
    question_passages.find_or_create_by(question: question) do |qp|
      qp.is_primary = is_primary
      qp.relevance_score = relevance_score
    end
  end

  def primary_questions
    questions.joins(:question_passages)
            .where(question_passages: { is_primary: true })
            .order('question_passages.created_at')
  end

  def related_questions
    questions.joins(:question_passages)
            .where(question_passages: { is_primary: false })
            .order('question_passages.relevance_score DESC')
  end
end
