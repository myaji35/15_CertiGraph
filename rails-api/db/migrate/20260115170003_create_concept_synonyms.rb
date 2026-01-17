class CreateConceptSynonyms < ActiveRecord::Migration[7.2]
  def change
    create_table :concept_synonyms do |t|
      t.references :knowledge_node, null: false, foreign_key: true, index: true
      t.string :synonym_name, null: false
      t.string :synonym_type, default: 'synonym', null: false # synonym, abbreviation, alias, related_term
      t.float :similarity_score, default: 1.0
      t.string :source, default: 'manual' # manual, ai_extracted, user_defined
      t.json :metadata, default: {}
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :concept_synonyms, [:synonym_name, :knowledge_node_id], unique: true
    add_index :concept_synonyms, :synonym_name
    add_index :concept_synonyms, :synonym_type
    add_index :concept_synonyms, :active
  end
end
