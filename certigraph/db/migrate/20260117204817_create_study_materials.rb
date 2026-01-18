class CreateStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    create_table :study_materials do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_set, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :file_type

      t.timestamps
    end
  end
end
