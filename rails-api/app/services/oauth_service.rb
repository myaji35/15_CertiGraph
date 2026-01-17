class OauthService
  def initialize(auth_hash)
    @auth = auth_hash
    @provider = auth_hash['provider']
    @uid = auth_hash['uid']
  end

  # Find or create user from OAuth data
  def find_or_create_user
    user = User.find_by(provider: @provider, uid: @uid)

    if user
      update_user_info(user)
      return { success: true, user: user, action: 'sign_in' }
    end

    # Check if user exists with same email
    existing_user = User.find_by(email: email)

    if existing_user
      # Link OAuth account to existing user
      link_oauth_account(existing_user)
      return { success: true, user: existing_user, action: 'linked' }
    end

    # Create new user
    create_new_user
  rescue StandardError => e
    { success: false, error: e.message }
  end

  # Link OAuth account to existing user
  def link_oauth_account(user)
    # Ensure OAuth users are confirmed
    user.confirm if user.respond_to?(:confirm) && !user.confirmed?

    user.update!(
      provider: @provider,
      uid: @uid,
      avatar_url: profile_image_url
    )

    { success: true, user: user, action: 'linked' }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  # Unlink OAuth account
  def self.unlink_oauth_account(user)
    return { error: 'No password set. Cannot unlink OAuth.' } if user.encrypted_password.blank?

    user.update!(provider: nil, uid: nil)
    { success: true, message: 'OAuth account unlinked successfully' }
  rescue StandardError => e
    { success: false, error: e.message }
  end

  # Extract user information from OAuth provider
  def user_attributes
    {
      email: email,
      name: name,
      provider: @provider,
      uid: @uid,
      avatar_url: profile_image_url,
      password: Devise.friendly_token[0, 20]
    }
  end

  private

  def create_new_user
    user = User.new(user_attributes)
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)

    if user.save
      { success: true, user: user, action: 'created' }
    else
      { success: false, error: user.errors.full_messages.join(', ') }
    end
  end

  def update_user_info(user)
    updates = {}
    updates[:name] = name if name.present? && user.name.blank?
    updates[:avatar_url] = profile_image_url if profile_image_url.present?

    # Ensure OAuth users are confirmed
    user.confirm if user.respond_to?(:confirm) && !user.confirmed?

    user.update(updates) if updates.any?
  end

  def email
    @auth.dig('info', 'email')
  end

  def name
    case @provider
    when 'google_oauth2'
      @auth.dig('info', 'name')
    when 'naver'
      @auth.dig('info', 'name')
    else
      @auth.dig('info', 'name') || @auth.dig('info', 'nickname')
    end
  end

  def profile_image_url
    case @provider
    when 'google_oauth2'
      @auth.dig('info', 'image')
    when 'naver'
      @auth.dig('info', 'image')
    else
      @auth.dig('info', 'image')
    end
  end

  # Provider-specific data extraction
  def self.extract_provider_data(auth)
    provider = auth['provider']

    case provider
    when 'naver'
      {
        nickname: auth.dig('info', 'nickname'),
        profile_image: auth.dig('info', 'image'),
        age: auth.dig('info', 'age'),
        gender: auth.dig('info', 'gender'),
        birthday: auth.dig('info', 'birthday'),
        mobile: auth.dig('info', 'mobile')
      }
    when 'google_oauth2'
      {
        profile_image: auth.dig('info', 'image'),
        verified_email: auth.dig('extra', 'raw_info', 'email_verified'),
        locale: auth.dig('extra', 'raw_info', 'locale')
      }
    else
      {}
    end
  end
end
