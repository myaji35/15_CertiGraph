class WrongAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :study_set
end
