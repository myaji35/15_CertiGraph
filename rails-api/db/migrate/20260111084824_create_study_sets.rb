class CreateStudySets < ActiveRecord::Migration[7.2]
  def change
    create_table :study_sets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.date :exam_date
      t.integer :certification_id

      t.timestamps
    end
  end
end
