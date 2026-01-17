class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_material, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.integer :helpful_count, default: 0
      t.integer :not_helpful_count, default: 0
      t.boolean :verified_purchase, default: false
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :reviews, [:user_id, :study_material_id], unique: true
    add_index :reviews, :rating
    add_index :reviews, :verified_purchase
    add_index :reviews, :helpful_count
    add_index :reviews, :created_at
  end
end
