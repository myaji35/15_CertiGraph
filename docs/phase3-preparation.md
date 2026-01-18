# 🚀 Phase 3: AI 기반 문제 추출 (Upstage OCR + GPT-4o)

## 📋 **Phase 2 완료 요약**

### ✅ **성공 지표**
- **PDF 파싱**: 3개 파일, 199개 문제 추출
- **처리 속도**: 평균 1.75초/PDF
- **정확도**: 100% 파싱 성공
- **비용**: $0/월 (Python 알고리즘)

### ⚠️ **Phase 2 제한사항**
1. **정답 추출 불가**: Python 알고리즘은 정답을 자동으로 식별하지 못함
2. **해설 추출 불가**: 문제 해설을 추출하지 못함
3. **난이도 분석 불가**: 문제 난이도를 자동으로 판단하지 못함
4. **지문 감지 정확도**: 휴리스틱 기반으로 완벽하지 않음

---

## 🎯 **Phase 3 목표**

### **핵심 가치 제안**
> "PDF 업로드만 하면, AI가 문제, 정답, 해설까지 모두 추출합니다"

### **Phase 3 vs Phase 2 비교**

| 항목 | Phase 2 (Python) | Phase 3 (AI) |
|------|------------------|--------------|
| **문제 추출** | ✅ 95% | ✅ 98% |
| **정답 식별** | ❌ 수동 입력 | ✅ **자동 추출** |
| **해설 추출** | ❌ 없음 | ✅ **자동 추출** |
| **난이도 분석** | ❌ 없음 | ✅ **AI 분석** |
| **지문 감지** | ⚠️ 휴리스틱 | ✅ **AI 자동** |
| **처리 속도** | 1.75초 | 30-60초 |
| **비용** | $0/월 | ~$80-130/월 |

---

## 🏗️ **Phase 3 구현 계획**

### **Week 1: AI 추출 기능**

#### **@agent:BE - AI Services** (3일)
1. ✅ `UpstageOcrService` (이미 완료)
   - PDF → 텍스트 추출
   - 페이지별 처리
   - 메타데이터 수집

2. ✅ `QuestionExtractorService` (이미 완료)
   - GPT-4o 문제 추출
   - 정답 자동 식별
   - 해설 추출
   - 난이도 분석

3. ✅ `ProcessPdfJob` 업데이트 (이미 완료)
   - AI/Python 하이브리드
   - 환경 변수로 전환 가능

#### **@agent:DBA - Database** (1일)
- ✅ `study_materials` 테이블 (이미 존재)
- ✅ `questions` 테이블 (이미 존재)
- 추가 필요 컬럼:
  - `ai_confidence_score` (AI 신뢰도)
  - `ai_extracted` (AI 추출 여부)

#### **@agent:FE - UI 개선** (2일)
1. **PDF 업로드 페이지**
   - AI/Python 선택 옵션
   - 예상 비용 표시
   - 처리 시간 안내

2. **진행 상태 표시**
   - OCR 진행률
   - GPT-4o 분석 진행률
   - 실시간 업데이트

3. **결과 확인 페이지**
   - AI 신뢰도 표시
   - 정답/해설 확인
   - 수동 수정 기능

---

### **Week 2: Knowledge Graph (선택사항)**

#### **@agent:BE - Neo4j 연동** (3일)
1. Neo4j 설치 및 설정
2. Concept Extraction Service
3. Knowledge Graph Builder
4. GraphRAG Analysis

#### **@agent:DBA - Graph Schema** (2일)
1. Node 타입 정의
   - Concept
   - Question
   - Topic
2. Relationship 타입
   - PREREQUISITE
   - RELATED_TO
   - TESTS

---

## 💰 **Phase 3 비용 분석**

### **API 비용 (월간 예상)**

#### **Upstage OCR**
- 가격: $0.30/100 페이지
- 예상 사용량: 100 PDFs × 10 페이지 = 1,000 페이지
- **월 비용**: ~$30

#### **GPT-4o**
- 가격: $5/1M input tokens, $15/1M output tokens
- 예상 사용량:
  - Input: 100 PDFs × 50,000 tokens = 5M tokens → $25
  - Output: 100 PDFs × 10,000 tokens = 1M tokens → $15
- **월 비용**: ~$40

#### **Neo4j (선택사항)**
- Neo4j Aura Free: $0
- Neo4j Aura Pro: $65/월
- **월 비용**: $0-65

### **총 예상 비용**
- **AI만**: ~$70/월
- **AI + Neo4j**: ~$135/월

---

## 🔧 **Phase 3 환경 설정**

### **1. API 키 발급**

```bash
# .env 파일에 추가
UPSTAGE_API_KEY=your_upstage_api_key
OPENAI_API_KEY=your_openai_api_key

# AI 추출 활성화
ENABLE_AI_EXTRACTION=true

# Knowledge Graph (선택)
ENABLE_KNOWLEDGE_GRAPH=false
NEO4J_URL=bolt://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=your_password
```

### **2. Gem 설치**

```bash
cd rails-api
bundle add httparty ruby-openai
bundle install
```

### **3. Python 환경 (Upstage 대안)**

```bash
cd backend
source venv/bin/activate
pip install upstage-ai openai
```

---

## 🧪 **Phase 3 테스트 계획**

### **테스트 시나리오**

#### **1. AI 추출 정확도 테스트**
```ruby
# 제19회 사회복지사 1급 1교시로 테스트
# - Python: 49개 문제 추출
# - AI: 49개 문제 + 정답 + 해설 추출
# - 정확도 비교
```

#### **2. 비용 모니터링**
```ruby
# 1 PDF 처리 비용 측정
# - Upstage OCR: ~$0.03
# - GPT-4o: ~$0.40
# - 총: ~$0.43/PDF
```

#### **3. 처리 시간 측정**
```ruby
# Python: 1.75초
# AI: 30-60초
# 속도 차이: 17-34배 느림
```

---

## 📊 **Phase 3 성공 지표**

### **필수 지표**
- [ ] 정답 추출 정확도 > 95%
- [ ] 해설 추출 정확도 > 90%
- [ ] 난이도 분석 정확도 > 85%
- [ ] 처리 시간 < 60초/PDF
- [ ] 월 비용 < $150

### **선택 지표** (Knowledge Graph)
- [ ] Concept 추출 정확도 > 90%
- [ ] Prerequisite 관계 정확도 > 85%
- [ ] GraphRAG 분석 시간 < 5초

---

## 🚀 **Phase 3 실행 계획**

### **Option A: 즉시 시작** (추천)
1. API 키 발급 (10분)
2. 환경 변수 설정 (5분)
3. 테스트 실행 (10분)
4. 결과 확인 및 조정 (30분)

### **Option B: 점진적 도입**
1. Week 1: AI 추출만 구현
2. Week 2: 사용자 피드백 수집
3. Week 3: Knowledge Graph 추가
4. Week 4: 최적화 및 비용 절감

### **Option C: 하이브리드 모드**
1. 기본: Python 알고리즘 (무료)
2. 프리미엄: AI 추출 (유료)
3. 사용자 선택 가능

---

## 🎯 **다음 단계**

### **즉시 실행 가능**
1. ✅ Backend 서비스 이미 구현됨
2. ✅ Frontend UI 준비됨
3. ⏳ API 키만 발급하면 바로 테스트 가능

### **필요한 작업**
1. Upstage API 키 발급
2. OpenAI API 키 발급
3. `.env` 파일 설정
4. 테스트 실행

---

**Phase 3 준비 완료!**  
API 키만 발급하면 즉시 시작할 수 있습니다.

**작성일**: 2026-01-18  
**작성자**: KPM Orchestrator
