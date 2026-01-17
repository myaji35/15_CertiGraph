# Epic 2: Quick Start Guide

## 5-Minute Setup

### 1. Run Migration

```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api
rails db:migrate
```

### 2. Install AWS SDK

Add to `Gemfile`:
```ruby
gem 'aws-sdk-s3', '~> 1.0'
```

```bash
bundle install
```

### 3. Configure Environment

Add to `.env`:
```bash
# AWS S3
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
AWS_S3_BUCKET=certigraph-production
```

### 4. Create S3 Bucket

```bash
aws s3 mb s3://certigraph-production --region us-east-1
```

### 5. Configure CORS

Create `cors.json`:
```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

Apply:
```bash
aws s3api put-bucket-cors --bucket certigraph-production --cors-configuration file://cors.json
```

### 6. Test Upload

```bash
rails console

# Create test study set
user = User.first
study_set = user.study_sets.create!(title: "Test Set")

# Test file validation
validator = FileValidationService.new("/path/to/test.pdf")
validator.validate!

# Test direct upload service
material = study_set.study_materials.create!(name: "Test")
service = DirectUploadService.new(material, {
  filename: "test.pdf",
  byte_size: 1024,
  content_type: "application/pdf"
})
presigned_data = service.generate_presigned_url
```

### 7. Start Background Jobs

```bash
bin/rails solid_queue:start
```

## That's It!

Your upload system is ready. See the full guide at `docs/epic-2-upload-storage-guide.md` for advanced features.

## Quick Test Checklist

- [ ] Migration ran successfully
- [ ] AWS credentials configured
- [ ] S3 bucket created
- [ ] CORS configured
- [ ] Services working in console
- [ ] Background jobs running

## Common Issues

**Q: Presigned URLs not working?**
A: Check AWS credentials and CORS configuration.

**Q: Upload timing out?**
A: Use chunked upload for large files.

**Q: Background jobs not processing?**
A: Ensure Solid Queue is running: `bin/rails solid_queue:start`

## Next Steps

1. Review full documentation: `docs/epic-2-upload-storage-guide.md`
2. Test upload in browser
3. Configure scheduled cleanup jobs
4. Monitor storage usage
5. Optional: Set up ClamAV malware scanning
