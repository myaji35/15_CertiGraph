class AddRandomizationToExamSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :exam_sessions, :randomization_seed, :string
    add_column :exam_sessions, :randomization_strategy, :string, default: 'full_random'
    add_column :exam_sessions, :randomization_enabled, :boolean, default: true

    add_index :exam_sessions, :randomization_seed
    add_index :exam_sessions, :randomization_strategy
  end
end
