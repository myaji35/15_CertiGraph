class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :payment

  # Plan types
  SEASON_PASS = 'season_pass'.freeze
  VIP_PASS = 'vip_pass'.freeze

  # Validations
  validates :plan_type, presence: true, inclusion: { in: [SEASON_PASS, VIP_PASS] }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :starts_at, presence: true
  validates :expires_at, presence: true
  validate :expires_at_after_starts_at

  # Scopes
  scope :active, -> { where(is_active: true, status: 'active').where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :by_plan, ->(plan_type) { where(plan_type: plan_type) }

  # Callbacks
  before_save :update_user_payment_status
  after_create :activate_user_subscription
  after_save :check_expiration

  # Class methods
  def self.create_from_payment(payment, plan_type: SEASON_PASS, duration_days: 90)
    create!(
      user: payment.user,
      payment: payment,
      plan_type: plan_type,
      price: payment.amount,
      starts_at: Time.current,
      expires_at: duration_days.days.from_now,
      is_active: true,
      status: 'active'
    )
  end

  # Instance methods
  def active?
    is_active && status == 'active' && !expired?
  end

  def expired?
    expires_at <= Time.current
  end

  def days_remaining
    return 0 if expired?
    ((expires_at - Time.current) / 1.day).ceil
  end

  def deactivate!
    update!(is_active: false, status: 'inactive')
    user.update!(is_paid: false, valid_until: nil)
  end

  private

  def expires_at_after_starts_at
    if starts_at.present? && expires_at.present? && expires_at <= starts_at
      errors.add(:expires_at, 'must be after start date')
    end
  end

  def update_user_payment_status
    if is_active && !expired?
      user.is_paid = true
      user.valid_until = expires_at
      user.subscription_type = plan_type
    end
  end

  def activate_user_subscription
    user.update!(
      is_paid: true,
      valid_until: expires_at,
      subscription_type: plan_type,
      role: :paid
    )
  end

  def check_expiration
    deactivate! if expired? && is_active
  end
end
