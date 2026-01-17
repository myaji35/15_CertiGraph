# Epic 2: Active Storage Configuration for Direct Upload

Rails.application.config.after_initialize do
  # Configure Active Storage for Direct Upload
  ActiveStorage::DirectUploadsController.class_eval do
    # Add custom headers for CORS
    before_action :set_cors_headers

    private

    def set_cors_headers
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept, X-CSRF-Token'
    end
  end
end

# Content types configuration
ActiveStorage.content_types_to_serve_as_binary.delete('application/pdf')
ActiveStorage.content_types_allowed_inline << 'application/pdf'

# Service URLs configuration
# Note: ActiveStorage::Current is deprecated in Rails 7.2
# Use Rails.application.routes.default_url_options instead
Rails.application.routes.default_url_options[:host] = ENV['APP_HOST'] || 'localhost:3000'
