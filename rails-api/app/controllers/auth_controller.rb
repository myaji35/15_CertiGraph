class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:google_oauth2]

  def google_oauth2
    auth = request.env['omniauth.auth']

    # Google OAuth 정보로 사용자 찾기 또는 생성
    user = User.find_or_create_by(email: auth.info.email) do |u|
      u.name = auth.info.name
      u.password = SecureRandom.hex(16) # 랜덤 패스워드 설정 (OAuth 사용자는 비밀번호 로그인 불가)
      u.role = 'free'
    end

    # 세션에 사용자 ID 저장
    session[:user_id] = user.id

    # 홈페이지로 리다이렉트
    redirect_to root_path, notice: "#{user.name}님 환영합니다!"
  end

  def failure
    redirect_to signin_path, alert: '구글 로그인에 실패했습니다. 다시 시도해주세요.'
  end
end