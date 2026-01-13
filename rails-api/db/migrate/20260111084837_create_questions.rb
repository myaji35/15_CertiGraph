class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.references :study_material, null: false, foreign_key: true
      t.text :content
      t.text :passage
      t.text :explanation
      t.integer :difficulty
      t.text :embedding_json

      t.timestamps
    end
  end
end
