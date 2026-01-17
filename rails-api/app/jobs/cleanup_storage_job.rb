# Background job for automated storage cleanup
class CleanupStorageJob < ApplicationJob
  queue_as :maintenance

  def perform
    Rails.logger.info("Starting scheduled storage cleanup...")

    service = StorageCleanupService.new
    results = service.cleanup_all!

    Rails.logger.info("Storage cleanup completed: #{results.inspect}")

    # Send notification to admins if configured
    notify_admins(results) if results[:space_freed_bytes] > 100.megabytes

    results
  rescue StandardError => e
    Rails.logger.error("Storage cleanup job failed: #{e.message}\n#{e.backtrace.join("\n")}")
    raise
  end

  private

  def notify_admins(results)
    # Implement admin notification (email, Slack, etc.)
    # AdminMailer.storage_cleanup_report(results).deliver_later
  end
end
