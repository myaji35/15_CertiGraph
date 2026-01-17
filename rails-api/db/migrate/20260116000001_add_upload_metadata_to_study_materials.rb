class AddUploadMetadataToStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    add_column :study_materials, :file_size, :bigint
    add_column :study_materials, :file_checksum, :string
    add_column :study_materials, :mime_type, :string
    add_column :study_materials, :upload_status, :string, default: 'pending'
    add_column :study_materials, :upload_progress, :integer, default: 0
    add_column :study_materials, :upload_started_at, :datetime
    add_column :study_materials, :upload_completed_at, :datetime
    add_column :study_materials, :upload_error, :text
    add_column :study_materials, :chunk_count, :integer
    add_column :study_materials, :chunks_uploaded, :integer, default: 0
    add_column :study_materials, :multipart_upload_id, :string
    add_column :study_materials, :retry_count, :integer, default: 0
    add_column :study_materials, :last_accessed_at, :datetime
    add_column :study_materials, :storage_usage_bytes, :bigint, default: 0
    add_column :study_materials, :is_backed_up, :boolean, default: false
    add_column :study_materials, :backup_completed_at, :datetime

    add_index :study_materials, :file_checksum
    add_index :study_materials, :upload_status
    add_index :study_materials, :last_accessed_at
  end
end
