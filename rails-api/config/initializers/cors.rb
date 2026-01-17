# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:3000", "http://localhost:3001"

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end

  # Epic 2: Direct Upload to S3 - Allow presigned URL requests
  allow do
    origins '*' # S3 direct uploads can come from any origin with presigned URLs

    resource '/rails/active_storage/direct_uploads',
      headers: :any,
      methods: [:post, :options],
      credentials: false

    resource '/study_sets/*/uploads/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options],
      credentials: false
  end
end
