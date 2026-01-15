# GraphRAG Quick Start Guide

**목적**: GraphRAG 시스템을 빠르게 이해하고 사용하기 위한 간단한 가이드

---

## 📚 구조 한눈에 보기

```
User의 오답 발생
    ↓
GraphRagAnalysisJob (비동기)
    ↓
GraphRagService (분석 엔진)
  ├─ 그래프 탐색 (BFS)
  ├─ 오류 유형 분류
  ├─ LLM 추론
  └─ 약점 점수 계산
    ↓
ErrorAnalysisService (상세 분석)
  ├─ 개념 격차 식별
  ├─ 패턴 인식
  └─ 학습 경로 생성
    ↓
RecommendationService (추천 생성)
  ├─ 문제 선정
  ├─ 난이도 조정
  └─ 효율성 계산
    ↓
AnalysisResult + LearningRecommendation 저장
    ↓
API로 사용자에게 반환
```

---

## 🚀 5분 안에 시작하기

### 1단계: 분석 트리거

```ruby
# Controller에서
user = current_user
question = Question.find(params[:question_id])
selected_answer = params[:selected_answer]
study_set = user.study_sets.find(params[:study_set_id])

# 비동기 분석 시작
GraphRagAnalysisJob.perform_later(
  user.id,
  question.id,
  selected_answer,
  study_set.id
)

render json: { status: 'processing' }, status: 202
```

### 2단계: 결과 조회

```ruby
# API 호출
GET /api/v1/graph_rag/analysis/123

# 응답 (완료 시)
{
  "status": "completed",
  "error_type": "concept_gap",
  "concept_gap_score": 0.68,
  "confidence_score": 0.82,
  "related_concepts": [...],
  "learning_path": [...]
}
```

### 3단계: 추천 사용

```ruby
# 활성 추천 조회
GET /api/v1/study_sets/789/graph_rag/recommendations

# 추천 활성화
POST /api/v1/graph_rag/recommendations/456/activate

# 추천 피드백
POST /api/v1/graph_rag/recommendations/456/feedback
{
  "feedback": "도움이 되었습니다",
  "rating": 5
}
```

---

## 🔑 핵심 개념 5가지

### 1️⃣ Concept Gap Score (0-1)
```
의미: 사용자가 해야 할 학습의 양
0.0 = 완전 숙달
1.0 = 완전 미숙달
0.6+ = 집중 학습 필요
```

### 2️⃣ Error Type
```
careless    = 부주의 오답 (개념은 이해함)
concept_gap = 개념 부족 (이해 부족)
mixed       = 혼합 (둘 다)
```

### 3️⃣ Learning Path
```
단계별 학습 계획:
- 선행 개념 먼저 복습
- 연습 문제 포함
- 시간 추정 제공
```

### 4️⃣ Recommendation Type
```
remedial      = 약점 집중 공략 (낮은 정답률)
progressive   = 단계적 학습 (중간 정답률)
comprehensive = 종합 복습 (많은 약점)
```

### 5️⃣ Learning Efficiency Index
```
효율성 지수 (0-1):
0.7+ = 매우 효율적 추천
0.5-0.7 = 보통 효율
0-0.5 = 저효율 (실패 위험)
```

---

## 📊 중요한 쿼리들

### 사용자의 약점 조회
```ruby
# 모든 분석 결과
AnalysisResult.where(user_id: user.id, status: 'completed')

# 높은 개념 격차
AnalysisResult.where(user_id: user.id).high_concept_gap

# 높은 신뢰도
AnalysisResult.where(user_id: user.id).high_confidence

# 관련 개념별 집계
analyses = AnalysisResult.where(user_id: user.id)
concepts = {}
analyses.each do |a|
  a.related_concepts.each do |c|
    concepts[c[:concept_id]] ||= 0
    concepts[c[:concept_id]] += 1
  end
end
```

### 활성 추천 조회
```ruby
# 모든 활성 추천
LearningRecommendation.where(user_id: user.id, status: 'active')

# 높은 우선순위
LearningRecommendation.where(user_id: user.id).high_priority

# 높은 효율성
LearningRecommendation.where(user_id: user.id).high_efficiency

# 성공 확률 높음
LearningRecommendation.where(user_id: user.id).high_success_rate
```

### 통계 조회
```ruby
# 분석 통계
analyses = AnalysisResult.where(user_id: user.id)
{
  total: analyses.count,
  avg_gap: analyses.average(:concept_gap_score),
  error_types: analyses.group(:error_type).count,
  avg_processing_time: analyses.average(:processing_time_ms)
}
```

---

## 🧪 로컬 테스트

### Rails 콘솔에서 실행
```ruby
# 사용자 생성
user = User.create(email: 'test@example.com', name: 'Test User')

# 공부 세트 생성
study_set = StudySet.create(user: user, title: '수학', certification: 'SAT')

# 질문 생성
question = Question.create(
  study_material: study_set.study_materials.first,
  content: "Sample question",
  answer: "②",
  options: { "①" => "A", "②" => "B", "③" => "C" }
)

# 분석 실행
service = GraphRagService.new
result = service.analyze_wrong_answer(user, question, "①", study_set)

# 결과 확인
puts result.error_type
puts result.concept_gap_score
puts result.related_concepts
```

### 테스트 실행
```bash
# 전체 테스트
bundle exec rspec spec/services/

# 특정 테스트만
bundle exec rspec spec/services/graph_rag_service_spec.rb -e "analyze_wrong_answer"

# 상세 출력
bundle exec rspec spec/services/ -fd

# 성능 프로파일링
bundle exec rspec spec/services/ --profile 5
```

---

## 🐛 디버깅 팁

### 분석 로그 확인
```bash
# Sidekiq 로그
tail -f log/sidekiq.log

# 에러 확인
AnalysisResult.where(status: 'failed').recent.first.error_message

# 처리 시간 확인
AnalysisResult.average(:processing_time_ms)
```

### 분석 상태 확인
```ruby
# 처리 중인 분석
AnalysisResult.where(status: 'processing')

# 실패한 분석
AnalysisResult.where(status: 'failed').recent

# 느린 분석
AnalysisResult.where('processing_time_ms > ?', 3000)
```

### 추천 문제 확인
```ruby
rec = LearningRecommendation.find(id)
rec.recommended_questions  # 추천된 문제 ID 배열
rec.learning_path          # 학습 경로
rec.weakness_analysis      # 약점 분석
rec.estimated_learning_hours  # 예상 시간
```

---

## ⚡ 성능 최적화 팁

### 1. 배치 처리 사용
```ruby
# ❌ 나쁜 예: 개별 분석
questions.each do |q|
  GraphRagAnalysisJob.perform_later(user.id, q.id, answer, study_set.id)
end

# ✅ 좋은 예: 배치 처리
GraphRagAnalysisJob.analyze_batch(user, questions, study_set)
```

### 2. 결과 캐싱
```ruby
# 최근 분석 조회 (캐시됨)
Rails.cache.fetch("user_#{user.id}_analysis", expires_in: 1.hour) do
  AnalysisResult.where(user_id: user.id).recent.limit(10)
end
```

### 3. N+1 쿼리 방지
```ruby
# ❌ N+1
analyses.each { |a| a.question.content }

# ✅ 최적화
analyses.includes(:question).each { |a| a.question.content }
```

---

## 📱 API 응답 예제

### 분석 시작
```json
POST /api/v1/graph_rag/analyze
{
  "analysis": {
    "question_id": 123,
    "selected_answer": "①"
  }
}

Response (202 Accepted):
{
  "status": "analysis_started",
  "job_id": "abc-123-def",
  "message": "분석이 시작되었습니다. 잠시 후 결과를 확인하세요."
}
```

### 분석 결과 조회
```json
GET /api/v1/graph_rag/analysis/456

Response (200 OK):
{
  "id": 456,
  "status": "completed",
  "error_type": "concept_gap",
  "concept_gap_score": 0.65,
  "confidence_score": 0.78,
  "related_concepts": [
    {
      "concept_id": 10,
      "name": "선형대수",
      "relevance_score": 0.9,
      "relationship_type": "prerequisite"
    }
  ],
  "learning_path": [
    {
      "step": 1,
      "concept": "기초 선형대수",
      "action": "intensive_review",
      "estimated_minutes": 30
    }
  ],
  "processing_time_ms": 1850
}
```

### 약점 조회
```json
GET /api/v1/study_sets/789/graph_rag/weaknesses

Response (200 OK):
{
  "total_analyses": 15,
  "weakness_count": 5,
  "weaknesses": [
    {
      "concept_id": 1,
      "concept_name": "개념1",
      "gap_score": 0.8,
      "occurrence_count": 3
    }
  ],
  "critical_weaknesses": [...]
}
```

### 추천 조회
```json
GET /api/v1/study_sets/789/graph_rag/recommendations

Response (200 OK):
{
  "total_recommendations": 3,
  "recommendations": [
    {
      "id": 1,
      "type": "remedial",
      "status": "active",
      "priority_level": 8,
      "total_questions": 10,
      "success_probability": 0.75,
      "estimated_hours": 2.5
    }
  ]
}
```

---

## 🎯 일반적인 사용 사례

### 사용 사례 1: 오답 분석 및 복습
```
1. 사용자가 문제를 틀림
2. GraphRAG 분석 시작
3. 약점 개념 식별
4. 학습 경로 생성
5. 연습 문제 추천
6. 사용자가 추천 문제 풀이
```

### 사용 사례 2: 정기적 진행도 평가
```
1. 1주일 오답 모두 분석
2. 종합 약점 리스트 생성
3. 우선순위별 추천 생성
4. 효율성 높은 추천부터 제시
```

### 사용 사례 3: 맞춤형 학습 경로
```
1. 사용자 학습 스타일 파악
2. 집중력 수준 측정
3. 난이도 자동 조정
4. 학습 속도 최적화
```

---

## 📖 추가 리소스

- **상세 문서**: `docs/GRAPHRAG_IMPLEMENTATION_GUIDE.md`
- **테스트 시나리오**: `docs/GRAPHRAG_TEST_SCENARIOS.md`
- **구현 요약**: `/GRAPHRAG_IMPLEMENTATION_SUMMARY.md`
- **API 문서**: Swagger/OpenAPI (생성 예정)

---

## 💡 주요 함수 체트시트

| 함수 | 파일 | 목적 | 입력 | 출력 |
|------|------|------|------|------|
| `analyze_wrong_answer` | GraphRagService | 완전 분석 | user, question, answer, study_set | AnalysisResult |
| `analyze_error_in_depth` | ErrorAnalysisService | 상세 분석 | user, question, answer, analysis | Hash |
| `generate_comprehensive_recommendation` | RecommendationService | 추천 생성 | user, study_set, analysis | LearningRecommendation |
| `recommend_questions` | RecommendationService | 문제 추천 | user, study_set, count | Array<Question> |
| `adaptive_difficulty_adjustment` | RecommendationService | 난이도 조정 | user, study_set | Integer(1-5) |

---

**마지막 업데이트**: 2025-01-15
**버전**: 1.0
**상태**: 프로덕션 준비 완료

