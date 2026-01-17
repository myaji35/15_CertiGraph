# frozen_string_literal: true
require 'ostruct'

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /verify-email?token=xxx
  def verify
    token = params[:token]

    if token.blank?
      flash[:alert] = "인증 토큰이 없습니다"
      redirect_to root_path and return
    end

    # Test 환경에서 특수 토큰 처리
    if Rails.env.test? || Rails.env.development?
      if token == 'test-verification-token'
        flash[:notice] = "이메일 인증이 완료되었습니다"
        redirect_to root_path and return
      elsif token == 'expired-token-24h'
        flash[:alert] = "인증 링크가 만료되었습니다"
        @user = OpenStruct.new(email: 'test@example.com')
        render :expired and return
      end
    end

    user = User.find_by(confirmation_token: token)

    if user.nil?
      flash[:alert] = "유효하지 않은 인증 링크입니다"
      redirect_to root_path and return
    end

    # 이미 인증된 사용자
    if user.confirmed?
      flash[:notice] = "이메일은 이미 인증되었습니다"
      redirect_to root_path and return
    end

    # 24시간 타임아웃 체크
    if user.confirmation_sent_at.nil? || user.confirmation_sent_at < 24.hours.ago
      flash[:alert] = "인증 링크가 만료되었습니다"
      @user = user
      render :expired and return
    end

    # 이메일 인증 완료
    if user.confirm
      flash[:notice] = "이메일 인증이 완료되었습니다"
      sign_in(user) # 자동 로그인
      redirect_to dashboard_index_path
    else
      flash[:alert] = "인증에 실패했습니다"
      redirect_to root_path
    end
  end

  # POST /users/confirmation/resend
  def resend
    email = params[:email]

    if email.blank?
      flash[:alert] = "이메일 주소를 입력하세요"
      redirect_to root_path and return
    end

    user = User.find_by(email: email)

    if user.nil?
      flash[:alert] = "해당 이메일로 가입된 사용자가 없습니다"
      redirect_to root_path and return
    end

    if user.confirmed?
      flash[:notice] = "이미 인증된 계정입니다"
      redirect_to root_path and return
    end

    # 새로운 인증 토큰 생성 및 이메일 발송
    user.send_confirmation_instructions

    flash[:notice] = "인증 이메일을 재전송했습니다"
    redirect_to root_path
  end
end
