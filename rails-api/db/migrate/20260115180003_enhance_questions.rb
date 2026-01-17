class EnhanceQuestions < ActiveRecord::Migration[7.2]
  def change
    add_column :questions, :question_number, :integer unless column_exists?(:questions, :question_number)
    add_column :questions, :question_type, :string, default: 'multiple_choice' unless column_exists?(:questions, :question_type)
    add_column :questions, :correct_answer_index, :integer unless column_exists?(:questions, :correct_answer_index)
    add_column :questions, :has_image, :boolean, default: false unless column_exists?(:questions, :has_image)
    add_column :questions, :has_table, :boolean, default: false unless column_exists?(:questions, :has_table)
    add_column :questions, :validation_status, :string, default: 'pending' unless column_exists?(:questions, :validation_status)
    add_column :questions, :validation_errors, :json, default: {} unless column_exists?(:questions, :validation_errors)
    add_column :questions, :extraction_metadata, :json, default: {} unless column_exists?(:questions, :extraction_metadata)
    add_column :questions, :ai_confidence_score, :float, default: 0.0 unless column_exists?(:questions, :ai_confidence_score)

    add_index :questions, :question_number unless index_exists?(:questions, :question_number)
    add_index :questions, :question_type unless index_exists?(:questions, :question_type)
    add_index :questions, :validation_status unless index_exists?(:questions, :validation_status)
    add_index :questions, [:study_material_id, :question_number], unique: true unless index_exists?(:questions, [:study_material_id, :question_number])
  end
end
