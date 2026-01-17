# Job to generate daily performance snapshots for users
class GeneratePerformanceSnapshotJob < ApplicationJob
  queue_as :default

  # Generate snapshot for a specific user
  def perform(user_id, study_set_id: nil, date: Date.today, period_type: 'daily')
    user = User.find(user_id)
    study_set = study_set_id ? StudySet.find(study_set_id) : nil

    service = GeneratePerformanceSnapshotService.new(user, study_set: study_set)
    service.generate(date: date, period_type: period_type)

    Rails.logger.info "Generated #{period_type} performance snapshot for User #{user_id}"
  rescue StandardError => e
    Rails.logger.error "Failed to generate snapshot for User #{user_id}: #{e.message}"
    raise e
  end

  # Generate snapshots for all active users
  def self.generate_for_all_users(date: Date.today, period_type: 'daily')
    User.find_each do |user|
      GeneratePerformanceSnapshotJob.perform_later(user.id, date: date, period_type: period_type)

      # Also generate for each study set
      user.study_sets.each do |study_set|
        GeneratePerformanceSnapshotJob.perform_later(
          user.id,
          study_set_id: study_set.id,
          date: date,
          period_type: period_type
        )
      end
    end
  end
end
