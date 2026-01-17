Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2,
    ENV['GOOGLE_CLIENT_ID'] || 'your-google-client-id',
    ENV['GOOGLE_CLIENT_SECRET'] || 'your-google-client-secret',
    {
      scope: 'email,profile',
      prompt: 'select_account',
      image_aspect_ratio: 'square',
      image_size: 200,
      name: 'google_oauth2'
    }

  # Naver OAuth
  provider :naver,
    ENV['NAVER_CLIENT_ID'] || 'your-naver-client-id',
    ENV['NAVER_CLIENT_SECRET'] || 'your-naver-client-secret',
    {
      name: 'naver'
    }
end

OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# Handle OAuth failures gracefully
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}