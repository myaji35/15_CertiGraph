class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Devise가 current_user와 authenticate_user!를 제공하므로
  # 중복 정의를 피하기 위해 제거하거나 Devise 메소드 사용
end
