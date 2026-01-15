# AI 임베딩 시스템 가이드 (Epic 2)

## 개요

Epic 2의 AI 임베딩 시스템은 OpenAI API를 통해 문서와 질문을 벡터로 변환하고, 이를 데이터베이스에 저장하여 유사도 검색, GraphRAG 기반 분석, 개념 관계 파악 등에 활용하는 시스템입니다.

## 주요 기능

### 1. OpenAI API 통합
- **GPT-4o/4o-mini**: 추론 작업 (개념 분석, 오답 원인 파악)
- **text-embedding-3-small**: 1536차원 임베딩 벡터 생성
- 자동 재시도 로직 및 에러 핸들링

### 2. 문서 청킹 및 임베딩
- 문서를 512토큰 크기의 청크로 분할 (64토큰 오버랩)
- 각 청크의 임베딩 생성 및 배치 처리
- 매그니튜드 계산으로 벡터 정규화

### 3. 데이터베이스 저장
- **DocumentChunk**: 문서 분할 단위 저장
- **Embedding**: 벡터 데이터 저장 (JSON 형식)
- **ChunkQuestion**: 청크와 질문의 관계 저장

### 4. 백그라운드 작업
- PDF 처리 완료 시 자동 임베딩 생성
- 비동기 처리로 UI 블로킹 방지
- 실패 시 자동 재시도

## 기술 스택

### 의존성
```ruby
gem "ruby-openai", "~> 7.0"
```

### 모델
- `Embedding`: 임베딩 벡터 저장
- `DocumentChunk`: 문서 청크
- `ChunkQuestion`: 중간 테이블

### 서비스
- `OpenaiClient`: OpenAI API 통합
- `EmbeddingService`: 임베딩 생성 및 저장

### 백그라운드 작업
- `GenerateEmbeddingJob`: 임베딩 생성 작업

## 사용 방법

### 1. 환경 설정

`.env` 파일에 OpenAI API 키 설정:
```
OPENAI_API_KEY=sk-your-api-key-here
```

### 2. 문서 임베딩 생성

```ruby
# 학습 자료 전체의 임베딩 생성
embedding_service = EmbeddingService.new
count = embedding_service.generate_embeddings_for_document(study_material)
puts "Generated #{count} embeddings"

# 또는 백그라운드 작업으로 실행
GenerateEmbeddingJob.perform_later(study_material.id, "study_material")
```

### 3. 질문 임베딩 생성

```ruby
# 단일 질문 임베딩 생성
success = embedding_service.generate_embedding_for_question(question)

# 또는 백그라운드 작업으로
GenerateEmbeddingJob.perform_later(question.id, "question")
```

### 4. 임베딩 검색 및 유사도 계산

```ruby
# 벡터 검색
query_text = "객체지향 프로그래밍"
query_embedding = embedding_service.generate_embedding(query_text)

# 유사도 계산
embedding = Embedding.first
similarity = embedding.similarity_to(query_embedding)
puts "Similarity: #{(similarity * 100).round(2)}%"
```

### 5. GraphRAG를 위한 개념 분석

```ruby
client = OpenaiClient.new

# GPT-4o를 사용한 추론
prompt = "사용자가 다음 문제들을 틀렸다: #{wrong_questions.map(&:content).join(', ')}. 어떤 개념이 부족한가?"

analysis = client.reason_with_gpt4o(prompt)
puts analysis
```

## 데이터 구조

### Embedding 모델

```ruby
{
  document_chunk_id: integer,      # 외래키
  vector: json,                    # 1536차원 임베딩 벡터
  magnitude: float,                # L2 노름 (정규화용)
  model_version: integer,          # 모델 버전 (기본값 1)
  generated_at: datetime,          # 생성 시간
  created_at: datetime,
  updated_at: datetime
}
```

### DocumentChunk 모델

```ruby
{
  study_material_id: integer,      # 외래키
  content: text,                   # 청크 내용
  token_count: integer,            # 토큰 수 (추정값)
  chunk_index: integer,            # 청크 순서
  start_position: integer,         # 시작 위치 (문자 기준)
  end_position: integer,           # 종료 위치 (문자 기준)
  has_passage: boolean,            # 지문 포함 여부
  passage_context: text,           # 지문 컨텍스트
  created_at: datetime,
  updated_at: datetime
}
```

### ChunkQuestion 모델 (중간 테이블)

```ruby
{
  document_chunk_id: integer,
  question_id: integer,
  created_at: datetime,
  updated_at: datetime
}
```

## 마이그레이션

필요한 마이그레이션 파일:

1. `db/migrate/20260115030000_create_document_chunks.rb`
2. `db/migrate/20260115030001_create_embeddings.rb`
3. `db/migrate/20260115030002_create_chunk_questions.rb`

마이그레이션 실행:
```bash
bundle exec rake db:migrate
```

## 시드 데이터

테스트용 데이터 생성:
```bash
bundle exec rake db:seed
```

시드 데이터 포함 항목:
- 테스트 사용자
- 샘플 문제집
- 샘플 청크 및 임베딩 (더미 벡터)
- 청크-질문 연결

## 성능 고려사항

### 1. 배치 처리
- 최대 100개의 청크를 배치로 처리
- API 레이트 제한을 고려한 배치 크기 설정

### 2. 토큰 수 제한
- 개별 청크: 최대 8191토큰
- 배치 요청: 최대 2,048,000토큰/분

### 3. 캐싱
- 생성된 임베딩은 데이터베이스에 저장
- 동일 청크에 대한 재생성 방지

### 4. 비용 최적화
- text-embedding-3-small 사용 (가장 저렴)
- GPT-4o-mini로 간단한 작업 처리
- 캐싱으로 불필요한 API 호출 제거

## 에러 핸들링

### 재시도 정책

```ruby
retry_on Timeout::Error, wait: 10.seconds, attempts: 3
retry_on OpenAI::Error, wait: :exponentially_longer, attempts: 5
retry_on StandardError, wait: :exponentially_longer, attempts: 3
```

### 일반적인 에러

| 에러 | 원인 | 해결책 |
|------|------|------|
| `OpenAI::Error` | API 에러 | API 키 확인, 할당량 확인 |
| `Timeout::Error` | 네트워크 타임아웃 | 자동 재시도, 타임아웃 시간 증가 |
| `ArgumentError` | 빈 텍스트 | 텍스트 길이 확인 |

## 테스트

### 단위 테스트

```bash
# 모든 테스트 실행
bundle exec rake test

# 특정 테스트 실행
bundle exec rake test TEST=test/services/embedding_service_test.rb
```

### 테스트 파일
- `test/services/embedding_service_test.rb`
- `test/services/openai_client_test.rb`
- `test/models/document_chunk_test.rb`
- `test/models/embedding_test.rb`

### 통합 테스트

```ruby
# 문서 임베딩 생성 테스트
embedding_service = EmbeddingService.new
count = embedding_service.generate_embeddings_for_document(study_material)
assert count > 0
assert Embedding.count > 0
```

## 모니터링

### 로깅

```ruby
Rails.logger.info("Generated #{embedding_count} embeddings for study_material: #{study_material.id}")
```

### 메트릭 추적

```ruby
# 생성된 임베딩 수
Embedding.count

# 청크 수
DocumentChunk.count

# 평균 생성 시간
Embedding.average(:created_at)

# 실패한 작업
Que::Job.where(job_class: 'GenerateEmbeddingJob', finished_at: nil).count
```

## 확장 계획

### Phase 2
- Neo4j 통합: 개념 관계 그래프 구축
- GraphRAG: 다중 홉 추론 기반 오답 분석
- 개념 자동 태깅: LLM 기반 개념 추출

### Phase 3
- 3D 시각화: 임베딩 기반 개념 공간 표현
- 의미 검색: 자연어 질의로 문제 검색
- 개인화 추천: 유사도 기반 약점 문제 추천

## API 비용 추정

### text-embedding-3-small
- 가격: $0.02 per 1M input tokens
- 예시: 50,000개 청크 × 512토큰 = 25,600,000토큰 = $0.512

### GPT-4o
- 입력: $15 per 1M tokens
- 출력: $60 per 1M tokens
- 예시: 1,000개 분석 × 1,000토큰 = $15

### 월간 예산 (10,000명 사용자 가정)
- 임베딩: $5,000 (100M 토큰)
- 분석: $3,000 (200K 분석)
- 총계: ~$8,000/월

## 환경 변수

```bash
# OpenAI API 키
OPENAI_API_KEY=sk-...

# 선택사항
OPENAI_API_TIMEOUT=120  # 타임아웃 (초)
EMBEDDING_BATCH_SIZE=100  # 배치 크기
CHUNK_SIZE=512  # 청크 토큰 크기
CHUNK_OVERLAP=64  # 청크 오버랩
```

## 문제 해결

### 임베딩이 생성되지 않음

1. API 키 확인
   ```bash
   echo $OPENAI_API_KEY
   ```

2. 백그라운드 작업 상태 확인
   ```bash
   bundle exec rails c
   Que::Job.where(job_class: 'GenerateEmbeddingJob').count
   ```

3. 에러 로그 확인
   ```bash
   tail -f log/development.log | grep -i embedding
   ```

### 느린 임베딩 생성

1. 배치 크기 조정
2. 청크 크기 감소 (토큰 수 감소)
3. 병렬 작업 수 증가

### 높은 API 비용

1. 캐시 설정 확인
2. 배치 처리 활용
3. text-embedding-3-small 사용 확인
4. API 할당량 설정

## 참고 자료

- [OpenAI Embeddings API](https://platform.openai.com/docs/guides/embeddings)
- [ruby-openai Gem](https://github.com/alexrudall/ruby-openai)
- [Rail Background Jobs](https://guides.rubyonrails.org/active_job_basics.html)
- [SQLite JSON1](https://www.sqlite.org/json1.html)
