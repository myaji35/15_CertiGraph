class Users::TwoFactorController < ApplicationController
  before_action :authenticate_user!
  before_action :set_two_factor_service

  # GET /users/two_factor/status
  def status
    render json: @service.status
  end

  # POST /users/two_factor/setup
  # Generate QR code for 2FA setup
  def setup
    result = @service.generate_qr_code

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: {
        qr_code: result[:qr_code],
        secret: result[:secret],
        provisioning_uri: result[:provisioning_uri],
        message: 'Scan this QR code with Google Authenticator or Authy'
      }
    end
  end

  # POST /users/two_factor/enable
  # Verify OTP and enable 2FA
  def enable
    otp_code = params[:otp_code]

    unless TwoFactorService.valid_otp_format?(otp_code)
      return render json: { error: 'Invalid OTP format. Must be 6 digits.' }, status: :unprocessable_entity
    end

    result = @service.enable_with_verification(otp_code)

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: {
        success: true,
        message: result[:message],
        backup_codes: result[:backup_codes]
      }
    end
  end

  # POST /users/two_factor/verify
  # Verify OTP code (during login or sensitive operations)
  def verify
    otp_code = params[:otp_code]

    unless TwoFactorService.valid_otp_format?(otp_code) || TwoFactorService.valid_backup_code_format?(otp_code)
      return render json: { error: 'Invalid code format' }, status: :unprocessable_entity
    end

    result = @service.verify_otp(otp_code)

    if result[:error]
      render json: { error: result[:error] }, status: :unauthorized
    else
      render json: result
    end
  end

  # DELETE /users/two_factor/disable
  # Disable 2FA with verification
  def disable
    otp_code = params[:otp_code]
    password = params[:password]

    if otp_code.blank? || password.blank?
      return render json: { error: 'OTP code and password are required' }, status: :unprocessable_entity
    end

    result = @service.disable_with_verification(otp_code, password)

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: result
    end
  end

  # POST /users/two_factor/backup_codes/regenerate
  # Regenerate backup codes
  def regenerate_backup_codes
    otp_code = params[:otp_code]

    unless TwoFactorService.valid_otp_format?(otp_code)
      return render json: { error: 'Invalid OTP format' }, status: :unprocessable_entity
    end

    result = @service.regenerate_backup_codes(otp_code)

    if result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: result
    end
  end

  # GET /users/two_factor/backup_codes
  # View remaining backup codes (requires OTP verification)
  def backup_codes
    otp_code = params[:otp_code]

    unless TwoFactorService.valid_otp_format?(otp_code)
      return render json: { error: 'Invalid OTP format' }, status: :unprocessable_entity
    end

    result = @service.verify_otp(otp_code)

    if result[:error]
      render json: { error: result[:error] }, status: :unauthorized
    else
      codes = current_user.otp_backup_codes&.split("\n") || []
      render json: {
        backup_codes: codes.map { |code| { code: code, used: false } },
        total: codes.size
      }
    end
  end

  private

  def set_two_factor_service
    @service = TwoFactorService.new(current_user)
  end
end
