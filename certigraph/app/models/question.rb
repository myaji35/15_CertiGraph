# frozen_string_literal: true

require 'csv'

class Question < ApplicationRecord
  belongs_to :study_set
  has_many :options, dependent: :destroy
  has_many :test_answers, dependent: :destroy

  accepts_nested_attributes_for :options, allow_destroy: true

  validates :content, presence: true
  validates :question_type, presence: true, inclusion: { in: %w[multiple_choice true_false short_answer] }
  validates :difficulty, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }, allow_nil: true
  validate :must_have_correct_answer

  enum question_type: {
    multiple_choice: 'multiple_choice',
    true_false: 'true_false',
    short_answer: 'short_answer'
  }

  scope :by_difficulty, ->(level) { where(difficulty: level) }
  scope :by_topic, ->(topic) { where(topic: topic) }
  scope :random_selection, ->(count) { order('RANDOM()').limit(count) }

  # CSV Import
  def self.import_from_csv(file_path)
    imported_count = 0

    CSV.foreach(file_path, headers: true) do |row|
      question = new(
        study_set_id: row['study_set_id'],
        content: row['content'],
        question_type: row['question_type'] || 'multiple_choice',
        difficulty: row['difficulty']&.to_i || 3,
        topic: row['topic'],
        explanation: row['explanation'],
        correct_answer: row['correct_answer']
      )

      # Parse options (assuming format: "option1|option2|option3|option4")
      if row['options'].present?
        options_array = row['options'].split('|')
        correct_index = row['correct_answer']&.to_i || 0

        options_array.each_with_index do |option_content, index|
          question.options.build(
            content: option_content.strip,
            is_correct: (index == correct_index)
          )
        end
      end

      if question.save
        imported_count += 1
      else
        Rails.logger.error "Failed to import question: #{question.errors.full_messages.join(', ')}"
      end
    end

    imported_count
  end

  # Export to CSV
  def self.to_csv
    attributes = %w[id study_set_id content question_type difficulty topic explanation correct_answer created_at]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.find_each do |question|
        csv << attributes.map { |attr| question.send(attr) }
      end
    end
  end

  private

  def must_have_correct_answer
    if question_type == 'multiple_choice' && options.none?(&:is_correct)
      errors.add(:base, '정답이 하나 이상 선택되어야 합니다.')
    end
  end
end
