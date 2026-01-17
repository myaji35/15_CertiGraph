class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :html, :json

  # GET /signup
  def new
    super
  end

  # POST /signup
  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)

        respond_to do |format|
          format.html { redirect_to after_sign_up_path_for(resource) }
          format.json {
            render json: {
              success: true,
              message: '회원가입이 완료되었습니다.',
              user: user_data(resource),
              token: resource.generate_jwt
            }, status: :created
          }
        end
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!

        respond_to do |format|
          format.html { redirect_to after_inactive_sign_up_path_for(resource) }
          format.json {
            render json: {
              success: true,
              message: resource.inactive_message,
              requires_confirmation: true
            }, status: :ok
          }
        end
      end
    else
      clean_up_passwords resource
      set_minimum_password_length

      # Set flash message for validation errors
      flash.now[:alert] = resource.errors.full_messages.join(', ')

      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json {
          render json: {
            success: false,
            errors: resource.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  # GET /users/edit
  def edit
    super
  end

  # PUT /users
  def update
    super
  end

  # DELETE /users
  def destroy
    super
  end

  protected

  # 회원가입 성공 후 리다이렉션 경로
  def after_sign_up_path_for(resource)
    dashboard_index_path
  end

  # 비활성 사용자 리다이렉션 경로
  def after_inactive_sign_up_path_for(resource)
    root_path
  end

  # 업데이트 성공 후 리다이렉션 경로
  def after_update_path_for(resource)
    dashboard_index_path
  end

  private

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

  def sign_up_params
    user_params = params.require(:user).permit(:email, :password, :password_confirmation, :name, :terms_agreed, :privacy_agreed, :marketing_agreed, :phone_number)
    # Map marketingAgreed from form to marketing_agreed for user model
    # If marketingAgreed param exists and is '1', set to true; otherwise false
    user_params[:marketing_agreed] = params[:marketingAgreed] == '1'
    user_params
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :name)
  end
end
