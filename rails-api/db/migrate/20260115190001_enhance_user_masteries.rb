class EnhanceUserMasteries < ActiveRecord::Migration[7.2]
  def change
    add_column :user_masteries, :consecutive_correct, :integer, default: 0
    add_column :user_masteries, :consecutive_incorrect, :integer, default: 0
    add_column :user_masteries, :fastest_solve_seconds, :integer
    add_column :user_masteries, :avg_solve_seconds, :integer
    add_column :user_masteries, :study_streak_days, :integer, default: 0
    add_column :user_masteries, :last_review_date, :date
    add_column :user_masteries, :next_review_date, :date
    add_column :user_masteries, :retention_score, :float, default: 0.0
    add_column :user_masteries, :difficulty_rating, :integer, default: 3
    add_column :user_masteries, :time_of_day_best_performance, :string # morning, afternoon, evening, night

    add_index :user_masteries, :consecutive_correct
    add_index :user_masteries, :retention_score
    add_index :user_masteries, :next_review_date
  end
end
