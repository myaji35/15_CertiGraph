class AddStudyMaterialsCountToStudySets < ActiveRecord::Migration[7.2]
  def change
    # rails-best-practices: db-counter-cache
    add_column :study_sets, :study_materials_count, :integer, default: 0, null: false

    # Reset existing counters
    reversible do |dir|
      dir.up do
        StudySet.find_each do |study_set|
          StudySet.reset_counters(study_set.id, :study_materials)
        end
      end
    end
  end
end
