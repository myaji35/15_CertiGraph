class AddMetadataToExamSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :exam_sessions, :metadata, :text
  end
end
