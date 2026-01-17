class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:google_oauth2, :naver]

  # Google OAuth2 callback
  def google_oauth2
    handle_oauth('Google')
  end

  # Naver OAuth callback
  def naver
    handle_oauth('Naver')
  end

  # OAuth failure callback
  def failure
    flash[:alert] = "Authentication failed: #{failure_message}"
    redirect_to root_path
  end

  private

  def handle_oauth(provider_name)
    auth_hash = request.env['omniauth.auth']
    service = OauthService.new(auth_hash)
    result = service.find_or_create_user

    if result[:success]
      user = result[:user]

      # Record login
      user.record_login(request.remote_ip, request.user_agent)

      # Check for suspicious activity
      if user.suspicious_login_detected && user.security_alerts_enabled
        Rails.logger.info "Suspicious login detected for user #{user.id} via #{provider_name}"
        # TODO: Send email notification
      end

      sign_in_and_redirect user, event: :authentication

      case result[:action]
      when 'created'
        set_flash_message(:notice, :success, kind: provider_name) if is_navigational_format?
        flash[:notice] = "Successfully signed up with #{provider_name}"
      when 'linked'
        flash[:notice] = "Successfully linked #{provider_name} account"
      else
        set_flash_message(:notice, :success, kind: provider_name) if is_navigational_format?
        flash[:notice] = "Successfully signed in with #{provider_name}"
      end
    else
      session["devise.#{auth_hash['provider']}_data"] = auth_hash.except('extra')
      redirect_to new_user_registration_url, alert: result[:error]
    end
  rescue StandardError => e
    Rails.logger.error "OAuth Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  def failure_message
    exception = request.env['omniauth.error']
    error_type = request.env['omniauth.error.type']
    return exception.error_reason if exception.respond_to?(:error_reason)
    return exception.error if exception.respond_to?(:error)
    error_type.to_s.humanize if error_type
  end

  # API mode support
  def after_omniauth_failure_path_for(scope)
    root_path
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end
end