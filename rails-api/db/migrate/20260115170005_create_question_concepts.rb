class CreateQuestionConcepts < ActiveRecord::Migration[7.2]
  def change
    create_table :question_concepts do |t|
      t.references :question, null: false, foreign_key: true, index: true
      t.references :knowledge_node, null: false, foreign_key: true, index: true
      t.integer :importance_level, default: 5, null: false # 1-10 scale
      t.float :relevance_score, default: 0.5 # 0.0-1.0
      t.boolean :is_primary_concept, default: false
      t.string :extraction_method, default: 'ai' # ai, manual, rule_based
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :question_concepts, [:question_id, :knowledge_node_id], unique: true, name: 'idx_question_concepts_unique'
    add_index :question_concepts, :importance_level
    add_index :question_concepts, :relevance_score
    add_index :question_concepts, :is_primary_concept
  end
end
