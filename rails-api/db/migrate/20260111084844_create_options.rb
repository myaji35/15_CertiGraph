class CreateOptions < ActiveRecord::Migration[7.2]
  def change
    create_table :options do |t|
      t.references :question, null: false, foreign_key: true
      t.text :content
      t.boolean :is_correct

      t.timestamps
    end
  end
end
