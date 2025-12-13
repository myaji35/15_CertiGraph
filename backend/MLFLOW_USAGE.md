# MLflow 사용 가이드 - ExamsGraph AI 튜터 모니터링

ExamsGraph에 MLflow가 통합되어 AI 튜터의 품질 관리, 프롬프트 최적화, 사용자 피드백 수집, 비용 모니터링을 수행할 수 있습니다.

## 📋 목차

1. [MLflow 서버 시작](#mlflow-서버-시작)
2. [시나리오 A: GraphRAG 경로 추적](#시나리오-a-graphrag-경로-추적)
3. [시나리오 B: 프롬프트 실험](#시나리오-b-프롬프트-실험)
4. [시나리오 C: 사용자 피드백 수집](#시나리오-c-사용자-피드백-수집)
5. [시나리오 D: 비용 모니터링](#시나리오-d-비용-모니터링)
6. [분석 대시보드 사용](#분석-대시보드-사용)

---

## MLflow 서버 시작

### Docker Compose로 시작

```bash
docker-compose up -d mlflow
```

MLflow UI 접속: [http://localhost:5000](http://localhost:5000)

---

## 시나리오 A: GraphRAG 경로 추적

**목적**: "틀린 문제를 보고 약점을 진단하는 로직(GraphRAG)이 정말 멍청하지 않은지 검증"

### API 사용 예제

```python
# POST /v1/mlflow/trace-graph-exploration
{
  "question_id": "q_001",
  "wrong_concept": "데이터베이스 정규화",
  "graph_path": [
    {
      "node": "정규화",
      "relation": "포함",
      "next_node": "제1정규형",
      "similarity_score": 0.92
    },
    {
      "node": "제1정규형",
      "relation": "해결",
      "next_node": "이상현상",
      "similarity_score": 0.85
    },
    {
      "node": "이상현상",
      "relation": "관련",
      "next_node": "SQL 문법",  # 이상한 경로!
      "similarity_score": 0.45
    }
  ],
  "retrieval_params": {
    "depth": 3,
    "similarity_threshold": 0.7,
    "max_hops": 5
  },
  "final_explanation": "정규화는 데이터 중복을 제거하고..."
}
```

### MLflow UI에서 확인

1. **Experiments** → `GraphRAG_Path_Tracing` 선택
2. **Run** 클릭 → `graph_exploration_path.json` 아티팩트 다운로드
3. **경로 시각화**:
   ```
   정규화 → 제1정규형 (0.92)
           → 이상현상 (0.85)
           → SQL 문법 (0.45) ⚠️ 이상한 경로 발견!
   ```
4. **조치**: `similarity_threshold`를 0.7 → 0.8로 올려서 엉뚱한 경로 차단

---

## 시나리오 B: 프롬프트 실험

**목적**: "엄격한 선생님 톤 vs 친절한 코치 톤" 중 어느 것이 더 효과적인지 비교

### API 사용 예제

```python
# POST /v1/mlflow/compare-prompts
{
  "question_id": "q_002",
  "user_answer": "제3정규형",
  "correct_answer": "제2정규형",
  "prompt_variants": {
    "v1_strict": "당신은 엄격한 교수입니다. 학생이 틀렸을 때 명확히 지적하세요.",
    "v2_friendly": "당신은 친절한 코치입니다. 학생의 노력을 인정하면서 부드럽게 설명하세요.",
    "v3_encouraging": "당신은 격려형 멘토입니다. 실수를 긍정적으로 받아들이게 하세요."
  },
  "generated_responses": {
    "v1_strict": "틀렸습니다. 제2정규형이 정답입니다. 부분 함수 종속성을 제거해야 합니다.",
    "v2_friendly": "아쉽네요! 거의 다 왔어요. 제2정규형에서는 부분 함수 종속성을 제거합니다.",
    "v3_encouraging": "좋은 시도였어요! 정규화 과정을 이해하고 계시네요. 제2정규형을 한번 더 복습해볼까요?"
  }
}
```

### MLflow UI에서 비교

1. **Experiments** → `Prompt_Experimentation` 선택
2. **Compare Runs** 선택 (v1, v2, v3 체크)
3. **Metrics** 탭에서 `response_length` 비교
4. **Artifacts**에서 각 응답 내용 확인
5. **수동 평가**: 어느 톤이 학습 효과가 높은지 A/B 테스트

---

## 시나리오 C: 사용자 피드백 수집

**목적**: "학생들이 가장 많이 이해 못 한 개념 TOP 5"를 데이터로 확인

### API 사용 예제

```python
# POST /v1/mlflow/log-user-feedback
{
  "session_id": "session_123",
  "question_id": "q_003",
  "ai_explanation": "정규화의 목적은 데이터 중복을 제거하고...",
  "feedback_type": "thumbs_down",  # 또는 "thumbs_up", "followup_question"
  "followup_text": "무슨 말인지 더 쉽게 설명해줘",
  "understanding_score": 2  # 1-5 (1=전혀 이해 못함, 5=완벽히 이해)
}
```

### 피드백 분석

```python
# GET /v1/mlflow/analytics/top-failed-concepts?limit=5
{
  "data": [
    {"concept": "정규화", "failure_count": 42},
    {"concept": "이상현상", "failure_count": 35},
    {"concept": "함수 종속성", "failure_count": 28},
    {"concept": "BCNF", "failure_count": 20},
    {"concept": "조인", "failure_count": 15}
  ],
  "generated_at": "2025-01-15T10:30:00"
}
```

### 조치

1. **"정규화"**에 대한 더 쉬운 설명 노드를 Neo4j에 추가
2. **유튜브 영상 링크**를 지식 그래프에 연결
3. **이미지 예시**를 설명에 포함

---

## 시나리오 D: 비용 모니터링

**목적**: "GPT-4o와 GPT-4o-mini가 제대로 라우팅되는지, 월 구독료가 비용을 커버하는지 확인"

### API 사용 예제

```python
# POST /v1/mlflow/log-llm-cost
{
  "task_type": "simple_greeting",  # 단순 인사
  "model_name": "gpt-4o-mini",
  "input_tokens": 15,
  "output_tokens": 30,
  "estimated_cost": 0.0001,  # USD
  "latency_ms": 450,
  "response_quality": "good"
}

# 복잡한 개념 설명
{
  "task_type": "complex_reasoning",
  "model_name": "gpt-4o",
  "input_tokens": 1500,
  "output_tokens": 800,
  "estimated_cost": 0.05,  # USD
  "latency_ms": 3200,
  "response_quality": "excellent"
}
```

### 비용 분석

```python
# GET /v1/mlflow/analytics/average-cost?user_id=user_001
{
  "data": {
    "average_cost_usd": 0.75,
    "average_cost_krw": 975,  # 약 1,000원
    "user_id": "user_001"
  },
  "generated_at": "2025-01-15T11:00:00"
}
```

### 의사 결정

- **구독료**: ₩10,000
- **평균 비용**: ₩975/사용자
- **마진**: ₩9,025 (90%+)
- **결론**: 현재 가격 정책이 지속 가능함 ✅

---

## 분석 대시보드 사용

### MLflow UI에서 확인 가능한 지표

#### 1. **GraphRAG 탐색 성능**
- **Metric**: `path_length`, `exploration_depth`
- **필터**: `tags.wrong_concept = "정규화"`
- **분석**: 평균 탐색 깊이가 5 hops 이상이면 비효율적

#### 2. **프롬프트 품질 비교**
- **Experiments**: `Prompt_Experimentation`
- **Compare**: 3개 이상의 variant를 나란히 비교
- **결정**: 응답 길이와 수동 평가 점수를 종합

#### 3. **사용자 만족도**
- **Metric**: `satisfaction` (0 or 1), `understanding_score` (1-5)
- **필터**: `tags.status = "review_needed"`
- **분석**: 평균 이해도 점수가 3 이하인 개념 파악

#### 4. **비용 추세**
- **Metric**: `estimated_cost_usd`, `total_tokens`
- **필터**: `tags.model = "gpt-4o"`
- **분석**: 시간대별 비용 패턴, 비싼 모델 사용 빈도

---

## Python 코드 통합 예제

### 실제 서비스에서 MLflow 사용

```python
from app.core.mlflow_config import mlflow_tracker

# GraphRAG 탐색 후 자동 로깅
def explain_wrong_answer(user_id: str, question_id: str):
    # 1. Neo4j에서 지식 그래프 탐색
    graph_path = explore_knowledge_graph(wrong_concept="정규화")

    # 2. LLM으로 설명 생성
    explanation = generate_explanation(graph_path)

    # 3. MLflow에 자동 기록
    mlflow_tracker.trace_graph_exploration(
        user_id=user_id,
        question_id=question_id,
        wrong_concept="정규화",
        graph_path=graph_path,
        retrieval_params={"depth": 3, "threshold": 0.7},
        final_explanation=explanation
    )

    return explanation

# 사용자 피드백 수집
def handle_user_feedback(session_id: str, feedback: str):
    mlflow_tracker.log_user_feedback(
        session_id=session_id,
        user_id=current_user.id,
        question_id=question_id,
        ai_explanation=last_explanation,
        user_feedback=feedback,
        understanding_score=3
    )
```

---

## 환경 변수 설정

```bash
# .env
MLFLOW_TRACKING_URI=http://mlflow:5000
```

---

## 다음 단계

1. **A/B 테스트**: 프롬프트 v1, v2를 실제 사용자에게 랜덤 배포
2. **자동 알림**: 이해도 점수가 2 이하인 개념이 10건 이상 발생하면 Slack 알림
3. **비용 경보**: 일일 비용이 $50 초과 시 자동 알림
4. **대시보드**: Grafana + MLflow API로 실시간 모니터링 대시보드 구축

---

## 문의

MLflow 사용 중 문의사항은 [MLflow Docs](https://mlflow.org/docs/latest/index.html)를 참조하거나 팀에 문의하세요.
