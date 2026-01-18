class ExamAnswer < ApplicationRecord
  belongs_to :exam_session
  belongs_to :question

  validates :selected_answer, presence: true

  before_save :check_answer

  private

  def check_answer
    self.is_correct = (selected_answer == question.answer)
  end
end
