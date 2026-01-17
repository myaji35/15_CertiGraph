class ReviewVote < ApplicationRecord
  belongs_to :user
  belongs_to :review

  validates :user_id, uniqueness: { scope: :review_id, message: "이미 투표하셨습니다" }
  validates :helpful, inclusion: { in: [true, false] }

  scope :helpful, -> { where(helpful: true) }
  scope :not_helpful, -> { where(helpful: false) }
end
