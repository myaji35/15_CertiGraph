# app/jobs/update_recommendations_job.rb
class UpdateRecommendationsJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(user_id = nil, study_set_id = nil)
    if user_id
      # Update recommendations for specific user
      update_for_user(user_id, study_set_id)
    else
      # Update recommendations for all active users
      update_for_all_users
    end
  end

  private

  def update_for_user(user_id, study_set_id = nil)
    user = User.find(user_id)
    study_sets = study_set_id ? [StudySet.find(study_set_id)] : user.study_sets.active

    study_sets.each do |study_set|
      begin
        Rails.logger.info "Generating recommendations for User #{user.id}, StudySet #{study_set.id}"

        engine = RecommendationEngine.new(user, study_set)
        recommendations = engine.generate_recommendations(force: true)

        Rails.logger.info "Generated #{recommendations.count} recommendations for User #{user.id}, StudySet #{study_set.id}"

        # Clean up old dismissed recommendations
        cleanup_old_recommendations(user, study_set)

      rescue StandardError => e
        Rails.logger.error "Failed to generate recommendations for User #{user.id}, StudySet #{study_set.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end

  def update_for_all_users
    # Find users who have been active in the last 30 days
    active_users = User.joins(:test_sessions)
                      .where('test_sessions.created_at >= ?', 30.days.ago)
                      .distinct
                      .limit(1000) # Process in batches

    Rails.logger.info "Updating recommendations for #{active_users.count} active users"

    active_users.find_each(batch_size: 50) do |user|
      begin
        UpdateRecommendationsJob.perform_later(user.id)
      rescue StandardError => e
        Rails.logger.error "Failed to queue recommendations job for User #{user.id}: #{e.message}"
      end
    end

    Rails.logger.info "Queued recommendation updates for all active users"
  end

  def cleanup_old_recommendations(user, study_set)
    # Remove dismissed recommendations older than 30 days
    user.learning_recommendations
        .where(study_set: study_set, status: 'dismissed')
        .where('created_at < ?', 30.days.ago)
        .delete_all

    # Remove completed recommendations older than 90 days
    user.learning_recommendations
        .where(study_set: study_set, status: 'completed')
        .where('completed_at < ?', 90.days.ago)
        .delete_all

    Rails.logger.info "Cleaned up old recommendations for User #{user.id}, StudySet #{study_set.id}"
  end
end
