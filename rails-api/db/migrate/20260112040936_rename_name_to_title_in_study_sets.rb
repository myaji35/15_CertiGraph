class RenameNameToTitleInStudySets < ActiveRecord::Migration[7.2]
  def change
    rename_column :study_sets, :name, :title
    rename_column :study_sets, :certification_id, :certification
    change_column :study_sets, :certification, :string
  end
end