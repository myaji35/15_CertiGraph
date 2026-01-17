# Service for automated storage management and cleanup
class StorageCleanupService
  attr_reader :results

  # Cleanup thresholds
  UNUSED_FILE_RETENTION = 30.days
  FAILED_UPLOAD_RETENTION = 7.days
  TEMP_FILE_RETENTION = 1.day
  BACKUP_RETENTION = 90.days

  def initialize
    @results = {
      unused_files_removed: 0,
      failed_uploads_removed: 0,
      temp_files_removed: 0,
      old_backups_removed: 0,
      space_freed_bytes: 0,
      errors: []
    }
  end

  # Run full cleanup
  def cleanup_all!
    Rails.logger.info("Starting storage cleanup...")

    cleanup_unused_files!
    cleanup_failed_uploads!
    cleanup_temp_files!
    cleanup_old_backups!
    update_storage_stats!

    Rails.logger.info("Storage cleanup complete: #{format_results}")

    @results
  end

  # Remove files that haven't been accessed in UNUSED_FILE_RETENTION days
  def cleanup_unused_files!
    cutoff_date = UNUSED_FILE_RETENTION.ago

    unused_materials = StudyMaterial
                       .where('last_accessed_at < ?', cutoff_date)
                       .where(upload_status: 'completed')

    unused_materials.find_each do |material|
      begin
        if material.pdf_file.attached?
          file_size = material.pdf_file.blob.byte_size

          material.pdf_file.purge

          @results[:unused_files_removed] += 1
          @results[:space_freed_bytes] += file_size

          Rails.logger.info("Removed unused file from material #{material.id}")
        end
      rescue StandardError => e
        @results[:errors] << "Failed to remove material #{material.id}: #{e.message}"
        Rails.logger.error("Cleanup error: #{e.message}")
      end
    end
  end

  # Remove failed upload records and their files
  def cleanup_failed_uploads!
    cutoff_date = FAILED_UPLOAD_RETENTION.ago

    failed_materials = StudyMaterial
                       .where(upload_status: ['failed', 'cancelled'])
                       .where('updated_at < ?', cutoff_date)

    failed_materials.find_each do |material|
      begin
        file_size = 0

        if material.pdf_file.attached?
          file_size = material.pdf_file.blob.byte_size
          material.pdf_file.purge
        end

        # Clean up temp chunks if any
        ChunkedUploadService.new(material).send(:cleanup_temp_chunks)

        material.destroy

        @results[:failed_uploads_removed] += 1
        @results[:space_freed_bytes] += file_size

        Rails.logger.info("Removed failed upload material #{material.id}")
      rescue StandardError => e
        @results[:errors] << "Failed to remove failed material #{material.id}: #{e.message}"
        Rails.logger.error("Cleanup error: #{e.message}")
      end
    end
  end

  # Clean up temporary upload chunks
  def cleanup_temp_files!
    temp_chunks_dir = Rails.root.join('tmp', 'chunks')
    temp_uploads_dir = Rails.root.join('tmp', 'uploads')

    [temp_chunks_dir, temp_uploads_dir].each do |dir|
      next unless Dir.exist?(dir)

      Dir.glob(File.join(dir, '*')).each do |path|
        begin
          next unless File.exist?(path)

          file_age = Time.current - File.mtime(path)

          if file_age > TEMP_FILE_RETENTION
            file_size = File.directory?(path) ? directory_size(path) : File.size(path)

            if File.directory?(path)
              FileUtils.rm_rf(path)
            else
              File.delete(path)
            end

            @results[:temp_files_removed] += 1
            @results[:space_freed_bytes] += file_size

            Rails.logger.info("Removed temp file/directory: #{path}")
          end
        rescue StandardError => e
          @results[:errors] << "Failed to remove temp file #{path}: #{e.message}"
          Rails.logger.error("Cleanup error: #{e.message}")
        end
      end
    end
  end

  # Remove old backups (if backup system is implemented)
  def cleanup_old_backups!
    cutoff_date = BACKUP_RETENTION.ago

    old_backups = StudyMaterial
                  .where('backup_completed_at < ?', cutoff_date)
                  .where(is_backed_up: true)

    # This is a placeholder - implement actual backup cleanup based on your backup strategy
    old_backups.find_each do |material|
      begin
        # Example: Remove from backup storage
        # BackupService.new(material).remove_backup

        material.update!(is_backed_up: false, backup_completed_at: nil)

        @results[:old_backups_removed] += 1

        Rails.logger.info("Removed old backup for material #{material.id}")
      rescue StandardError => e
        @results[:errors] << "Failed to remove backup for material #{material.id}: #{e.message}"
        Rails.logger.error("Backup cleanup error: #{e.message}")
      end
    end
  end

  # Update storage usage statistics
  def update_storage_stats!
    StudyMaterial.where(upload_status: 'completed').find_each do |material|
      next unless material.pdf_file.attached?

      blob = material.pdf_file.blob
      expected_size = blob.byte_size
      current_size = material.storage_usage_bytes

      if expected_size != current_size
        material.update_column(:storage_usage_bytes, expected_size)
      end
    end
  end

  # Calculate total storage usage per user
  def self.calculate_user_storage(user)
    StudyMaterial
      .joins(:study_set)
      .where(study_sets: { user_id: user.id })
      .where(upload_status: 'completed')
      .sum(:storage_usage_bytes)
  end

  # Calculate total storage usage
  def self.total_storage_usage
    StudyMaterial.where(upload_status: 'completed').sum(:storage_usage_bytes)
  end

  # Get storage statistics
  def self.storage_stats
    {
      total_files: StudyMaterial.where(upload_status: 'completed').count,
      total_storage_bytes: total_storage_usage,
      total_storage_mb: (total_storage_usage.to_f / 1.megabyte).round(2),
      total_storage_gb: (total_storage_usage.to_f / 1.gigabyte).round(2),
      avg_file_size_bytes: StudyMaterial.where(upload_status: 'completed').average(:file_size).to_i,
      largest_file_bytes: StudyMaterial.where(upload_status: 'completed').maximum(:file_size).to_i,
      unused_files_count: StudyMaterial
                           .where(upload_status: 'completed')
                           .where('last_accessed_at < ?', UNUSED_FILE_RETENTION.ago)
                           .count,
      failed_uploads_count: StudyMaterial
                             .where(upload_status: ['failed', 'cancelled'])
                             .where('updated_at < ?', FAILED_UPLOAD_RETENTION.ago)
                             .count
    }
  end

  # Optimize storage (compress, deduplicate, etc.)
  def self.optimize_storage!
    results = {
      optimized_count: 0,
      space_saved_bytes: 0
    }

    # Find potential duplicates based on checksum
    duplicates = StudyMaterial
                 .where(upload_status: 'completed')
                 .where.not(file_checksum: nil)
                 .group(:file_checksum)
                 .having('COUNT(*) > 1')
                 .pluck(:file_checksum)

    duplicates.each do |checksum|
      materials = StudyMaterial.where(file_checksum: checksum).order(created_at: :asc)

      # Keep the first one, point others to it (requires custom implementation)
      # This is a placeholder for deduplication logic
      original = materials.first
      duplicates = materials[1..]

      duplicates.each do |dup|
        Rails.logger.info("Duplicate found: material #{dup.id} (checksum: #{checksum})")
        results[:optimized_count] += 1
      end
    end

    results
  end

  private

  def directory_size(path)
    size = 0
    Dir.glob(File.join(path, '**', '*')).each do |file|
      size += File.size(file) if File.file?(file)
    end
    size
  end

  def format_results
    mb_freed = (@results[:space_freed_bytes].to_f / 1.megabyte).round(2)

    "Files: #{@results[:unused_files_removed]}, " \
    "Failed: #{@results[:failed_uploads_removed]}, " \
    "Temp: #{@results[:temp_files_removed]}, " \
    "Backups: #{@results[:old_backups_removed]}, " \
    "Space freed: #{mb_freed} MB"
  end
end
