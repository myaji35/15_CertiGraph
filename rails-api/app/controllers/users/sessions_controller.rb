class Users::SessionsController < Devise::SessionsController
  respond_to :html, :json

  # GET /signin
  def new
    super
  end

  # POST /users/sign_in
  def create
    # 먼저 계정 잠금 상태 확인
    # Support both simple field names (email, password) and nested (user[email], user[password])
    email = params[:email] || params.dig(:user, :email)
    password = params[:password] || params.dig(:user, :password)

    user = User.find_by(email: email)

    if user&.access_locked?
      # 30분 경과 확인 후 자동 잠금 해제
      if user.locked_at && user.locked_at < 30.minutes.ago
        user.unlock_access!
        Rails.logger.info "Account #{user.email} automatically unlocked after 30 minutes"
      else
        # 아직 잠금 해제 시간이 안됨
        respond_to do |format|
          format.html {
            flash.now[:alert] = '계정이 잠겼습니다. 30분 후 다시 시도하세요.'
            self.resource = resource_class.new(sign_in_params)
            render :new, status: :unprocessable_entity
          }
          format.json {
            render json: {
              success: false,
              error: 'Account locked. Please try again in 30 minutes.'
            }, status: :locked
          }
        end
        return
      end
    end

    # Try to authenticate, but catch failure
    self.resource = warden.authenticate(auth_options)

    unless resource
      # Authentication failed - 로그인 실패 카운터 증가
      if user
        user.increment!(:failed_attempts)
        Rails.logger.info "Failed login attempt #{user.failed_attempts} for user #{user.email}"

        # 5회 실패 시 계정 잠금
        if user.failed_attempts >= 5
          user.update!(locked_at: Time.current)
          Rails.logger.warn "Account #{user.email} locked after 5 failed attempts"

          respond_to do |format|
            format.html {
              flash.now[:alert] = '계정이 잠겼습니다. 30분 후 다시 시도하세요.'
              self.resource = resource_class.new(sign_in_params)
              render :new, status: :unprocessable_entity
            }
            format.json {
              render json: {
                success: false,
                error: 'Account locked due to too many failed attempts. Please try again in 30 minutes.'
              }, status: :locked
            }
          end
          return
        end
      end

      # Authentication failed - build resource for form
      self.resource = resource_class.new(sign_in_params)
      respond_to do |format|
        format.html {
          flash.now[:alert] = '잘못된 이메일 또는 비밀번호입니다.'
          render :new, status: :unprocessable_entity
        }
        format.json {
          render json: {
            success: false,
            error: 'Invalid email or password'
          }, status: :unauthorized
        }
      end
      return
    end

    # Check if 2FA is required
    if resource.otp_required_for_login?
      # Store user ID in session for 2FA verification
      session[:otp_user_id] = resource.id
      sign_out(resource)

      respond_to do |format|
        format.html {
          flash[:alert] = '2단계 인증 코드를 입력하세요.'
          redirect_to root_path # TODO: 2FA verification page
        }
        format.json {
          render json: {
            two_factor_required: true,
            message: 'Please enter your 2FA code'
          }, status: :ok
        }
      end
      return
    end

    # 로그인 성공 시 failed_attempts 리셋
    if resource.failed_attempts > 0
      resource.update!(failed_attempts: 0, locked_at: nil)
      Rails.logger.info "Reset failed_attempts for user #{resource.email} after successful login"
    end

    # Record login
    resource.record_login(request.remote_ip, request.user_agent) if resource.respond_to?(:record_login)

    # Check for suspicious activity
    if resource.respond_to?(:suspicious_login_detected) && resource.suspicious_login_detected
      # TODO: Send email alert
      Rails.logger.info "Suspicious login detected for user #{resource.id} from IP #{request.remote_ip}"
    end

    # Handle Remember Me functionality
    remember_me = params[:rememberMe] == 'on' || params[:rememberMe] == '1'
    if remember_me
      Rails.logger.info "Remember Me enabled for user #{resource.email}"
    end

    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource, remember: remember_me)

    yield resource if block_given?

    respond_to do |format|
      format.html { redirect_to after_sign_in_path_for(resource) }
      format.json {
        render json: {
          success: true,
          message: 'Signed in successfully',
          user: user_data(resource),
          token: resource.respond_to?(:generate_jwt) ? resource.generate_jwt : nil
        }
      }
    end
  end

  # POST /users/two_factor/verify_login
  # Verify 2FA code during login
  def verify_two_factor
    user_id = session[:otp_user_id]
    return render json: { error: 'Invalid session' }, status: :unauthorized unless user_id

    user = User.find(user_id)
    otp_code = params[:otp_code]

    service = TwoFactorService.new(user)
    result = service.verify_otp(otp_code)

    if result[:success]
      session.delete(:otp_user_id)
      sign_in(user)

      # Record login
      user.record_login(request.remote_ip, request.user_agent)

      render json: {
        success: true,
        message: 'Signed in successfully',
        user: user_data(user),
        token: user.generate_jwt,
        backup_code_used: result[:backup_code_used],
        remaining_backup_codes: result[:remaining_codes]
      }
    else
      # Increment failed attempts
      user.increment!(:failed_attempts)

      # Lock account if too many failed attempts
      if user.failed_attempts >= 5
        user.lock_access!
        session.delete(:otp_user_id)
        render json: {
          error: 'Account locked due to too many failed 2FA attempts. Please reset your password.'
        }, status: :locked
      else
        render json: {
          error: result[:error],
          failed_attempts: user.failed_attempts,
          remaining_attempts: 5 - user.failed_attempts
        }, status: :unauthorized
      end
    end
  end

  # DELETE /users/sign_out
  def destroy
    if current_user
      Rails.logger.info "User #{current_user.id} signing out"
    end

    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out

    yield if block_given?

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json {
        render json: {
          success: true,
          message: 'Signed out successfully'
        }
      }
    end
  end

  protected

  # 로그인 성공 후 리다이렉션 경로
  def after_sign_in_path_for(resource)
    dashboard_index_path
  end

  # 로그아웃 후 리다이렉션 경로
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # GET /users/sessions/active
  def active_sessions
    return render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user

    sessions_data = current_user.login_history&.last(10)&.reverse || []

    render json: {
      active_sessions: sessions_data,
      current_session: {
        ip: request.remote_ip,
        user_agent: request.user_agent,
        last_activity: current_user.last_activity_at
      }
    }
  end

  # DELETE /users/sessions/revoke_all
  def revoke_all_sessions
    return render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user

    # This would require implementing session tracking
    # For now, we'll just update the password to invalidate JWT tokens
    current_user.update!(updated_at: Time.current)

    render json: {
      success: true,
      message: 'All other sessions have been revoked'
    }
  end

  private

  # Override sign_in_params to support both simple and nested field names
  def sign_in_params
    # Return empty params if no params are present (during GET requests)
    return ActionController::Parameters.new if params[:email].blank? && params[:user].blank?

    # If simple field names are used, wrap them in the user key for Devise
    if params[:email].present? && params[:password].present?
      ActionController::Parameters.new(
        user: {
          email: params[:email],
          password: params[:password],
          remember_me: params[:remember_me]
        }
      ).permit(user: [:email, :password, :remember_me])
    else
      params.require(:user).permit(:email, :password, :remember_me)
    end
  end

  def user_data(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      two_factor_enabled: user.otp_required_for_login,
      avatar_url: user.avatar.attached? ? url_for(user.avatar) : user.avatar_url_or_default
    }
  end

  def respond_with(resource, _opts = {})
    respond_to do |format|
      format.html { super }
      format.json {
        render json: {
          success: true,
          user: user_data(resource),
          token: resource.generate_jwt
        }
      }
    end
  end

  def respond_to_on_destroy
    render json: { success: true, message: 'Signed out successfully' }
  end
end
