class TwoFactorService
  require 'rotp'
  require 'rqrcode'

  def initialize(user)
    @user = user
  end

  # Generate QR code for TOTP setup
  def generate_qr_code
    return { error: '2FA is already enabled' } if @user.otp_required_for_login

    # Generate new OTP secret if not exists
    unless @user.otp_secret
      @user.otp_secret = ROTP::Base32.random
      @user.save!
    end

    totp = ROTP::TOTP.new(@user.otp_secret, issuer: 'CertiGraph')
    provisioning_uri = totp.provisioning_uri(@user.email)

    qr_code = RQRCode::QRCode.new(provisioning_uri)
    svg = qr_code.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 6,
      standalone: true
    )

    {
      success: true,
      qr_code: svg,
      secret: @user.otp_secret,
      provisioning_uri: provisioning_uri
    }
  rescue StandardError => e
    { error: e.message }
  end

  # Verify TOTP code and enable 2FA
  def enable_with_verification(otp_code)
    return { error: '2FA is already enabled' } if @user.otp_required_for_login
    return { error: 'OTP secret not found' } unless @user.otp_secret

    totp = ROTP::TOTP.new(@user.otp_secret)

    if totp.verify(otp_code, drift_behind: 30, drift_ahead: 30)
      @user.otp_required_for_login = true
      backup_codes = @user.generate_otp_backup_codes!

      {
        success: true,
        message: '2FA has been enabled successfully',
        backup_codes: backup_codes
      }
    else
      { error: 'Invalid verification code' }
    end
  rescue StandardError => e
    { error: e.message }
  end

  # Verify TOTP code during login
  def verify_otp(otp_code)
    return { error: '2FA is not enabled' } unless @user.otp_required_for_login

    # Check if it's a backup code
    if @user.otp_backup_codes&.split("\n")&.include?(otp_code)
      if @user.invalidate_otp_backup_code!(otp_code)
        return {
          success: true,
          message: 'Backup code accepted',
          backup_code_used: true,
          remaining_codes: @user.otp_backup_codes&.split("\n")&.size || 0
        }
      end
    end

    # Verify TOTP code
    totp = ROTP::TOTP.new(@user.otp_secret)
    if totp.verify(otp_code, drift_behind: 30, drift_ahead: 30)
      {
        success: true,
        message: 'OTP verified successfully'
      }
    else
      { error: 'Invalid OTP code' }
    end
  rescue StandardError => e
    { error: e.message }
  end

  # Disable 2FA with verification
  def disable_with_verification(otp_code, password)
    return { error: '2FA is not enabled' } unless @user.otp_required_for_login
    return { error: 'Invalid password' } unless @user.valid_password?(password)

    verification = verify_otp(otp_code)
    return verification unless verification[:success]

    @user.disable_two_factor!

    {
      success: true,
      message: '2FA has been disabled successfully'
    }
  rescue StandardError => e
    { error: e.message }
  end

  # Regenerate backup codes
  def regenerate_backup_codes(otp_code)
    return { error: '2FA is not enabled' } unless @user.otp_required_for_login

    verification = verify_otp(otp_code)
    return verification unless verification[:success]

    backup_codes = @user.generate_otp_backup_codes!

    {
      success: true,
      message: 'Backup codes regenerated successfully',
      backup_codes: backup_codes
    }
  rescue StandardError => e
    { error: e.message }
  end

  # Get 2FA status
  def status
    {
      enabled: @user.otp_required_for_login,
      backup_codes_count: @user.otp_backup_codes ? @user.otp_backup_codes.split("\n").size : 0
    }
  end

  class << self
    # Validate OTP format
    def valid_otp_format?(code)
      code.present? && code.match?(/^\d{6}$/)
    end

    # Validate backup code format
    def valid_backup_code_format?(code)
      code.present? && code.match?(/^[a-f0-9]{8}$/)
    end
  end
end
