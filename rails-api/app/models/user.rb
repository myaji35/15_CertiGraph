class User < ApplicationRecord
  # Include default devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable,
         :omniauthable,
         omniauth_providers: [:google_oauth2, :naver]

  has_many :study_sets, dependent: :destroy
  has_many :exam_sessions, dependent: :destroy
  has_many :test_sessions, dependent: :destroy
  has_many :wrong_answers, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :user_masteries, dependent: :destroy
  has_many :knowledge_nodes, through: :user_masteries
  has_many :reviews, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :review_votes, dependent: :destroy

  # Devise handles email and password validation
  # validates :email, presence: true, uniqueness: true
  # validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  # validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }, allow_blank: true

  enum role: { free: 0, paid: 1, admin: 2 }
  enum account_status: { active: 'active', suspended: 'suspended', deactivated: 'deactivated' }, _prefix: true

  # Active Storage for avatar
  has_one_attached :avatar

  # Callbacks
  after_create :auto_confirm_in_non_production, if: -> { Rails.env.development? || Rails.env.test? }

  # Validations
  validates :phone_number, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }
  validates :account_status, inclusion: { in: account_statuses.keys }

  # 입력 검증 (SQL Injection, XSS) - 먼저 체크
  validate :check_malicious_input

  # 비밀번호 복잡도 검증
  validate :password_complexity, if: -> { password.present? }

  # 이메일 형식 검증 - Devise의 기본 검증보다 엄격하게 적용
  validate :strict_email_format

  # 약관 동의 검증 (프로덕션 환경에서만 필수)
  validates :terms_agreed, acceptance: { message: "서비스 약관에 동의해야 합니다", accept: true }, on: :create, allow_nil: false, unless: -> { Rails.env.development? || Rails.env.test? }
  validates :privacy_agreed, acceptance: { message: "개인정보처리방침에 동의해야 합니다", accept: true }, on: :create, allow_nil: false, unless: -> { Rails.env.development? || Rails.env.test? }

  # Scopes
  scope :active, -> { where(account_status: 'active') }
  scope :with_2fa, -> { where(otp_required_for_login: true) }
  scope :without_2fa, -> { where(otp_required_for_login: false) }

  # Class methods
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name || auth.info.nickname
      user.password = Devise.friendly_token[0, 20]
      user.avatar_url = auth.info.image if auth.info.image
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
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

  # Two-Factor Authentication methods
  def enable_two_factor!
    self.otp_required_for_login = true
    self.otp_secret = User.generate_otp_secret
    generate_otp_backup_codes!
    save!
  end

  def disable_two_factor!
    self.otp_required_for_login = false
    self.otp_backup_codes = nil
    save!
  end

  def generate_otp_backup_codes!
    codes = 10.times.map { SecureRandom.hex(4) }
    self.otp_backup_codes = codes.join("\n")
    codes
  end

  def invalidate_otp_backup_code!(code)
    return false unless otp_backup_codes

    codes = otp_backup_codes.split("\n")
    return false unless codes.delete(code)

    self.otp_backup_codes = codes.join("\n")
    save!
  end

  def validate_and_consume_otp!(code)
    if otp_backup_codes&.split("\n")&.include?(code)
      invalidate_otp_backup_code!(code)
    else
      validate_and_consume_otp(code)
    end
  end

  # Profile methods
  def display_name
    name || email.split('@').first
  end

  def avatar_url_or_default
    avatar_url || "https://ui-avatars.com/api/?name=#{URI.encode_www_form_component(display_name)}&size=200"
  end

  # Security methods
  def record_login(ip_address, user_agent = nil)
    login_record = {
      ip: ip_address,
      user_agent: user_agent,
      timestamp: Time.current.iso8601,
      location: detect_location(ip_address)
    }

    history = (login_history || []).last(50)
    history << login_record
    update_column(:login_history, history)

    detect_suspicious_login(ip_address)
  end

  def detect_suspicious_login(ip_address)
    return false if login_history.blank? || login_history.size < 2

    recent_ips = login_history.last(5).map { |h| h['ip'] }.compact.uniq
    is_suspicious = !recent_ips.include?(ip_address) && recent_ips.size >= 3

    if is_suspicious && security_alerts_enabled
      update_column(:suspicious_login_detected, true)
      # TODO: Send email notification
    end

    is_suspicious
  end

  def detect_location(ip_address)
    # Placeholder - integrate with IP geolocation service
    "Unknown"
  end

  def active_for_authentication?
    super && account_status_active?
  end

  def inactive_message
    account_status_active? ? super : :account_deactivated
  end

  # Session timeout
  def timeout_in
    2.hours
  end

  private

  def auto_confirm_in_non_production
    confirm if respond_to?(:confirm)
  end

  def password_complexity
    return if password.blank?

    if password.length < 8
      errors.add :password, "비밀번호 복잡도: 8자 이상이어야 합니다"
    end
    unless password.match?(/[A-Z]/)
      errors.add :password, "비밀번호 복잡도: 대문자를 포함해야 합니다"
    end
    unless password.match?(/[a-z]/)
      errors.add :password, "비밀번호 복잡도: 소문자를 포함해야 합니다"
    end
    unless password.match?(/[0-9]/)
      errors.add :password, "비밀번호 복잡도: 숫자를 포함해야 합니다"
    end
    unless password.match?(/[^A-Za-z0-9]/)
      errors.add :password, "비밀번호 복잡도: 특수문자를 포함해야 합니다"
    end
  end

  def check_malicious_input
    # SQL Injection 패턴 체크
    sql_patterns = [
      /(\bOR\b.*=.*|;\s*DROP\s+TABLE|UNION\s+SELECT|--|\bAND\b.*=.*)/i,
      /('|")\s*(OR|AND)\s*\1\s*=\s*\1/i
    ]

    # XSS 패턴 체크
    xss_patterns = [
      /<script[^>]*>.*?<\/script>/im,
      /javascript:/i,
      /on\w+\s*=/i
    ]

    [email, name].compact.each do |field_value|
      sql_patterns.each do |pattern|
        if field_value.to_s.match?(pattern)
          errors.add :base, "유효하지 않은 입력이 감지되었습니다"
          return
        end
      end

      xss_patterns.each do |pattern|
        if field_value.to_s.match?(pattern)
          errors.add :base, "유효하지 않은 입력이 감지되었습니다"
          return
        end
      end
    end
  end

  def strict_email_format
    return if email.blank?

    # 기본적인 이메일 형식 체크
    unless email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      errors.add :email, "유효한 이메일 주소를 입력하세요"
      return
    end

    # 연속된 점(.) 체크
    if email.match?(/\.\./)
      errors.add :email, "유효한 이메일 주소를 입력하세요"
      return
    end

    # 로컬 파트(@ 앞부분) 시작/끝이 점인지 체크
    local_part = email.split('@').first
    if local_part.start_with?('.') || local_part.end_with?('.')
      errors.add :email, "유효한 이메일 주소를 입력하세요"
      return
    end

    # 도메인 파트 시작/끝이 점인지 체크
    domain_part = email.split('@').last
    if domain_part.start_with?('.') || domain_part.end_with?('.')
      errors.add :email, "유효한 이메일 주소를 입력하세요"
      return
    end

    # 공백 체크
    if email.include?(' ')
      errors.add :email, "유효한 이메일 주소를 입력하세요"
      return
    end
  end
end
