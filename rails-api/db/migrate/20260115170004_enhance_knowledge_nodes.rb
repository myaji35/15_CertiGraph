class EnhanceKnowledgeNodes < ActiveRecord::Migration[7.2]
  def change
    # Add concept extraction and analysis fields
    add_column :knowledge_nodes, :definition, :text
    add_column :knowledge_nodes, :examples, :json, default: []
    add_column :knowledge_nodes, :frequency, :integer, default: 0
    add_column :knowledge_nodes, :mastery_threshold, :float, default: 0.8
    add_column :knowledge_nodes, :estimated_learning_minutes, :integer, default: 30
    add_column :knowledge_nodes, :tags, :json, default: []
    add_column :knowledge_nodes, :concept_category, :string # fundamental, advanced, specialized
    add_column :knowledge_nodes, :extraction_confidence, :float, default: 0.0
    add_column :knowledge_nodes, :normalized_name, :string
    add_column :knowledge_nodes, :is_primary, :boolean, default: true

    # Add indexes for better query performance
    add_index :knowledge_nodes, :normalized_name
    add_index :knowledge_nodes, :concept_category
    add_index :knowledge_nodes, :frequency
    add_index :knowledge_nodes, :is_primary
    add_index :knowledge_nodes, [:study_material_id, :normalized_name]
  end
end
