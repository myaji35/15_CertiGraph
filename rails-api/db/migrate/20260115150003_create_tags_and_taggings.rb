class CreateTagsAndTaggings < ActiveRecord::Migration[7.2]
  def change
    # Tags table
    create_table :tags do |t|
      t.string :name, null: false
      t.string :category
      t.integer :usage_count, default: 0
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :tags, :name, unique: true
    add_index :tags, :category
    add_index :tags, :usage_count

    # Taggings join table (polymorphic for future extensibility)
    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false
      t.string :context # For different tag types: 'topic', 'difficulty', 'year', etc.
      t.integer :relevance_score, default: 100

      t.timestamps
    end

    add_index :taggings, [:taggable_type, :taggable_id, :tag_id], unique: true, name: 'idx_taggings_unique'
    add_index :taggings, :context
  end
end
