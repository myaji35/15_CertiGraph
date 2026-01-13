class AddExtractedDataToStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    add_column :study_materials, :extracted_data, :text
    add_column :study_materials, :error_message, :text
  end
end
