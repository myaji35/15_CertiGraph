# Epic 2: Production Deployment Checklist

## Pre-Deployment Setup

### 1. Database Migration
- [ ] Run migration: `rails db:migrate`
- [ ] Verify migration: `rails db:migrate:status`
- [ ] Check new columns in `study_materials` table

### 2. Gem Installation
- [ ] Add `aws-sdk-s3` to Gemfile
- [ ] Run `bundle install`
- [ ] Verify gems: `bundle list | grep aws-sdk`

### 3. AWS S3 Setup
- [ ] Create AWS account / IAM user
- [ ] Generate Access Key ID and Secret Access Key
- [ ] Create S3 bucket: `aws s3 mb s3://certigraph-production`
- [ ] Set bucket region (e.g., us-east-1)
- [ ] Configure bucket lifecycle rules (optional)

### 4. S3 CORS Configuration
- [ ] Create CORS configuration file (use `docs/epic-2-s3-cors-config.json`)
- [ ] Apply CORS: `aws s3api put-bucket-cors --bucket <bucket-name> --cors-configuration file://cors.json`
- [ ] Verify CORS: `aws s3api get-bucket-cors --bucket <bucket-name>`

### 5. Environment Variables
- [ ] Copy `.env.example` to `.env`
- [ ] Set `AWS_ACCESS_KEY_ID`
- [ ] Set `AWS_SECRET_ACCESS_KEY`
- [ ] Set `AWS_REGION`
- [ ] Set `AWS_S3_BUCKET`
- [ ] Set `APP_HOST`
- [ ] Verify with: `rails runner "puts ENV['AWS_S3_BUCKET']"`

### 6. Active Storage Configuration
- [ ] Verify `config/storage.yml` has `amazon` service configured
- [ ] Update `config/environments/production.rb` to use `:amazon` service
- [ ] Test configuration: `rails runner "puts ActiveStorage::Blob.service.class"`

### 7. Background Jobs
- [ ] Verify Solid Queue is configured
- [ ] Test job queue: `rails solid_queue:start`
- [ ] Set up process manager (systemd, PM2, etc.)

### 8. Scheduled Tasks
- [ ] Configure daily cleanup: `CleanupStorageJob`
- [ ] Set up cron job or scheduling system
- [ ] Test manual cleanup: `rails runner "CleanupStorageJob.perform_now"`

## Testing Checklist

### Unit Tests
- [ ] Test DirectUploadService
- [ ] Test ChunkedUploadService
- [ ] Test FileValidationService
- [ ] Test StorageCleanupService

### Integration Tests
- [ ] Test UploadsController endpoints
- [ ] Test file upload flow
- [ ] Test chunked upload flow
- [ ] Test error scenarios

### Manual Testing
- [ ] Upload small PDF (< 5MB)
- [ ] Upload medium PDF (5-100MB)
- [ ] Upload large PDF (100MB+)
- [ ] Test invalid file type (should reject)
- [ ] Test oversized file (> 500MB, should reject)
- [ ] Test duplicate file (should detect)
- [ ] Test pause/resume
- [ ] Test cancellation
- [ ] Test network interruption recovery
- [ ] Verify file appears in S3
- [ ] Verify background processing triggers
- [ ] Test download from S3

## Security Checklist

### AWS Security
- [ ] Use IAM user with minimal permissions (not root)
- [ ] Enable S3 bucket encryption
- [ ] Set bucket to private (no public access)
- [ ] Use presigned URLs only
- [ ] Rotate access keys regularly
- [ ] Enable AWS CloudTrail logging

### Application Security
- [ ] CSRF protection enabled
- [ ] CORS properly configured
- [ ] File validation enabled
- [ ] File size limits enforced
- [ ] MIME type whitelist active
- [ ] Checksum verification enabled
- [ ] Rate limiting configured (optional)

### Optional: Malware Scanning
- [ ] Install ClamAV: `brew install clamav` or `apt-get install clamav`
- [ ] Update virus definitions: `freshclam`
- [ ] Start daemon: `clamd`
- [ ] Test scan: `clamdscan /path/to/file.pdf`

## Performance Optimization

### S3 Configuration
- [ ] Consider enabling S3 Transfer Acceleration
- [ ] Set up CloudFront CDN (optional)
- [ ] Configure S3 Intelligent-Tiering
- [ ] Set lifecycle rules for old files

### Application Optimization
- [ ] Optimize chunk size (default 5MB)
- [ ] Configure connection pool
- [ ] Enable Rack::Deflater for compression
- [ ] Set appropriate timeouts

### Monitoring
- [ ] Set up AWS CloudWatch
- [ ] Monitor S3 storage usage
- [ ] Track upload success/failure rates
- [ ] Monitor background job performance
- [ ] Set up alerts for failures

## Production Launch

### Day of Launch
- [ ] Deploy code to production
- [ ] Run database migrations
- [ ] Verify environment variables
- [ ] Start background job workers
- [ ] Test upload functionality
- [ ] Monitor error logs
- [ ] Check S3 connectivity

### First Week
- [ ] Monitor upload success rates
- [ ] Check storage growth
- [ ] Review error logs daily
- [ ] Test cleanup jobs
- [ ] Monitor AWS costs
- [ ] Gather user feedback

### First Month
- [ ] Analyze storage statistics
- [ ] Optimize chunk size if needed
- [ ] Review security logs
- [ ] Assess cost vs usage
- [ ] Plan optimizations
- [ ] Consider CloudFront

## Rollback Plan

If issues arise:

1. **Immediate Rollback**
   ```bash
   # Revert migration
   rails db:rollback STEP=1

   # Switch back to local storage
   # In production.rb:
   config.active_storage.service = :local
   ```

2. **Preserve User Data**
   - Existing uploads remain in S3
   - Can restore when issues resolved
   - No data loss

3. **Re-enable When Ready**
   - Fix issues
   - Re-run migration
   - Switch back to `:amazon` service
   - Resume uploads

## Monitoring Dashboard

Track these metrics:

### Daily
- Total uploads
- Success rate
- Failure rate
- Average file size
- Total storage used

### Weekly
- Storage growth trend
- Top error types
- Cleanup job results
- User adoption rate

### Monthly
- Total AWS costs
- Storage optimization savings
- Performance improvements
- User satisfaction

## Support & Maintenance

### Regular Tasks
- **Daily**: Check error logs, monitor uploads
- **Weekly**: Review statistics, check cleanup
- **Monthly**: Cost analysis, performance review
- **Quarterly**: Security audit, optimization

### Contact Information
- AWS Support: https://console.aws.amazon.com/support
- Rails Active Storage Docs: https://guides.rubyonrails.org/active_storage_overview.html
- Epic 2 Documentation: `docs/epic-2-upload-storage-guide.md`

## Success Metrics

Target goals:

- [ ] Upload success rate > 99%
- [ ] Average upload time < 2 minutes for 100MB
- [ ] Storage cleanup runs daily without errors
- [ ] Zero security incidents
- [ ] User satisfaction > 90%
- [ ] AWS costs within budget
- [ ] Background jobs process within 10 minutes

## Post-Launch Optimization

### Phase 1 (Month 1)
- [ ] Gather metrics
- [ ] Identify bottlenecks
- [ ] Optimize chunk size
- [ ] Fine-tune timeouts

### Phase 2 (Month 2-3)
- [ ] Implement CloudFront
- [ ] Add upload analytics
- [ ] Optimize storage costs
- [ ] Enhance monitoring

### Phase 3 (Month 4+)
- [ ] Advanced deduplication
- [ ] Compression strategies
- [ ] Multi-region support
- [ ] Enhanced security

## Compliance & Legal

If applicable:

- [ ] GDPR compliance (EU users)
- [ ] Data retention policies
- [ ] User data export capability
- [ ] Right to deletion
- [ ] Terms of service updated
- [ ] Privacy policy updated

## Documentation

Ensure team has access to:

- [ ] `docs/epic-2-upload-storage-guide.md` (Full guide)
- [ ] `docs/epic-2-quick-start.md` (Quick setup)
- [ ] `docs/epic-2-summary.md` (Overview)
- [ ] `docs/epic-2-deployment-checklist.md` (This file)
- [ ] API documentation
- [ ] Troubleshooting guide

## Final Sign-off

- [ ] All checklist items completed
- [ ] Tests passing
- [ ] Production deployed successfully
- [ ] Monitoring active
- [ ] Team trained
- [ ] Documentation complete
- [ ] Stakeholders notified

---

**Date Deployed**: ________________

**Deployed By**: ________________

**Verified By**: ________________

**Notes**: ________________

---

**Status: Epic 2 is ready for production deployment! 🚀**
