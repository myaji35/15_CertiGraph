module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Try to find user from session
      if verified_user = User.find_by(id: cookies.encrypted[:user_id])
        verified_user
      # Try to find user from JWT token (for API/Native clients)
      elsif verified_user = find_user_from_token
        verified_user
      else
        reject_unauthorized_connection
      end
    end

    def find_user_from_token
      token = request.params[:token] || cookies[:token]
      return nil unless token

      begin
        decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
        user_id = decoded[0]['user_id']
        User.find_by(id: user_id)
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
