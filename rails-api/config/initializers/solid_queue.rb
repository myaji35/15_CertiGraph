# Solid Queue 초기화 설정

# 환경별 로깅 설정
Rails.application.config.after_initialize do
  if Rails.env.development?
    # 개발 환경에서는 상세 로깅
    Rails.logger.info("Solid Queue initialized in development mode")
    Rails.logger.info("Queue config: #{Rails.root.join('config/solid_queue.yml')}")
  elsif Rails.env.production?
    # 프로덕션 환경에서는 기본 정보만 로깅
    Rails.logger.info("Solid Queue initialized in production mode")
  end

  # 큐 어댑터 확인
  begin
    queue_adapter = Rails.application.config.active_job.queue_adapter
    Rails.logger.info("ActiveJob queue adapter: #{queue_adapter.inspect}")
  rescue => e
    Rails.logger.warn("Failed to check queue adapter: #{e.message}")
  end
end
