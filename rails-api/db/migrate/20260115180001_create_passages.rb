class CreatePassages < ActiveRecord::Migration[7.2]
  def change
    create_table :passages do |t|
      t.references :study_material, null: false, foreign_key: true
      t.text :content, null: false
      t.string :passage_type, default: 'text'
      t.integer :position
      t.json :metadata, default: {}
      t.boolean :has_image, default: false
      t.boolean :has_table, default: false
      t.integer :character_count, default: 0
      t.text :summary

      t.timestamps
    end

    add_index :passages, [:study_material_id, :position]
    add_index :passages, :passage_type
  end
end
