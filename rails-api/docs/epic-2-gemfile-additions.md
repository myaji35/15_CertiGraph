# Epic 2: Required Gem Additions

## Add to Gemfile

Add these gems to your `Gemfile` if not already present:

```ruby
# Epic 2: PDF Upload & Storage - AWS S3 Integration
gem 'aws-sdk-s3', '~> 1.0'
gem 'aws-sdk-core', '~> 3.0'

# CORS support (already included if using rack-cors)
gem 'rack-cors'

# Optional: PDF processing and validation
gem 'pdf-reader', '~> 2.11'

# Optional: MIME type detection (built into Rails 7.2+)
# gem 'marcel', '~> 1.0'
```

## Installation

```bash
bundle install
```

## Verification

Check that gems are installed:

```bash
bundle list | grep aws-sdk
bundle list | grep rack-cors
bundle list | grep pdf-reader
```

Expected output:
```
  * aws-sdk-core (3.x.x)
  * aws-sdk-s3 (1.x.x)
  * rack-cors (2.x.x)
  * pdf-reader (2.11.x)
```

## Testing in Console

```bash
rails console

# Test AWS SDK
require 'aws-sdk-s3'
s3_client = Aws::S3::Client.new(
  region: ENV['AWS_REGION'],
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
)

# Test PDF Reader
require 'pdf-reader'
reader = PDF::Reader.new('/path/to/test.pdf')
puts reader.page_count
```

## Production Considerations

1. **AWS SDK**: Required for S3 direct upload functionality
2. **CORS**: Already included in most Rails setups
3. **PDF Reader**: Optional but recommended for validation
4. **Image Processing**: Add if you need thumbnail generation:
   ```ruby
   gem 'image_processing', '~> 1.2'
   ```

## Version Compatibility

- Rails 7.2+: All gems compatible
- Ruby 3.0+: All gems compatible
- Active Storage: Built into Rails 7.2

## Notes

- `aws-sdk-s3` is specifically for S3 operations
- `aws-sdk-core` is automatically included as a dependency
- `marcel` is built into Rails 7.2 for MIME type detection
- `rack-cors` should already be in your Gemfile for API CORS support
