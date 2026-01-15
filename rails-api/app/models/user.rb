class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2]

  has_many :study_sets, dependent: :destroy
  has_many :exam_sessions, dependent: :destroy
  has_many :wrong_answers, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :user_masteries, dependent: :destroy
  has_many :knowledge_nodes, through: :user_masteries

  # Devise handles email and password validation
  # validates :email, presence: true, uniqueness: true
  # validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  # validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }, allow_blank: true

  enum role: { free: 0, paid: 1, admin: 2 }

  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.password = Devise.friendly_token[0, 20]
    end
  end

  def generate_jwt
    JWT.encode(
      { user_id: id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base
    )
  end

  # Payment methods
  def has_active_subscription?
    is_paid && valid_until.present? && valid_until > Time.current
  end

  def subscription_expired?
    valid_until.present? && valid_until <= Time.current
  end

  def current_subscription
    subscriptions.active.order(created_at: :desc).first
  end

  def check_subscription_expiration
    if subscription_expired? && is_paid
      update!(is_paid: false, valid_until: nil, subscription_type: nil)
    end
  end
end
