class AddMarketplaceFieldsToStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    add_column :study_materials, :is_public, :boolean, default: false, null: false
    add_column :study_materials, :price, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :study_materials, :sales_count, :integer, default: 0
    add_column :study_materials, :avg_rating, :decimal, precision: 3, scale: 2, default: 0.0
    add_column :study_materials, :total_reviews, :integer, default: 0
    # Skip adding category - it already exists
    add_column :study_materials, :difficulty_level, :string
    add_column :study_materials, :tags, :json, default: []
    add_column :study_materials, :published_at, :datetime

    add_index :study_materials, :is_public
    add_index :study_materials, :price
    add_index :study_materials, :avg_rating
    # Skip category index - already exists
    add_index :study_materials, :difficulty_level
    add_index :study_materials, :published_at
  end
end
