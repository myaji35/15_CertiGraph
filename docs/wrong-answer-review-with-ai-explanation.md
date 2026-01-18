# 틀린 문제 풀기 + AI 개념 설명 기능 기획서

**작성일**: 2026-01-18  
**프로젝트**: CertiGraph (ExamsGraph)  
**목적**: 오답 복습 + 실시간 인터넷 검색 기반 AI 개념 설명 기능

---

## 📊 **1. 개요**

사용자가 **틀린 문제만 모아서 복습**하고, 각 문제의 **핵심 개념을 AI가 최신 인터넷 검색 결과를 기반으로 설명**하는 기능입니다.

### **핵심 가치**
- ✅ **효율적 복습**: 틀린 문제만 집중 학습
- ✅ **최신 지식**: 인터넷 검색으로 최신 개념/법령 확인
- ✅ **깊이 있는 이해**: AI가 핵심 개념을 쉽게 설명
- ✅ **맥락 이해**: 관련 개념과 연결하여 설명

---

## 🎯 **2. 사용자 시나리오**

### **시나리오 1: 틀린 문제 복습 시작**
```
1. 사용자가 대시보드에서 "틀린 문제 풀기" 클릭
2. 시스템이 모든 틀린 문제 목록 표시
3. 사용자가 "복습 시작" 클릭
4. 첫 번째 틀린 문제 표시
```

### **시나리오 2: 문제 풀이 + AI 설명 확인**
```
1. 문제를 읽고 답안 선택
2. "제출" 클릭
3. 정답/오답 즉시 표시
4. "AI 개념 설명 보기" 버튼 표시
5. 클릭 시 AI가 실시간으로:
   - 인터넷에서 최신 정보 검색
   - 핵심 개념 추출
   - 쉬운 설명 생성
   - 관련 개념 연결
```

### **시나리오 3: 최신 법령 확인**
```
예: 사회복지사법 관련 문제

1. 문제: "2024년 개정된 사회복지사법에 따르면..."
2. AI 설명:
   ┌─────────────────────────────────────────┐
   │ 🔍 최신 정보 검색 중...                  │
   │                                         │
   │ ✅ 2024년 사회복지사법 개정 내용 확인    │
   │                                         │
   │ 📚 핵심 개념:                            │
   │ - 사회복지사 자격 요건 변경              │
   │ - 보수교육 의무화 (연 8시간)             │
   │ - 윤리강령 강화                          │
   │                                         │
   │ 🔗 관련 개념:                            │
   │ - 사회복지사 윤리강령                    │
   │ - 보수교육 제도                          │
   │                                         │
   │ 📖 출처:                                 │
   │ - 법제처 국가법령정보센터 (2024.03.15)   │
   │ - 보건복지부 공고 제2024-123호           │
   └─────────────────────────────────────────┘
```

---

## 🏗️ **3. 데이터 모델**

### **3.1 WrongAnswer (오답 노트)**
```ruby
class WrongAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :question
  belongs_to :study_set
  
  # 속성
  - id: UUID
  - user_id: UUID (FK)
  - question_id: UUID (FK)
  - study_set_id: UUID (FK)
  - selected_answer: String (틀린 답)
  - correct_answer: String (정답)
  - attempt_count: Integer (재시도 횟수)
  - last_attempted_at: DateTime
  - mastered: Boolean (복습 완료 여부)
  - created_at: DateTime
  
  # 메서드
  - mark_as_mastered!
  - increment_attempt!
end
```

### **3.2 ConceptExplanation (개념 설명 캐시)**
```ruby
class ConceptExplanation < ApplicationRecord
  belongs_to :question
  
  # 속성
  - id: UUID
  - question_id: UUID (FK)
  - concept_keywords: String[] (핵심 키워드)
  - explanation: Text (AI 생성 설명)
  - search_results: JSONB (검색 결과)
  - related_concepts: String[] (관련 개념)
  - sources: JSONB (출처 정보)
  - generated_at: DateTime
  - expires_at: DateTime (7일 후)
  
  # 메서드
  - expired?
  - refresh!
end
```

---

## 📱 **4. 화면 구성**

### **4.1 틀린 문제 목록 화면**

```
┌─────────────────────────────────────────────────────┐
│  ❌ 틀린 문제 복습                                    │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  📊 통계                                             │
│  ┌─────────┬─────────┬─────────┐                   │
│  │ 총 오답  │ 복습 완료 │ 남은 문제 │                   │
│  │  24개   │   12개   │   12개   │                   │
│  └─────────┴─────────┴─────────┘                   │
│                                                     │
│  🔍 필터                                             │
│  [ 전체 ▼ ] [ 최근 순 ▼ ] [복습 시작]               │
│                                                     │
│  📝 문제 목록                                         │
│  ─────────────────────────────────────────────────  │
│  1. 사회복지정책의 재정에 관한 설명으로...            │
│     ❌ 틀린 횟수: 2회 | 마지막 시도: 2일 전           │
│     [다시 풀기] [설명 보기]                           │
│                                                     │
│  2. 영국의 지역사회복지 역사에 관한...                │
│     ❌틀린 횟수: 1회 | 마지막 시도: 5일 전            │
│     [다시 풀기] [설명 보기]                           │
│                                                     │
│  3. 예산에 관한 설명으로 옳지 않은 것은...            │
│     ✅ 복습 완료 | 마지막 시도: 1주 전                │
│     [다시 풀기] [설명 보기]                           │
└─────────────────────────────────────────────────────┘
```

### **4.2 틀린 문제 풀이 화면**

```
┌─────────────────────────────────────────────────────┐
│  ❌ 틀린 문제 복습 (12/24)                            │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  📝 문제 1                                           │
│  ─────────────────────────────────────────────────  │
│  사회복지정책의 재정에 관한 설명으로 옳은 것은?       │
│                                                     │
│  ○ ① 영국은 Zero Based Budgeting을 채택...         │
│  ○ ② 사회보험방식은 기여금을 재원으로...             │
│  ○ ③ 조세기반 방식은 소득 재분배...                 │
│  ○ ④ 우리나라 사회복지 재정은...                    │
│  ○ ⑤ 사회복지 지출은 GDP 대비...                    │
│                                                     │
│  ⚠️ 이전 답안: ① (틀림)                              │
│  ✅ 정답: ②                                          │
│                                                     │
│  [제출하기]                                          │
└─────────────────────────────────────────────────────┘
```

### **4.3 AI 개념 설명 화면 (핵심!)**

```
┌─────────────────────────────────────────────────────┐
│  🤖 AI 개념 설명                                      │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  🔍 최신 정보 검색 중...                              │
│  [████████████░░░░░░░░] 70%                         │
│  "사회복지정책 재정" 관련 최신 정보 수집 중...         │
│                                                     │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  ✅ 검색 완료! (2026년 1월 기준)                      │
│                                                     │
│  📚 핵심 개념                                         │
│  ─────────────────────────────────────────────────  │
│  이 문제는 **사회복지정책의 재정 방식**에 관한        │
│  내용입니다.                                         │
│                                                     │
│  1️⃣ 사회보험방식                                     │
│     - 기여금(보험료)을 재원으로 함                    │
│     - 예: 국민연금, 건강보험                         │
│     - 소득 재분배 효과가 상대적으로 약함              │
│                                                     │
│  2️⃣ 조세기반 방식                                    │
│     - 일반 세금을 재원으로 함                        │
│     - 예: 기초생활보장, 아동수당                     │
│     - 소득 재분배 효과가 강함                        │
│                                                     │
│  💡 왜 ②번이 정답인가?                                │
│  ─────────────────────────────────────────────────  │
│  사회보험방식은 **기여금(보험료)**을 재원으로 하며,   │
│  일반 세금이 아닙니다. 따라서 ②번이 옳은 설명입니다.  │
│                                                     │
│  ❌ 왜 ①번이 틀렸는가?                                │
│  ─────────────────────────────────────────────────  │
│  영국은 **Incremental Budgeting**을 주로 사용하며,   │
│  Zero Based Budgeting은 미국에서 도입한 방식입니다.  │
│                                                     │
│  🔗 관련 개념                                         │
│  ─────────────────────────────────────────────────  │
│  • 사회보험 4대 보험 (국민연금, 건강보험, 고용보험,   │
│    산재보험)                                         │
│  • 조세기반 복지제도 (기초생활보장제도)               │
│  • 소득 재분배 정책                                  │
│                                                     │
│  📖 참고 자료 (최신순)                                │
│  ─────────────────────────────────────────────────  │
│  1. 보건복지부 (2025.12) - 사회보험 재정 현황        │
│  2. 국민연금공단 (2025.11) - 기여금 체계             │
│  3. 한국보건사회연구원 (2025.10) - 복지재정 분석     │
│                                                     │
│  [다음 문제] [북마크] [공유하기]                      │
└─────────────────────────────────────────────────────┘
```

---

## 🔧 **5. 기술 구현**

### **5.1 인터넷 검색 API**

#### **옵션 1: Perplexity API (추천)**
```ruby
# 실시간 검색 + AI 요약
class PerplexitySearchService
  def search_and_explain(question_text, keywords)
    response = HTTP.post(
      'https://api.perplexity.ai/chat/completions',
      headers: {
        'Authorization' => "Bearer #{ENV['PERPLEXITY_API_KEY']}",
        'Content-Type' => 'application/json'
      },
      json: {
        model: 'llama-3.1-sonar-large-128k-online',
        messages: [
          {
            role: 'system',
            content: '당신은 사회복지사 시험 전문가입니다. 최신 법령과 정책을 기반으로 정확하게 설명해주세요.'
          },
          {
            role: 'user',
            content: <<~PROMPT
              다음 문제의 핵심 개념을 최신 정보를 검색하여 설명해주세요:
              
              문제: #{question_text}
              키워드: #{keywords.join(', ')}
              
              다음 형식으로 답변해주세요:
              1. 핵심 개념 설명
              2. 정답 해설
              3. 오답 해설
              4. 관련 개념
              5. 최신 법령/정책 (있는 경우)
            PROMPT
          }
        ]
      }
    )
    
    JSON.parse(response.body)
  end
end
```

#### **옵션 2: Tavily Search API**
```ruby
# 검색 전문 API
class TavilySearchService
  def search(query)
    response = HTTP.post(
      'https://api.tavily.com/search',
      json: {
        api_key: ENV['TAVILY_API_KEY'],
        query: query,
        search_depth: 'advanced',
        include_answer: true,
        include_raw_content: false,
        max_results: 5
      }
    )
    
    JSON.parse(response.body)
  end
end
```

### **5.2 AI 설명 생성 서비스**

```ruby
class ConceptExplanationService
  def initialize(question)
    @question = question
  end
  
  def generate_explanation
    # 1. 캐시 확인
    cached = ConceptExplanation.find_by(question_id: @question.id)
    return cached if cached && !cached.expired?
    
    # 2. 키워드 추출
    keywords = extract_keywords(@question.content)
    
    # 3. 인터넷 검색
    search_results = search_latest_info(keywords)
    
    # 4. AI 설명 생성
    explanation = generate_ai_explanation(
      question: @question,
      keywords: keywords,
      search_results: search_results
    )
    
    # 5. 캐시 저장
    ConceptExplanation.create!(
      question_id: @question.id,
      concept_keywords: keywords,
      explanation: explanation[:text],
      search_results: search_results,
      related_concepts: explanation[:related_concepts],
      sources: explanation[:sources],
      generated_at: Time.current,
      expires_at: 7.days.from_now
    )
  end
  
  private
  
  def extract_keywords(text)
    # LLM으로 핵심 키워드 추출
    prompt = <<~PROMPT
      다음 문제에서 핵심 키워드 3-5개를 추출해주세요:
      #{text}
      
      JSON 형식으로 반환: ["키워드1", "키워드2", ...]
    PROMPT
    
    response = call_llm(prompt)
    JSON.parse(response)
  end
  
  def search_latest_info(keywords)
    # Perplexity 또는 Tavily로 검색
    PerplexitySearchService.new.search_and_explain(
      @question.content,
      keywords
    )
  end
  
  def generate_ai_explanation(question:, keywords:, search_results:)
    prompt = <<~PROMPT
      당신은 사회복지사 시험 전문가입니다.
      
      문제: #{question.content}
      정답: #{question.answer}
      해설: #{question.explanation}
      
      검색 결과:
      #{search_results}
      
      다음 형식으로 설명을 생성해주세요:
      
      1. 핵심 개념 (3-5문장, 쉽게 설명)
      2. 정답 해설 (왜 정답인지)
      3. 오답 해설 (왜 틀렸는지)
      4. 관련 개념 (3-5개)
      5. 최신 정보 (법령, 정책 등)
      6. 출처 (검색 결과 기반)
      
      JSON 형식으로 반환해주세요.
    PROMPT
    
    response = call_llm(prompt)
    JSON.parse(response)
  end
end
```

---

## 📡 **6. API 엔드포인트**

### **6.1 틀린 문제 관리**

```ruby
# 틀린 문제 목록 조회
GET /api/v1/wrong_answers
Response:
{
  "data": [
    {
      "id": "uuid",
      "question": {
        "id": "uuid",
        "content": "문제 내용...",
        "answer": "②"
      },
      "selected_answer": "①",
      "attempt_count": 2,
      "last_attempted_at": "2026-01-16T10:00:00Z",
      "mastered": false
    }
  ],
  "meta": {
    "total": 24,
    "mastered": 12,
    "remaining": 12
  }
}

# 틀린 문제 복습 세션 시작
POST /api/v1/wrong_answers/sessions
Request:
{
  "study_set_id": "uuid",
  "question_count": 10  // 선택사항
}
Response:
{
  "data": {
    "session_id": "uuid",
    "questions": [...],
    "total_questions": 10
  }
}

# 틀린 문제 정답 제출
POST /api/v1/wrong_answers/:id/submit
Request:
{
  "selected_answer": "②"
}
Response:
{
  "data": {
    "is_correct": true,
    "correct_answer": "②",
    "mastered": true  // 연속 2회 정답 시
  }
}
```

### **6.2 AI 개념 설명**

```ruby
# AI 개념 설명 생성/조회
GET /api/v1/questions/:id/explanation
Response:
{
  "data": {
    "question_id": "uuid",
    "explanation": {
      "core_concept": "핵심 개념 설명...",
      "correct_answer_explanation": "정답 해설...",
      "wrong_answer_explanation": "오답 해설...",
      "related_concepts": ["개념1", "개념2"],
      "latest_info": "최신 법령/정책...",
      "sources": [
        {
          "title": "보건복지부 공고",
          "url": "https://...",
          "date": "2025-12-01"
        }
      ]
    },
    "generated_at": "2026-01-18T11:00:00Z",
    "search_status": "completed"
  }
}

# 실시간 검색 상태 확인 (SSE)
GET /api/v1/questions/:id/explanation/stream
Response (Server-Sent Events):
data: {"status": "searching", "progress": 30, "message": "최신 정보 검색 중..."}
data: {"status": "analyzing", "progress": 60, "message": "개념 분석 중..."}
data: {"status": "completed", "progress": 100, "data": {...}}
```

---

## 🎨 **7. UX 플로우**

### **플로우 1: 틀린 문제 복습 시작**
```
1. 대시보드 → "틀린 문제 풀기" 클릭
2. 틀린 문제 목록 표시
3. "복습 시작" 클릭
4. 첫 번째 문제 표시
5. 답안 선택 → 제출
6. 정답/오답 표시
7. "AI 설명 보기" 버튼 표시
```

### **플로우 2: AI 설명 확인**
```
1. "AI 설명 보기" 클릭
2. 로딩 애니메이션 (검색 중...)
   - "최신 정보 검색 중..."
   - "개념 분석 중..."
   - "설명 생성 중..."
3. 설명 표시 (애니메이션)
   - 핵심 개념 (타이핑 효과)
   - 정답 해설
   - 오답 해설
   - 관련 개념
   - 출처
4. "다음 문제" 또는 "북마크" 선택
```

---

## 🚀 **8. 구현 우선순위**

### **Phase 1: 기본 기능 (1주)**
- [ ] WrongAnswer 모델 및 마이그레이션
- [ ] 틀린 문제 목록 API
- [ ] 틀린 문제 복습 세션 API
- [ ] 기본 UI (목록, 풀이 화면)

### **Phase 2: AI 설명 (1주)**
- [ ] ConceptExplanation 모델
- [ ] Perplexity API 연동
- [ ] AI 설명 생성 서비스
- [ ] 설명 화면 UI
- [ ] 실시간 검색 상태 표시 (SSE)

### **Phase 3: 고도화 (1주)**
- [ ] 캐싱 최적화
- [ ] 관련 개념 링크
- [ ] 북마크 기능
- [ ] 공유 기능
- [ ] 통계 대시보드

---

## 📊 **9. 성능 최적화**

### **9.1 캐싱 전략**
```ruby
# 7일 캐시
- 동일 문제는 7일간 재검색 안 함
- 만료 시 자동 갱신

# Redis 캐시
- 검색 결과 임시 저장 (1시간)
- 중복 요청 방지
```

### **9.2 비동기 처리**
```ruby
# Sidekiq Job
class GenerateExplanationJob < ApplicationJob
  def perform(question_id)
    question = Question.find(question_id)
    ConceptExplanationService.new(question).generate_explanation
  end
end

# 사용
GenerateExplanationJob.perform_later(question.id)
```

---

## 💰 **10. 비용 예측**

### **Perplexity API**
- 요금: $0.001 per request (sonar-large)
- 예상 사용량: 1,000 requests/month
- 월 비용: **$1**

### **대안: OpenAI + Tavily**
- OpenAI GPT-4: $0.03 per 1K tokens
- Tavily Search: $0.005 per search
- 월 비용: **$5-10**

---

## ✅ **11. 완료 기준**

### **사용자 관점**
- [ ] 틀린 문제만 모아서 볼 수 있다
- [ ] 틀린 문제를 다시 풀 수 있다
- [ ] AI 설명을 실시간으로 확인할 수 있다
- [ ] 최신 법령/정책 정보를 확인할 수 있다
- [ ] 관련 개념을 탐색할 수 있다

### **기술 관점**
- [ ] 인터넷 검색 API 연동 완료
- [ ] AI 설명 생성 서비스 구현
- [ ] 캐싱 시스템 구현
- [ ] 실시간 상태 표시 (SSE)
- [ ] 응답 시간 < 5초

---

## 📚 **12. 참고 자료**

- Perplexity API: https://docs.perplexity.ai/
- Tavily Search API: https://tavily.com/
- Server-Sent Events: https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events

---

**다음 단계**: Phase 1 구현 시작 (WrongAnswer 모델 + API)
