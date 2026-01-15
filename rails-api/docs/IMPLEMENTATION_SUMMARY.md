# Solid Queue 백그라운드 Job 시스템 구현 요약

## 프로젝트 정보
- **프로젝트**: CertiGraph (AI 자격증 마스터 플랫폼)
- **Rails 버전**: 7.2.2
- **구현 날짜**: 2026-01-15
- **큐 시스템**: Solid Queue (Rails 7.2+ 내장)

## 구현 완료 항목

### 1. 설정 파일 (Configuration)

#### `config/solid_queue.yml` ✓
- SQLite 기반 Solid Queue 데이터베이스 설정
- 환경별(development, test, production) 설정 분리
- 6개 전문 큐 정의:
  - `default`: 기본 작업 (5 threads)
  - `high_priority`: 높은 우선순위 (10 threads)
  - `low_priority`: 낮은 우선순위 (3 threads)
  - `pdf_processing`: PDF 처리 (2 threads)
  - `embedding_generation`: 임베딩 생성 (4 threads)
  - `graph_update`: 그래프 업데이트 (3 threads)
- Production 환경에서는 PostgreSQL 사용 가능하도록 설정됨

#### 환경 설정 ✓
- `config/environments/development.rb`: `queue_adapter = :solid_queue`
- `config/environments/production.rb`: `queue_adapter = :solid_queue`, 큐 접두사 설정
- `config/initializers/solid_queue.rb`: 초기화 로깅 및 설정

### 2. Job 클래스 (Background Jobs)

#### `ProcessPdfJob` ✓
**위치**: `/app/jobs/process_pdf_job.rb`
- **큐**: `pdf_processing`
- **재시도 정책**: Timeout 30초 대기 3회, 지수 백오프 5회
- **기능**:
  - PDF 파일 다운로드 및 파싱
  - 문제 추출 및 청킹
  - 지문 복제 처리
  - 각 문제마다 `GenerateEmbeddingJob` 자동 큐 추가
  - 상태 관리 (pending → processing → completed/failed)
  - 오류 로깅

#### `GenerateEmbeddingJob` (신규) ✓
**위치**: `/app/jobs/generate_embedding_job.rb`
- **큐**: `embedding_generation`
- **재시도 정책**: Timeout 10초 대기 3회, 지수 백오프 5회
- **기능**:
  - 문제 텍스트 및 선택지 준비
  - OpenAI Embedding API 호출
  - 임베딩 벡터 저장
  - 자동으로 `UpdateKnowledgeGraphJob` 큐 추가
  - 중복 생성 방지 (이미 있으면 스킵)
  - 텍스트 길이 제한 (8000 자)

#### `UpdateKnowledgeGraphJob` (신규) ✓
**위치**: `/app/jobs/update_knowledge_graph_job.rb`
- **큐**: `graph_update`
- **재시도 정책**: Timeout 15초 대기 4회, 지수 백오프 5회
- **기능**:
  - LLM을 통한 개념 추출
  - Neo4j 개념 노드 생성
  - 문제-개념 관계 생성
  - 개념 간 전제 조건 관계 생성
  - 사용자 성과 그래프 업데이트 (선택)
  - 부분 실패 허용 (일부 그래프 업데이트 실패해도 계속)

#### `ApplicationJob` (기본 설정) ✓
**위치**: `/app/jobs/application_job.rb`
- **기본 큐**: `:default`
- **재시도 정책**:
  - 데드락: 5초 대기, 3회 재시도
  - 일반 에러: 지수 백오프 대기, 5회 재시도
  - 직렬화 에러: 폐기
- **로깅**: 큐 추가, 시작, 완료, 실패 시점 기록
- **에러 핸들링**: 표준 예외 처리 및 로깅

### 3. 데이터베이스 마이그레이션

#### `20260115022805_create_solid_queue_tables.rb` ✓
생성되는 테이블:
- `solid_queue_jobs`: 작업 메타데이터
- `solid_queue_processes`: 워커 프로세스 정보
- `solid_queue_ready_executions`: 실행 대기 중인 작업
- `solid_queue_claimed_executions`: 실행 중인 작업
- `solid_queue_scheduled_executions`: 예약된 작업
- `solid_queue_paused_jobs`: 일시 중지된 작업
- `solid_queue_failed_executions`: 실패한 작업 기록
- `solid_queue_batches`: 배치 작업 그룹
- `solid_queue_batch_jobs`: 배치 내 개별 작업

관계: 외래키를 통한 데이터 무결성 보장

#### `20260115022806_add_embedding_to_questions.rb` ✓
추가되는 컬럼:
- `embedding`: vector(1536) - OpenAI 임베딩 저장
- `embedding_generated_at`: datetime - 생성 시간 기록

### 4. 테스트 파일

#### `test/jobs/process_pdf_job_test.rb` ✓
테스트 케이스:
- 올바른 큐에 대기 중인지 확인
- 대기열에 추가되는지 확인
- 각 문제마다 임베딩 작업 생성 확인

#### `test/jobs/generate_embedding_job_test.rb` ✓
테스트 케이스:
- 올바른 큐 확인
- 업데이트 그래프 작업 생성 확인
- 누락된 문제 오류 처리
- 기존 임베딩 스킵 확인

#### `test/jobs/update_knowledge_graph_job_test.rb` ✓
테스트 케이스:
- 올바른 큐 확인
- 문제 ID만으로 실행
- 사용자 ID와 함께 실행
- 누락된 데이터 오류 처리
- 재시도 정책 확인

### 5. 문서

#### `docs/SOLID_QUEUE_SETUP.md` ✓
포함 내용:
- 전체 아키텍처 설명
- 각 Job 클래스 상세 설명
- 실행 명령어
- 모니터링 방법
- 문제 해결 가이드
- 성능 최적화 팁
- 보안 고려사항

#### `docs/SOLID_QUEUE_EXAMPLES.md` ✓
포함 내용:
- 컨트롤러에서의 Job 사용 예제
- 모델에서의 자동 큐 추가
- 동기/비동기 실행
- 예약된 실행
- 일괄 처리
- 예외 처리
- 모니터링 방법
- 테스트 방법
- 웹 대시보드 구성
- 성능 최적화

## 아키텍처 흐름도

```
PDF 업로드
    ↓
ProcessPdfJob (pdf_processing 큐)
    ├─ PDF 파싱
    ├─ 문제 추출
    └─ 각 문제마다 GenerateEmbeddingJob 큐에 추가
        ↓
    GenerateEmbeddingJob (embedding_generation 큐)
        ├─ 임베딩 생성 (OpenAI API)
        └─ UpdateKnowledgeGraphJob 큐에 추가
            ↓
        UpdateKnowledgeGraphJob (graph_update 큐)
            ├─ 개념 추출 (LLM)
            ├─ Neo4j 그래프 업데이트
            └─ 사용자 성과 데이터 저장
```

## 핵심 특징

### 1. 확장성
- 큐별 독립적인 스레드 풀로 병렬 처리
- 환경별 스레드 수 설정 가능
- 새로운 Job 추가 용이

### 2. 신뢰성
- 자동 재시도 정책 (지수 백오프)
- 데드락 자동 처리
- 실패한 작업 추적

### 3. 성능
- 비동기 처리로 사용자 요청 응답성 향상
- 배치 처리 지원 (최대 500개 단위)
- 우선순위 기반 큐 처리

### 4. 모니터링
- 작업 상태 추적
- 실패 이유 기록
- 실행 시간 로깅

## 사용 예시

### Controller에서
```ruby
class StudyMaterialsController < ApplicationController
  def create
    @study_material = current_user.study_materials.build(study_material_params)

    if @study_material.save
      ProcessPdfJob.perform_later(@study_material.id)
      render json: @study_material, status: :created
    end
  end
end
```

### Model에서
```ruby
class StudyMaterial < ApplicationRecord
  after_create :enqueue_processing

  private

  def enqueue_processing
    ProcessPdfJob.set(wait: 5.seconds).perform_later(id)
  end
end
```

### Console에서
```ruby
# 비동기 실행
ProcessPdfJob.perform_later(1)

# 예약된 실행 (1시간 후)
ProcessPdfJob.set(wait: 1.hour).perform_later(1)

# 동기 실행 (개발/테스트)
ProcessPdfJob.perform_now(1)

# 모니터링
SolidQueue::Job.where(queue_name: 'pdf_processing').count
SolidQueue::FailedExecution.all
```

## 환경별 차이점

| 환경 | 스레드 수 | 배치 크기 | 로깅 | 특징 |
|------|---------|---------|------|------|
| Development | 낮음 | 100 | 상세 | 로컬 테스트용 |
| Test | 1 | 100 | 최소 | 동기 처리 |
| Production | 높음 | 500 | 기본정보 | 성능 최적화 |

## 다음 단계 (선택)

### 선택 사항
1. **PostgreSQL 마이그레이션**: Production 환경에서 PostgreSQL 사용
2. **Redis 캐싱**: Solid Cache 통합
3. **모니터링 대시보드**: Solid Queue 대시보드 활성화
4. **메트릭 수집**: Prometheus/Datadog 통합
5. **Webhook 알림**: Job 완료/실패 시 알림

## 파일 체크리스트

### 생성된 파일
- ✓ `config/solid_queue.yml`
- ✓ `config/initializers/solid_queue.rb`
- ✓ `app/jobs/generate_embedding_job.rb`
- ✓ `app/jobs/update_knowledge_graph_job.rb`
- ✓ `db/migrate/20260115022805_create_solid_queue_tables.rb`
- ✓ `db/migrate/20260115022806_add_embedding_to_questions.rb`
- ✓ `test/jobs/process_pdf_job_test.rb`
- ✓ `test/jobs/generate_embedding_job_test.rb`
- ✓ `test/jobs/update_knowledge_graph_job_test.rb`
- ✓ `docs/SOLID_QUEUE_SETUP.md`
- ✓ `docs/SOLID_QUEUE_EXAMPLES.md`

### 수정된 파일
- ✓ `app/jobs/application_job.rb` - 재시도 정책 추가
- ✓ `app/jobs/process_pdf_job.rb` - 큐 설정 및 임베딩 작업 추가
- ✓ `config/environments/development.rb` - queue_adapter 설정
- ✓ `config/environments/production.rb` - queue_adapter 설정

## 실행 방법

### 마이그레이션 실행
```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api
rails db:migrate
```

### 개발 환경에서 테스트
```bash
# 큐 워커 시작
bundle exec solid_queue start

# 또는 별도 터미널에서 API 서버
rails s

# 테스트 실행
rails test test/jobs/
```

### 프로덕션 배포
```bash
# 마이그레이션
bundle exec rails db:migrate RAILS_ENV=production

# Solid Queue 워커 시작
bundle exec solid_queue start --environment production
```

## 지원 및 문제 해결

문제가 발생할 경우:
1. `log/development.log` 또는 `log/production.log` 확인
2. `docs/SOLID_QUEUE_SETUP.md`의 "문제 해결" 섹션 참고
3. `SolidQueue::FailedExecution` 테이블에서 실패한 작업 확인

## 결론

Rails 7.2.2의 내장 Solid Queue를 사용하여 강력하고 확장 가능한 백그라운드 작업 처리 시스템을 구현했습니다. PDF 처리, 임베딩 생성, 그래프 업데이트 등의 장시간 작업이 비동기로 처리되어 사용자 경험이 크게 향상됩니다.
