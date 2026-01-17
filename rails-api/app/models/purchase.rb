class Purchase < ApplicationRecord
  belongs_to :user
  belongs_to :study_material
  belongs_to :payment, optional: true

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed cancelled refunded] }
  validates :user_id, uniqueness: { scope: :study_material_id, message: "이미 이 자료를 구매하셨습니다" }
  validates :download_limit, numericality: { greater_than_or_equal_to: 0 }

  enum status: {
    pending: 'pending',
    completed: 'completed',
    cancelled: 'cancelled',
    refunded: 'refunded'
  }

  scope :completed, -> { where(status: 'completed') }
  scope :active, -> { completed.where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { completed.where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :recent, -> { order(purchased_at: :desc) }

  after_create :mark_review_as_verified, if: :completed?
  after_update :mark_review_as_verified, if: -> { saved_change_to_status? && completed? }

  def can_download?
    completed? && !expired? && (download_limit.nil? || download_count < download_limit)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def download!
    raise "다운로드 한도를 초과했습니다" unless can_download?
    increment!(:download_count)
  end

  def remaining_downloads
    return Float::INFINITY if download_limit.nil?
    [download_limit - download_count, 0].max
  end

  def complete!(payment_record = nil)
    update!(
      status: 'completed',
      payment: payment_record,
      purchased_at: Time.current
    )

    # Update study material sales count
    study_material.increment!(:sales_count)
  end

  def cancel!
    update!(status: 'cancelled')
  end

  def refund!
    return false unless completed?

    transaction do
      update!(status: 'refunded')
      study_material.decrement!(:sales_count) if study_material.sales_count > 0
    end

    true
  end

  private

  def mark_review_as_verified
    review = Review.find_by(user: user, study_material: study_material)
    review&.update(verified_purchase: true)
  end
end
