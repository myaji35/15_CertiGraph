class Payment < ApplicationRecord
  belongs_to :user
  has_one :subscription, dependent: :destroy

  # Status enum
  enum status: {
    pending: 'pending',
    ready: 'ready',
    in_progress: 'in_progress',
    waiting_for_deposit: 'waiting_for_deposit',
    done: 'done',
    canceled: 'canceled',
    partial_canceled: 'partial_canceled',
    aborted: 'aborted',
    expired: 'expired',
    failed: 'failed'
  }

  # Validations
  validates :order_id, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :status, presence: true

  # Scopes
  scope :successful, -> { where(status: 'done') }
  scope :pending, -> { where(status: ['pending', 'ready', 'in_progress']) }
  scope :failed, -> { where(status: ['failed', 'canceled', 'aborted', 'expired']) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_create :set_order_id, if: -> { order_id.blank? }

  # Class methods
  def self.generate_order_id
    "ORDER_#{Time.current.strftime('%Y%m%d%H%M%S')}_#{SecureRandom.hex(4)}"
  end

  # Instance methods
  def success?
    status == 'done'
  end

  def failed?
    %w[failed canceled aborted expired].include?(status)
  end

  def pending?
    %w[pending ready in_progress waiting_for_deposit].include?(status)
  end

  def cancelable?
    %w[done partial_canceled].include?(status)
  end

  def mark_as_done!
    update!(
      status: 'done',
      approved_at: Time.current
    )
  end

  def mark_as_failed!(code, message)
    update!(
      status: 'failed',
      failure_code: code,
      failure_message: message
    )
  end

  def refundable?
    success? && approved_at && approved_at > 7.days.ago
  end

  private

  def set_order_id
    update_column(:order_id, self.class.generate_order_id)
  end
end
