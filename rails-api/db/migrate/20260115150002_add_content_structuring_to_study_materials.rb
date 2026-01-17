class AddContentStructuringToStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    add_column :study_materials, :category, :string
    add_column :study_materials, :difficulty, :integer, default: 3
    add_column :study_materials, :content_metadata, :json, default: {}

    add_index :study_materials, :category
    add_index :study_materials, :difficulty
  end
end
