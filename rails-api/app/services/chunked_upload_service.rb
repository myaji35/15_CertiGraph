# Service for handling chunked file uploads with progress tracking
# Supports pause/resume and automatic retry
class ChunkedUploadService
  attr_reader :study_material, :errors

  CHUNK_SIZE = 5.megabytes
  MAX_RETRIES = 3
  RETRY_DELAY = 2.seconds

  def initialize(study_material)
    @study_material = study_material
    @errors = []
  end

  # Process uploaded chunk
  def process_chunk(chunk_number, chunk_data, total_chunks)
    validate_chunk!(chunk_number, total_chunks)

    begin
      # Store chunk temporarily
      temp_file_path = save_temp_chunk(chunk_number, chunk_data)

      # Update progress
      study_material.increment!(:chunks_uploaded)

      progress = ((study_material.chunks_uploaded.to_f / total_chunks) * 100).round
      study_material.update!(upload_progress: progress)

      # Check if all chunks are uploaded
      if study_material.chunks_uploaded >= total_chunks
        assemble_chunks(total_chunks)
      end

      {
        success: true,
        chunk_number: chunk_number,
        chunks_uploaded: study_material.chunks_uploaded,
        total_chunks: total_chunks,
        progress: progress
      }
    rescue StandardError => e
      @errors << "Chunk #{chunk_number} failed: #{e.message}"
      handle_chunk_error(chunk_number, e)

      {
        success: false,
        chunk_number: chunk_number,
        error: e.message,
        retry_count: study_material.retry_count
      }
    end
  end

  # Resume interrupted upload
  def resume_upload
    return false unless study_material.upload_status == 'paused'

    study_material.update!(
      upload_status: 'in_progress',
      upload_error: nil
    )

    {
      chunks_uploaded: study_material.chunks_uploaded,
      chunk_count: study_material.chunk_count,
      progress: study_material.upload_progress
    }
  end

  # Pause upload
  def pause_upload
    return false unless study_material.upload_status == 'in_progress'

    study_material.update!(upload_status: 'paused')

    {
      chunks_uploaded: study_material.chunks_uploaded,
      chunk_count: study_material.chunk_count
    }
  end

  # Cancel upload and cleanup
  def cancel_upload
    cleanup_temp_chunks

    study_material.update!(
      upload_status: 'cancelled',
      chunks_uploaded: 0,
      upload_progress: 0,
      upload_error: 'Upload cancelled by user'
    )

    true
  end

  # Get upload status
  def upload_status
    {
      status: study_material.upload_status,
      progress: study_material.upload_progress,
      chunks_uploaded: study_material.chunks_uploaded,
      chunk_count: study_material.chunk_count,
      file_size: study_material.file_size,
      started_at: study_material.upload_started_at,
      error: study_material.upload_error
    }
  end

  private

  def validate_chunk!(chunk_number, total_chunks)
    if chunk_number < 1 || chunk_number > total_chunks
      raise ArgumentError, "Invalid chunk number: #{chunk_number}"
    end

    unless study_material.upload_status.in?(['in_progress', 'pending'])
      raise StandardError, "Upload not in progress"
    end
  end

  def save_temp_chunk(chunk_number, chunk_data)
    temp_dir = temp_chunks_directory
    FileUtils.mkdir_p(temp_dir)

    temp_file_path = File.join(temp_dir, "chunk_#{chunk_number.to_s.rjust(5, '0')}")

    File.open(temp_file_path, 'wb') do |file|
      file.write(chunk_data)
    end

    temp_file_path
  end

  def assemble_chunks(total_chunks)
    temp_dir = temp_chunks_directory
    final_file_path = File.join(Rails.root, 'tmp', 'uploads', "final_#{study_material.id}.pdf")

    FileUtils.mkdir_p(File.dirname(final_file_path))

    # Combine all chunks
    File.open(final_file_path, 'wb') do |output|
      (1..total_chunks).each do |chunk_number|
        chunk_file = File.join(temp_dir, "chunk_#{chunk_number.to_s.rjust(5, '0')}")

        if File.exist?(chunk_file)
          output.write(File.binread(chunk_file))
        else
          raise StandardError, "Missing chunk #{chunk_number}"
        end
      end
    end

    # Validate assembled file
    validate_assembled_file!(final_file_path)

    # Attach to Active Storage
    attach_final_file(final_file_path)

    # Cleanup
    cleanup_temp_chunks
    File.delete(final_file_path) if File.exist?(final_file_path)

    study_material.update!(
      upload_status: 'completed',
      upload_completed_at: Time.current,
      upload_progress: 100
    )

    # Trigger processing
    ProcessPdfJob.perform_later(study_material.id)
  end

  def validate_assembled_file!(file_path)
    # Check file size
    actual_size = File.size(file_path)
    expected_size = study_material.file_size

    if expected_size && (actual_size != expected_size)
      raise StandardError, "File size mismatch: expected #{expected_size}, got #{actual_size}"
    end

    # Validate checksum if provided
    if study_material.file_checksum.present?
      actual_checksum = Digest::MD5.file(file_path).hexdigest
      if actual_checksum != study_material.file_checksum
        raise StandardError, "Checksum mismatch"
      end
    end

    # Validate PDF structure
    FileValidationService.new(file_path).validate_pdf_integrity!
  end

  def attach_final_file(file_path)
    study_material.pdf_file.attach(
      io: File.open(file_path),
      filename: File.basename(study_material.name || 'uploaded.pdf'),
      content_type: 'application/pdf'
    )

    # Update metadata
    if study_material.pdf_file.attached?
      blob = study_material.pdf_file.blob

      study_material.update!(
        file_size: blob.byte_size,
        file_checksum: blob.checksum,
        mime_type: blob.content_type,
        storage_usage_bytes: blob.byte_size,
        last_accessed_at: Time.current
      )
    end
  end

  def handle_chunk_error(chunk_number, error)
    study_material.increment!(:retry_count)

    if study_material.retry_count >= MAX_RETRIES
      study_material.update!(
        upload_status: 'failed',
        upload_error: "Max retries exceeded for chunk #{chunk_number}: #{error.message}"
      )

      cleanup_temp_chunks
    else
      study_material.update!(
        upload_error: "Chunk #{chunk_number} failed (retry #{study_material.retry_count}/#{MAX_RETRIES}): #{error.message}"
      )
    end

    Rails.logger.error("Chunk upload error: #{error.message}\n#{error.backtrace.join("\n")}")
  end

  def temp_chunks_directory
    File.join(Rails.root, 'tmp', 'chunks', study_material.id.to_s)
  end

  def cleanup_temp_chunks
    temp_dir = temp_chunks_directory

    if Dir.exist?(temp_dir)
      FileUtils.rm_rf(temp_dir)
    end
  end
end
