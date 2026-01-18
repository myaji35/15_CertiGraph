# frozen_string_literal: true

class Option < ApplicationRecord
  belongs_to :question

  validates :content, presence: true
  validates :is_correct, inclusion: { in: [true, false] }

  scope :correct, -> { where(is_correct: true) }
  scope :incorrect, -> { where(is_correct: false) }
end
