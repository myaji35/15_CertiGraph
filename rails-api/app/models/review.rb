class Review < ApplicationRecord
  belongs_to :user
  belongs_to :study_material
  has_many :review_votes, dependent: :destroy

  validates :rating, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 5
  }
  validates :comment, length: { maximum: 2000 }, allow_blank: true
  validates :user_id, uniqueness: { scope: :study_material_id, message: "이미 이 자료에 대한 리뷰를 작성하셨습니다" }

  scope :recent, -> { order(created_at: :desc) }
  scope :top_rated, -> { order(rating: :desc, helpful_count: :desc) }
  scope :verified, -> { where(verified_purchase: true) }
  scope :with_rating, ->(rating) { where(rating: rating) }
  scope :helpful, -> { where("helpful_count > ?", 0).order(helpful_count: :desc) }

  after_create :update_material_rating
  after_update :update_material_rating
  after_destroy :update_material_rating

  def helpful_percentage
    total = helpful_count + not_helpful_count
    return 0 if total.zero?
    (helpful_count.to_f / total * 100).round(1)
  end

  def user_voted?(user, helpful)
    review_votes.exists?(user_id: user.id, helpful: helpful)
  end

  def vote!(user, helpful)
    vote = review_votes.find_or_initialize_by(user_id: user.id)

    # Remove old count if vote exists and is changing
    if vote.persisted?
      if vote.helpful
        decrement(:helpful_count)
      else
        decrement(:not_helpful_count)
      end
    end

    vote.helpful = helpful
    vote.save!

    # Add new count
    if helpful
      increment(:helpful_count)
    else
      increment(:not_helpful_count)
    end

    save!
  end

  def remove_vote!(user)
    vote = review_votes.find_by(user_id: user.id)
    return unless vote

    if vote.helpful
      decrement(:helpful_count)
    else
      decrement(:not_helpful_count)
    end

    vote.destroy
    save!
  end

  private

  def update_material_rating
    material = study_material
    reviews = material.reviews

    if reviews.any?
      material.update_columns(
        avg_rating: reviews.average(:rating).to_f.round(2),
        total_reviews: reviews.count
      )
    else
      material.update_columns(
        avg_rating: 0.0,
        total_reviews: 0
      )
    end
  end
end
