class AddGraphFieldsToStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    add_column :study_materials, :graph_built, :boolean, default: false
    add_column :study_materials, :graph_built_at, :datetime
    add_column :study_materials, :graph_metadata, :json
    add_column :study_materials, :graph_error, :text
  end
end
