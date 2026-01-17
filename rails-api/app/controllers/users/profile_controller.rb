class Users::ProfileController < ApplicationController
  before_action :authenticate_user!

  # GET /users/profile
  def show
    render json: {
      user: user_profile_data(current_user)
    }
  end

  # PATCH /users/profile
  def update
    if current_user.update(profile_params)
      render json: {
        success: true,
        message: 'Profile updated successfully',
        user: user_profile_data(current_user)
      }
    else
      render json: {
        error: 'Failed to update profile',
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /users/profile/avatar
  def upload_avatar
    if params[:avatar].blank?
      return render json: { error: 'No avatar file provided' }, status: :unprocessable_entity
    end

    current_user.avatar.attach(params[:avatar])

    if current_user.avatar.attached?
      render json: {
        success: true,
        message: 'Avatar uploaded successfully',
        avatar_url: url_for(current_user.avatar)
      }
    else
      render json: { error: 'Failed to upload avatar' }, status: :unprocessable_entity
    end
  end

  # DELETE /users/profile/avatar
  def delete_avatar
    if current_user.avatar.attached?
      current_user.avatar.purge
      render json: {
        success: true,
        message: 'Avatar deleted successfully'
      }
    else
      render json: { error: 'No avatar to delete' }, status: :unprocessable_entity
    end
  end

  # GET /users/profile/login_history
  def login_history
    history = current_user.login_history || []

    render json: {
      login_history: history.last(50).reverse,
      total: history.size
    }
  end

  # PATCH /users/profile/preferences
  def update_preferences
    preferences = current_user.preferences || {}
    preferences.merge!(preference_params)

    if current_user.update(preferences: preferences)
      render json: {
        success: true,
        message: 'Preferences updated successfully',
        preferences: preferences
      }
    else
      render json: {
        error: 'Failed to update preferences',
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /users/profile/notification_settings
  def update_notification_settings
    settings = current_user.notification_settings || {}
    settings.merge!(notification_params)

    if current_user.update(notification_settings: settings)
      render json: {
        success: true,
        message: 'Notification settings updated successfully',
        notification_settings: settings
      }
    else
      render json: {
        error: 'Failed to update notification settings',
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /users/profile/password
  def update_password
    if current_user.valid_password?(params[:current_password])
      if current_user.update(password: params[:new_password], password_confirmation: params[:password_confirmation])
        # Sign in again to prevent session invalidation
        sign_in(current_user, bypass: true)

        render json: {
          success: true,
          message: 'Password updated successfully'
        }
      else
        render json: {
          error: 'Failed to update password',
          errors: current_user.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Current password is incorrect' }, status: :unauthorized
    end
  end

  # POST /users/profile/deactivate
  def deactivate_account
    if current_user.valid_password?(params[:password])
      current_user.update!(
        account_status: 'deactivated',
        deactivated_at: Time.current
      )

      sign_out(current_user)

      render json: {
        success: true,
        message: 'Account deactivated successfully. You can reactivate within 30 days.'
      }
    else
      render json: { error: 'Invalid password' }, status: :unauthorized
    end
  end

  # POST /users/profile/reactivate
  def reactivate_account
    user = User.find_by(email: params[:email])

    if user && user.account_status_deactivated?
      if user.valid_password?(params[:password])
        # Check if deactivation was within 30 days
        if user.deactivated_at && user.deactivated_at > 30.days.ago
          user.update!(
            account_status: 'active',
            deactivated_at: nil
          )

          sign_in(user)

          render json: {
            success: true,
            message: 'Account reactivated successfully',
            user: user_profile_data(user)
          }
        else
          render json: {
            error: 'Account deactivation period exceeded. Please contact support.'
          }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Invalid password' }, status: :unauthorized
      end
    else
      render json: { error: 'User not found or account not deactivated' }, status: :not_found
    end
  end

  # POST /users/profile/request_deletion
  def request_deletion
    if current_user.valid_password?(params[:password])
      current_user.update!(deletion_requested_at: Time.current)

      # TODO: Schedule deletion job after 7 days

      render json: {
        success: true,
        message: 'Account deletion requested. Your account will be permanently deleted in 7 days.'
      }
    else
      render json: { error: 'Invalid password' }, status: :unauthorized
    end
  end

  # DELETE /users/profile/cancel_deletion
  def cancel_deletion
    if current_user.deletion_requested_at
      current_user.update!(deletion_requested_at: nil)

      render json: {
        success: true,
        message: 'Account deletion cancelled successfully'
      }
    else
      render json: { error: 'No deletion request found' }, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.permit(:name, :bio, :phone_number, :date_of_birth, :avatar_url, social_links: {})
  end

  def preference_params
    params.require(:preferences).permit(:language, :theme, :timezone, :email_notifications)
  end

  def notification_params
    params.require(:notification_settings).permit(
      :email_login_alerts,
      :email_password_changes,
      :email_marketing,
      :push_notifications
    )
  end

  def user_profile_data(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      display_name: user.display_name,
      bio: user.bio,
      phone_number: user.phone_number,
      date_of_birth: user.date_of_birth,
      avatar_url: user.avatar.attached? ? url_for(user.avatar) : user.avatar_url_or_default,
      role: user.role,
      account_status: user.account_status,
      provider: user.provider,
      has_oauth: user.provider.present?,
      has_password: user.encrypted_password.present?,
      two_factor_enabled: user.otp_required_for_login,
      security_alerts_enabled: user.security_alerts_enabled,
      preferences: user.preferences || {},
      notification_settings: user.notification_settings || {},
      social_links: user.social_links || {},
      created_at: user.created_at,
      deactivated_at: user.deactivated_at,
      deletion_requested_at: user.deletion_requested_at
    }
  end
end
