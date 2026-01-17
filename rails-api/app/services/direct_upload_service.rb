# Service for handling Direct Upload to S3 with presigned URLs
# Supports both standard and multipart uploads
class DirectUploadService
  attr_reader :study_material, :file_metadata, :errors

  CHUNK_SIZE = 5.megabytes # Minimum S3 multipart chunk size
  MULTIPART_THRESHOLD = 100.megabytes
  PRESIGNED_URL_EXPIRATION = 1.hour

  def initialize(study_material, file_metadata = {})
    @study_material = study_material
    @file_metadata = file_metadata
    @errors = []
  end

  # Generate presigned URL for direct upload
  def generate_presigned_url
    validate_file_metadata!

    if requires_multipart_upload?
      generate_multipart_presigned_urls
    else
      generate_single_presigned_url
    end
  rescue StandardError => e
    @errors << "Failed to generate presigned URL: #{e.message}"
    Rails.logger.error("DirectUpload Error: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  # Complete the upload after client-side upload
  def complete_upload(blob_signed_id)
    blob = ActiveStorage::Blob.find_signed!(blob_signed_id)

    study_material.pdf_file.attach(blob)

    update_study_material_metadata(blob)

    study_material.update!(
      upload_status: 'completed',
      upload_completed_at: Time.current,
      upload_progress: 100
    )

    # Trigger processing
    ProcessPdfJob.perform_later(study_material.id)

    true
  rescue StandardError => e
    @errors << "Failed to complete upload: #{e.message}"
    study_material.update(
      upload_status: 'failed',
      upload_error: e.message
    )
    false
  end

  # Complete multipart upload
  def complete_multipart_upload(upload_id, parts)
    return false unless study_material.multipart_upload_id == upload_id

    s3_client = get_s3_client
    bucket_name = get_bucket_name
    key = generate_storage_key

    begin
      # Complete multipart upload on S3
      result = s3_client.complete_multipart_upload(
        bucket: bucket_name,
        key: key,
        upload_id: upload_id,
        multipart_upload: {
          parts: parts.map { |p| { etag: p[:etag], part_number: p[:part_number] } }
        }
      )

      # Create Active Storage blob
      blob = ActiveStorage::Blob.create!(
        key: key,
        filename: file_metadata[:filename],
        content_type: file_metadata[:content_type],
        byte_size: file_metadata[:byte_size],
        checksum: calculate_checksum(parts)
      )

      study_material.pdf_file.attach(blob)
      update_study_material_metadata(blob)

      study_material.update!(
        upload_status: 'completed',
        upload_completed_at: Time.current,
        upload_progress: 100,
        multipart_upload_id: nil
      )

      ProcessPdfJob.perform_later(study_material.id)

      true
    rescue Aws::S3::Errors::ServiceError => e
      @errors << "S3 multipart completion failed: #{e.message}"
      Rails.logger.error("S3 Multipart Error: #{e.message}")

      # Attempt to abort the multipart upload
      abort_multipart_upload(upload_id)

      study_material.update(
        upload_status: 'failed',
        upload_error: e.message
      )
      false
    end
  end

  # Abort multipart upload
  def abort_multipart_upload(upload_id)
    s3_client = get_s3_client
    bucket_name = get_bucket_name
    key = generate_storage_key

    s3_client.abort_multipart_upload(
      bucket: bucket_name,
      key: key,
      upload_id: upload_id
    )

    study_material.update(
      multipart_upload_id: nil,
      upload_status: 'aborted'
    )
  rescue Aws::S3::Errors::ServiceError => e
    Rails.logger.error("Failed to abort multipart upload: #{e.message}")
  end

  private

  def validate_file_metadata!
    required_fields = [:filename, :byte_size, :content_type]
    missing_fields = required_fields - file_metadata.keys

    if missing_fields.any?
      raise ArgumentError, "Missing required file metadata: #{missing_fields.join(', ')}"
    end

    # Validate file size
    if file_metadata[:byte_size] > 500.megabytes
      raise ArgumentError, "File size exceeds maximum limit of 500MB"
    end

    # Validate content type
    unless FileValidationService.allowed_content_type?(file_metadata[:content_type])
      raise ArgumentError, "Invalid content type: #{file_metadata[:content_type]}"
    end
  end

  def requires_multipart_upload?
    file_metadata[:byte_size] > MULTIPART_THRESHOLD
  end

  def generate_single_presigned_url
    key = generate_storage_key

    presigned_url = get_s3_presigner.presigned_url(
      :put_object,
      bucket: get_bucket_name,
      key: key,
      expires_in: PRESIGNED_URL_EXPIRATION.to_i,
      acl: 'private',
      content_type: file_metadata[:content_type],
      content_length: file_metadata[:byte_size]
    )

    study_material.update!(
      upload_status: 'in_progress',
      upload_started_at: Time.current,
      file_size: file_metadata[:byte_size],
      mime_type: file_metadata[:content_type]
    )

    {
      type: 'single',
      url: presigned_url,
      key: key,
      headers: {
        'Content-Type' => file_metadata[:content_type],
        'Content-Length' => file_metadata[:byte_size].to_s
      }
    }
  end

  def generate_multipart_presigned_urls
    key = generate_storage_key
    s3_client = get_s3_client
    bucket_name = get_bucket_name

    # Initiate multipart upload
    response = s3_client.create_multipart_upload(
      bucket: bucket_name,
      key: key,
      content_type: file_metadata[:content_type],
      acl: 'private'
    )

    upload_id = response.upload_id

    # Calculate number of parts
    num_parts = (file_metadata[:byte_size].to_f / CHUNK_SIZE).ceil

    # Generate presigned URLs for each part
    presigned_urls = (1..num_parts).map do |part_number|
      {
        part_number: part_number,
        url: get_s3_presigner.presigned_url(
          :upload_part,
          bucket: bucket_name,
          key: key,
          upload_id: upload_id,
          part_number: part_number,
          expires_in: PRESIGNED_URL_EXPIRATION.to_i
        )
      }
    end

    study_material.update!(
      multipart_upload_id: upload_id,
      upload_status: 'in_progress',
      upload_started_at: Time.current,
      file_size: file_metadata[:byte_size],
      mime_type: file_metadata[:content_type],
      chunk_count: num_parts,
      chunks_uploaded: 0
    )

    {
      type: 'multipart',
      upload_id: upload_id,
      key: key,
      chunk_size: CHUNK_SIZE,
      parts: presigned_urls
    }
  end

  def generate_storage_key
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    secure_random = SecureRandom.hex(8)
    filename = file_metadata[:filename].parameterize

    "study_materials/#{study_material.study_set_id}/#{timestamp}_#{secure_random}_#{filename}"
  end

  def update_study_material_metadata(blob)
    study_material.update!(
      file_size: blob.byte_size,
      file_checksum: blob.checksum,
      mime_type: blob.content_type,
      storage_usage_bytes: blob.byte_size,
      last_accessed_at: Time.current
    )
  end

  def calculate_checksum(parts)
    # Combine ETags to create a checksum
    # This is a simplified version - in production, use proper MD5 calculation
    Digest::MD5.hexdigest(parts.map { |p| p[:etag] }.join)
  end

  def get_s3_client
    @s3_client ||= Aws::S3::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def get_s3_presigner
    @s3_presigner ||= Aws::S3::Presigner.new(client: get_s3_client)
  end

  def get_bucket_name
    ENV['AWS_S3_BUCKET'] || "certigraph-#{Rails.env}"
  end
end
