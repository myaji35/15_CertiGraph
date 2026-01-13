class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      flash[:notice] = "Google 계정으로 로그인했습니다."
      sign_in(:user, @user)
      redirect_to root_path
    else
      session["devise.google_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: "로그인에 실패했습니다."
    end
  end

  def failure
    redirect_to root_path, alert: "인증에 실패했습니다."
  end
end