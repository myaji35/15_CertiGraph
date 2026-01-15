# Solid Queue 백그라운드 Job 시스템 설정 가이드

## 개요

Rails 7.2.2 프로젝트에서 내장 Solid Queue를 사용하여 비동기 백그라운드 작업 처리 시스템을 구현했습니다.

## 구현된 컴포넌트

### 1. 설정 파일

#### `config/solid_queue.yml`
- Solid Queue 데이터베이스 및 큐 설정
- 환경별 큐 스레드 수 및 처리 정책 정의
- 6개 큐 지원:
  - `default`: 기본 작업 (5 threads)
  - `high_priority`: 높은 우선순위 (10 threads)
  - `low_priority`: 낮은 우선순위 (3 threads)
  - `pdf_processing`: PDF 처리 (2 threads)
  - `embedding_generation`: 임베딩 생성 (4 threads)
  - `graph_update`: 그래프 업데이트 (3 threads)

#### `config/environments/development.rb`
```ruby
config.active_job.queue_adapter = :solid_queue
```

#### `config/environments/production.rb`
```ruby
config.active_job.queue_adapter = :solid_queue
config.active_job.queue_name_prefix = "certigraph_api_production"
```

### 2. Job 클래스

#### `ProcessPdfJob`
**목적**: PDF 파일 처리 및 문제 추출
- 큐: `pdf_processing`
- 재시도: Timeout 3회, 지수 백오프 5회
- 플로우:
  1. PDF 파일 다운로드
  2. 문제 추출 및 처리
  3. 각 문제마다 `GenerateEmbeddingJob` 큐에 추가

**사용 예시**:
```ruby
ProcessPdfJob.perform_later(study_material_id)
```

#### `GenerateEmbeddingJob`
**목적**: 각 문제의 임베딩 벡터 생성
- 큐: `embedding_generation`
- 재시도: Timeout 3회, 지수 백오프 5회
- 플로우:
  1. 문제 텍스트 및 선택지 준비
  2. OpenAI 임베딩 API 호출
  3. 임베딩 저장
  4. `UpdateKnowledgeGraphJob` 큐에 추가

**사용 예시**:
```ruby
GenerateEmbeddingJob.perform_later(question_id)
```

#### `UpdateKnowledgeGraphJob`
**목적**: Neo4j 지식 그래프 업데이트
- 큐: `graph_update`
- 재시도: Timeout 4회, 지수 백오프 5회
- 플로우:
  1. 문제에서 개념 추출 (LLM)
  2. 개념 노드 생성
  3. 문제-개념 관계 생성
  4. 전제 조건 관계 생성
  5. 사용자 성과 데이터 업데이트 (선택)

**사용 예시**:
```ruby
UpdateKnowledgeGraphJob.perform_later(question_id)
UpdateKnowledgeGraphJob.perform_later(question_id, user_id)
```

### 3. ApplicationJob 설정

**기본 재시도 정책**:
- 데이터베이스 데드락: 5초 대기, 3회 재시도
- 일반 에러: 지수 백오프 대기, 5회 재시도
- 직렬화 에러: 폐기

**로깅**:
- 작업 큐 추가, 시작, 완료, 실패 시 로깅

## 마이그레이션

### Solid Queue 테이블
```bash
rails db:migrate
```

다음 테이블이 생성됩니다:
- `solid_queue_jobs`: 작업 정보
- `solid_queue_processes`: 워커 프로세스
- `solid_queue_ready_executions`: 실행 대기 중인 작업
- `solid_queue_claimed_executions`: 실행 중인 작업
- `solid_queue_scheduled_executions`: 예약된 작업
- `solid_queue_paused_jobs`: 일시 중지된 작업
- `solid_queue_failed_executions`: 실패한 작업
- `solid_queue_batches`: 배치 작업
- `solid_queue_batch_jobs`: 배치 내 작업

### 문제 테이블 확장
```bash
rails db:migrate
```

Question 테이블에 추가된 컬럼:
- `embedding`: vector(1536) - OpenAI 임베딩
- `embedding_generated_at`: datetime - 임베딩 생성 시간

## 사용 방법

### 1. PDF 처리 시작
```ruby
study_material = StudyMaterial.find(id)
ProcessPdfJob.perform_later(study_material.id)
```

### 2. 즉시 처리 (동기)
```ruby
ProcessPdfJob.perform_now(study_material.id)
```

### 3. 예약된 처리
```ruby
ProcessPdfJob.set(wait: 1.hour).perform_later(study_material.id)
ProcessPdfJob.set(wait_until: Date.tomorrow.noon).perform_later(study_material.id)
```

### 4. 재시도 없이 처리
```ruby
class CustomJob < ApplicationJob
  retry_on StandardError, attempts: 0  # 재시도 비활성화
end
```

## Solid Queue 실행

### Development 환경
```bash
# 큐 워커 시작
bundle exec solid_queue start

# 또는 별도 터미널에서
rails solid_queue:start
```

### Production 환경
```bash
# systemd 서비스로 등록
# Procfile 또는 다른 프로세스 매니저 사용
bin/solid-queue start
```

## 모니터링

### 작업 상태 확인
```ruby
# 대기 중인 작업 수
SolidQueue::Job.where(finished_at: nil).count

# 실패한 작업
SolidQueue::FailedExecution.all

# 예약된 작업
SolidQueue::ScheduledExecution.all
```

### 로그 확인
```bash
# Rails 로그에서 작업 로그 확인
tail -f log/development.log | grep "Job"

# Solid Queue 프로세스 로그
tail -f log/solid_queue.log
```

## 문제 해결

### 1. 작업이 처리되지 않음
- Solid Queue 워커 프로세스가 실행 중인지 확인: `ps aux | grep solid_queue`
- 큐 이름이 올바른지 확인
- 데이터베이스 연결 확인
- 로그 확인: `log/development.log`

### 2. 작업이 반복 실패함
- 재시도 정책 확인: `ApplicationJob`의 `retry_on` 설정
- 에러 메시지 확인: `SolidQueue::FailedExecution`
- 외부 API (OpenAI, Neo4j) 연결 확인

### 3. 성능 문제
- 큐별 스레드 수 조정: `config/solid_queue.yml`
- 배치 크기 조정
- 데이터베이스 인덱스 확인

## 환경별 설정

### Development
- 상세 로깅 활성화
- 배치 크기: 100
- 스레드 수: 낮음 (개발용)

### Test
- 동기 처리 가능 (ActiveJob 테스트 모드)
- 스레드 수: 1
- 로깅: 최소

### Production
- 배치 크기: 500
- 스레드 수: 높음 (성능 최적화)
- 로깅: 기본 정보만
- 큐 이름 접두사: `certigraph_api_production`

## 보안 고려사항

1. **민감한 데이터**: Job 인자에 민감한 정보 저장 금지
2. **권한 확인**: Job 내에서 사용자 권한 재확인
3. **시간 초과**: 장시간 작업에 대한 `timeout` 설정
4. **에러 로깅**: 민감한 정보는 로그에 기록하지 않기

## 성능 최적화

### 1. 큐 우선순위 활용
```ruby
class HighPriorityJob < ApplicationJob
  queue_as :high_priority
end
```

### 2. 배치 처리
```ruby
SolidQueue::Job.find_in_batches do |batch|
  # 배치 처리
end
```

### 3. 비동기 체인
```ruby
ProcessPdfJob
  .perform_later(id)
  .chain(GenerateEmbeddingJob.set(wait: 10.minutes))
```

## 참고 자료

- [Rails Solid Queue 공식 문서](https://github.com/rails/solid_queue)
- [ActiveJob 가이드](https://guides.rubyonrails.org/active_job_basics.html)
- [Neo4j REST API](https://neo4j.com/docs/rest-api/current/)
- [OpenAI Embeddings API](https://platform.openai.com/docs/guides/embeddings)

## 기여 가이드

새로운 Job을 추가할 때:

1. `app/jobs/` 디렉토리에 파일 생성
2. 적절한 큐 선택
3. 재시도 정책 설정
4. 로깅 추가
5. 테스트 작성 (`test/jobs/`)
