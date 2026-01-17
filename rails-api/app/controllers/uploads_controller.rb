# Controller for handling file uploads with Direct Upload and chunked upload support
class UploadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_set, except: [:storage_stats]
  before_action :set_study_material, only: [
    :upload_status,
    :pause_upload,
    :resume_upload,
    :cancel_upload,
    :upload_chunk,
    :complete_multipart
  ]

  # POST /study_sets/:study_set_id/uploads/prepare
  # Prepare upload and get presigned URLs
  def prepare
    # Validate upload parameters
    FileValidationService.validate_upload_params!(upload_params)

    # Check for duplicates
    checksum = upload_params[:checksum]
    if checksum.present?
      validator = FileValidationService.new(nil)
      # Note: This requires a file, so we'll check after upload
    end

    # Create study material record
    @study_material = @study_set.study_materials.build(
      name: upload_params[:filename],
      file_size: upload_params[:byte_size],
      mime_type: upload_params[:content_type],
      file_checksum: checksum,
      upload_status: 'preparing'
    )

    if @study_material.save
      # Generate presigned URLs
      service = DirectUploadService.new(@study_material, upload_params)
      presigned_data = service.generate_presigned_url

      if presigned_data
        render json: {
          success: true,
          upload_id: @study_material.id,
          upload_type: presigned_data[:type],
          presigned_data: presigned_data
        }, status: :ok
      else
        render json: {
          success: false,
          errors: service.errors
        }, status: :unprocessable_entity
      end
    else
      render json: {
        success: false,
        errors: @study_material.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue FileValidationService::ValidationError => e
    render json: {
      success: false,
      errors: [e.message]
    }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Upload preparation error: #{e.message}\n#{e.backtrace.join("\n")}")
    render json: {
      success: false,
      errors: ["Upload preparation failed: #{e.message}"]
    }, status: :internal_server_error
  end

  # POST /study_sets/:study_set_id/uploads/:id/complete
  # Complete Direct Upload (single file)
  def complete
    service = DirectUploadService.new(@study_material)

    if service.complete_upload(params[:blob_signed_id])
      render json: {
        success: true,
        study_material: study_material_json(@study_material)
      }, status: :ok
    else
      render json: {
        success: false,
        errors: service.errors
      }, status: :unprocessable_entity
    end
  end

  # POST /study_sets/:study_set_id/uploads/:id/chunk
  # Upload a chunk (for chunked uploads)
  def upload_chunk
    service = ChunkedUploadService.new(@study_material)

    chunk_data = params[:chunk].read
    chunk_number = params[:chunk_number].to_i
    total_chunks = params[:total_chunks].to_i

    result = service.process_chunk(chunk_number, chunk_data, total_chunks)

    render json: result, status: result[:success] ? :ok : :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Chunk upload error: #{e.message}")
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end

  # POST /study_sets/:study_set_id/uploads/:id/complete_multipart
  # Complete multipart upload (S3 multipart)
  def complete_multipart
    service = DirectUploadService.new(@study_material)

    upload_id = params[:upload_id]
    parts = params[:parts] || []

    if service.complete_multipart_upload(upload_id, parts)
      render json: {
        success: true,
        study_material: study_material_json(@study_material)
      }, status: :ok
    else
      render json: {
        success: false,
        errors: service.errors
      }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Multipart completion error: #{e.message}")
    render json: {
      success: false,
      errors: [e.message]
    }, status: :internal_server_error
  end

  # GET /study_sets/:study_set_id/uploads/:id/status
  # Get upload status
  def upload_status
    service = ChunkedUploadService.new(@study_material)
    status = service.upload_status

    render json: {
      success: true,
      status: status
    }, status: :ok
  end

  # POST /study_sets/:study_set_id/uploads/:id/pause
  # Pause upload
  def pause_upload
    service = ChunkedUploadService.new(@study_material)

    if service.pause_upload
      render json: {
        success: true,
        message: 'Upload paused'
      }, status: :ok
    else
      render json: {
        success: false,
        message: 'Failed to pause upload'
      }, status: :unprocessable_entity
    end
  end

  # POST /study_sets/:study_set_id/uploads/:id/resume
  # Resume upload
  def resume_upload
    service = ChunkedUploadService.new(@study_material)
    result = service.resume_upload

    if result
      render json: {
        success: true,
        upload_state: result
      }, status: :ok
    else
      render json: {
        success: false,
        message: 'Failed to resume upload'
      }, status: :unprocessable_entity
    end
  end

  # DELETE /study_sets/:study_set_id/uploads/:id/cancel
  # Cancel upload
  def cancel_upload
    service = ChunkedUploadService.new(@study_material)

    if service.cancel_upload
      render json: {
        success: true,
        message: 'Upload cancelled'
      }, status: :ok
    else
      render json: {
        success: false,
        message: 'Failed to cancel upload'
      }, status: :unprocessable_entity
    end
  end

  # POST /study_sets/:study_set_id/uploads/validate
  # Validate file before upload
  def validate_file
    FileValidationService.validate_upload_params!(upload_params)

    # Check for duplicates
    if upload_params[:checksum].present?
      duplicate_exists = StudyMaterial
                         .where(study_set_id: @study_set.id, file_checksum: upload_params[:checksum])
                         .where.not(upload_status: ['failed', 'cancelled'])
                         .exists?

      if duplicate_exists
        return render json: {
          success: false,
          errors: ['Duplicate file detected'],
          is_duplicate: true
        }, status: :unprocessable_entity
      end
    end

    render json: {
      success: true,
      message: 'File validation passed'
    }, status: :ok
  rescue FileValidationService::ValidationError => e
    render json: {
      success: false,
      errors: [e.message]
    }, status: :unprocessable_entity
  end

  # GET /uploads/storage_stats
  # Get storage statistics (admin)
  def storage_stats
    unless current_user.admin?
      return render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    stats = StorageCleanupService.storage_stats

    render json: {
      success: true,
      stats: stats
    }, status: :ok
  end

  # POST /uploads/cleanup
  # Trigger storage cleanup (admin)
  def cleanup_storage
    unless current_user.admin?
      return render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    CleanupStorageJob.perform_later

    render json: {
      success: true,
      message: 'Storage cleanup job scheduled'
    }, status: :ok
  end

  private

  def set_study_set
    @study_set = current_user.study_sets.find(params[:study_set_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  end

  def set_study_material
    @study_material = @study_set.study_materials.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Upload not found' }, status: :not_found
  end

  def upload_params
    params.require(:file).permit(:filename, :byte_size, :content_type, :checksum)
  end

  def study_material_json(material)
    {
      id: material.id,
      name: material.name,
      status: material.status,
      upload_status: material.upload_status,
      upload_progress: material.upload_progress,
      file_size: material.file_size,
      mime_type: material.mime_type,
      created_at: material.created_at,
      updated_at: material.updated_at
    }
  end
end
