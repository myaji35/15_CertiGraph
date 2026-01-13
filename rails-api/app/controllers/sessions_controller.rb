class SessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: '로그인되었습니다.'
    else
      flash.now[:alert] = '이메일 또는 비밀번호가 올바르지 않습니다.'
      render 'home/signin'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: '로그아웃되었습니다.'
  end
end