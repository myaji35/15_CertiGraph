class CreateStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    create_table :study_materials do |t|
      t.references :study_set, null: false, foreign_key: true
      t.string :name
      t.string :status
      t.integer :parsing_progress

      t.timestamps
    end
  end
end
