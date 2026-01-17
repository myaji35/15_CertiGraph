class QuestionPassage < ApplicationRecord
  belongs_to :question
  belongs_to :passage

  validates :question, presence: true
  validates :passage, presence: true
  validates :relevance_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  scope :primary, -> { where(is_primary: true) }
  scope :secondary, -> { where(is_primary: false) }
  scope :high_relevance, -> { where('relevance_score >= ?', 80) }
  scope :by_relevance, -> { order(relevance_score: :desc) }
end
