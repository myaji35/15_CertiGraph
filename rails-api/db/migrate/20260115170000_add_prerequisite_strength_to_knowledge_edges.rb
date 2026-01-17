class AddPrerequisiteStrengthToKnowledgeEdges < ActiveRecord::Migration[7.2]
  def change
    add_column :knowledge_edges, :strength, :string, default: 'medium'
    add_column :knowledge_edges, :depth, :integer, default: 1
    add_column :knowledge_edges, :confidence_score, :float, default: 0.0
    add_column :knowledge_edges, :auto_generated, :boolean, default: false
    add_column :knowledge_edges, :verified_by_user, :boolean, default: false
    add_column :knowledge_edges, :llm_reasoning, :text

    add_index :knowledge_edges, :strength
    add_index :knowledge_edges, :depth
    add_index :knowledge_edges, :confidence_score
    add_index :knowledge_edges, :auto_generated
  end
end
