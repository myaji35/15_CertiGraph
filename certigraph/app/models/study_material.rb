class StudyMaterial < ApplicationRecord
  belongs_to :user
  belongs_to :study_set
end
