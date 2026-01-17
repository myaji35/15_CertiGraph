class AddCounterCachesToUsers < ActiveRecord::Migration[7.2]
  def change
    # rails-best-practices: db-counter-cache
    add_column :users, :study_sets_count, :integer, default: 0, null: false
    add_column :users, :exam_sessions_count, :integer, default: 0, null: false
    add_column :users, :test_sessions_count, :integer, default: 0, null: false

    # Reset existing counters
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          User.reset_counters(user.id, :study_sets)
          User.reset_counters(user.id, :exam_sessions)
          User.reset_counters(user.id, :test_sessions)
        end
      end
    end
  end
end
