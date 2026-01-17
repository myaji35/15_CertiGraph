class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :check_session_expiry, if: :user_signed_in?

  # Devise가 current_user와 authenticate_user!를 제공하므로
  # 중복 정의를 피하기 위해 제거하거나 Devise 메소드 사용

  private

  def check_session_expiry
    # Check if session is expired based on last activity
    if session[:last_activity_at]
      last_activity = Time.parse(session[:last_activity_at])
      if last_activity < 30.minutes.ago
        sign_out current_user
        flash[:alert] = '세션이 만료되었습니다. 다시 로그인해주세요.'
        redirect_to new_user_session_path
      else
        # Update last activity timestamp
        session[:last_activity_at] = Time.current.to_s
      end
    else
      session[:last_activity_at] = Time.current.to_s
    end
  end
end
