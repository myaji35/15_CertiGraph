# Product Requirements Document (PRD) - Certi-Graph

| 문서 정보 | 내용 |
| :--- | :--- |
| **Project Name** | Certi-Graph (AI 자격증 마스터) |
| **Version** | v1.2 |
| **Status** | MVP Development - 사회복지사 1급 특화 |
| **Owner** | CEO Seungsik Kang |
| **Last Updated** | 2025-12-06 |
| **MVP Target Exam** | 제23회 사회복지사 1급 국가시험 (2025년 1월) |

---

## 1. Executive Summary (개요)

### 1.1. Product Vision
"사용자가 가진 PDF 한 권으로 시작하는 가장 완벽한 개인화 AI 튜터."
정적인 자격증 기출문제(PDF)를 동적인 학습 플랫폼으로 변환하고, Knowledge Graph 기술을 활용해 학습자의 '지식 구멍(Knowledge Gap)'을 시각적으로 분석 및 처방한다.

### 1.2. Key Problems to Solve
* **비효율적 학습:** 기출문제를 반복해서 풀다 보면 정답의 '위치(번호)'를 외우게 되어 실제 학습 효과가 떨어짐.
* **분석의 부재:** 틀린 문제에 대한 해설은 있지만, 내가 '어떤 개념'이 약해서 틀렸는지 구조적으로 파악하기 어려움.
* **자료의 파편화:** 사용자가 가진 좋은 자료(학원 교재, 요약집)를 디지털화하여 효율적으로 학습할 도구가 없음.

### 1.3. Value Proposition
* **User-Driven Content:** 어떤 자격증이든 PDF만 올리면 즉시 시험 대비 모드로 전환.
* **Deep Analysis:** GraphRAG를 통해 단순 오답 체크를 넘어, 취약한 개념 간의 연결 고리를 파악.
* **Visualized Progress:** 3D Brain Map을 통해 나의 지식 정복도를 직관적으로 확인.

---

## 2. Target Audience & Business Model

### 2.1. Target User

#### MVP Phase (사회복지사 1급 특화)
* **Primary:** 사회복지사 1급 국가시험 준비생 (연간 ~25,000명 응시)
* **Persona:**
  - 사회복지학과 졸업(예정)자, 20~30대
  - 학원 수강 + 독학 병행
  - 기출문제 반복 학습 중 "정답 위치 암기" 문제 경험
  - 시험까지 1~3개월 남은 시점

#### 확장 Phase (향후)
* **Primary:** 기사, 산업기사, 공무원, 어학 등 객관식 시험을 준비하는 수험생.
* **Secondary:** 사내 승진 시험이나 특정 인증 시험을 준비하는 직장인.

### 2.2. Business Model
* **Type:** B2C SaaS (Web)
* **Pricing:** **Season Pass (10,000 KRW)**
    * 사용자가 설정한 시험일(D-Day)까지 무제한 이용.
    * PDF 업로드, AI 분석, 무제한 모의고사 포함.

---

## 3. User Stories (핵심 시나리오)

| ID | Actor | User Story | Acceptance Criteria |
| :--- | :--- | :--- | :--- |
| **US-01** | User | 문제집을 생성하고 관리하고 싶다. (CRUD) | 문제집명, 개요, 자격증, 시험일자 입력/수정/삭제 가능. |
| **US-02** | User | 생성한 문제집에 PDF 학습자료를 업로드하고 싶다. | 문제집 선택 → PDF 업로드 → 진행률 표시 → 파싱 완료 알림. |
| **US-03** | System | 업로드된 PDF에서 문제, 보기, 해설, 지문을 정확히 분리해야 한다. | Upstage API 활용, 지문이 있는 경우 문제마다 지문 복제 청킹. |
| **US-04** | User | 문제집으로 모의고사를 응시하고 싶다. (CBT 환경) | 실제 시험과 유사한 UI, **보기 순서 랜덤 셔플링** 적용. |
| **US-05** | System | 사용자의 오답을 분석해 취약 개념을 도출해야 한다. | GraphRAG 기반 추론, 오답 원인(개념 부족 vs 실수) 태깅. |
| **US-06** | User | 이메일 또는 소셜 계정으로 회원가입/로그인하고 싶다. | 이메일/비밀번호 또는 Google/Kakao 소셜 로그인 지원, 로그인 후 대시보드 이동. |
| **US-07** | User | 1만원 시즌권을 결제하고 무제한 서비스를 이용하고 싶다. | 가입 후 결제 페이지 유도, 결제 완료 시 권한 부여. |
| **US-08** | User | 실제 시험을 대비해 내가 틀린 문제만 모아서 다시 풀고 싶다. | 오답 노트(틀린 문제) 모드 제공, 맞히면 오답 목록에서 제거 선택 가능. |
| **US-09** | User | [Phase 2] 나의 학습 상태를 3D 지도로 확인하고 싶다. | 3D 공간에 노드(개념) 표시, 취약 노드(Red) 클릭 시 집중 문제 풀이 연결. |

---

## 4. Functional Requirements (기능 명세)

### 4.1. 문제집 관리 (Study Set Management)
* **CRUD 기능:**
    * **Create:** 문제집명, 개요(설명), 자격증 선택. **(시험일 선택 시 오늘 기준 가장 가까운 자격증 시험일 자동 추천)**
    * **Read:** 사용자의 문제집 목록 조회, 문제집 상세 정보 조회
    * **Update:** 문제집명, 개요 수정
    * **Delete:** 문제집 삭제 (하위 학습자료 및 문제도 함께 삭제)
* **메타데이터:**
    * 문제집 ID, 문제집명, 개요, 자격증 ID, 시험일자
    * 생성일, 수정일, 총 학습자료 수, 총 문제 수
    * 학습 상태 (not_started, in_progress, completed)

### 4.2. 학습자료 관리 (Study Material Management)
* **업로드 프로세스:**
    1. 사용자가 문제집 선택
    2. PDF 파일 업로드 (최대 50MB)
    3. 파일 중복 감지 (해시 기반)
    4. 업로드 진행률 표시
    5. 파싱 작업 시작 (백그라운드)
* **파싱 프로세스:**
    * **OCR & Parsing:** Upstage Document Parse API 사용
    * **문서 구조 인식:** Heading, Paragraph, Table을 마크다운으로 변환
    * **Image Handling:** 이미지 Crop 후 GPT-4o로 Captioning
    * **지문 복제 전략:** "다음 글을 읽고..." 유형 감지 시 지문을 하위 문제 각각에 포함
* **데이터 스키마:**
    * 학습자료: PDF 경로, 파싱 상태, 문제 수
    * 문제: Question, Options(List), Answer, Explanation, Linked_Concept, Difficulty

### 4.2. Knowledge Graph Construction
* **Strategy:** Aggressive LLM Utilization (품질 최우선).
* **Ontology Level:** Macro (Subject -> Chapter -> Key Concept).
* **Automation:**
    * LLM이 문제 텍스트를 분석하여 사전 정의된(혹은 동적으로 생성된) Concept Node에 연결.
    * **Query:** "이 문제는 어떤 개념을 테스트하는가? 선수 지식은 무엇인가?"

### 4.3. Test Engine & Analysis
* **Randomization:** DB 저장 순서와 무관하게 Frontend 렌더링 시 보기 순서 무작위 섞기 (Anti-Memorization).
* **Modes:**
    * **Standard:** 랜덤 셔플 모의고사.
    * **Retest (오답 노트):** 과거 틀린 문제만 모아서 다시 풀기.
    * **Drill (약점 공략):** 취약 개념(Weak Concept)과 연관된 문제 집중 풀이.
* **GraphRAG Reasoning:**
    * 오답 발생 시, 연결된 Knowledge Graph를 탐색.
    * LLM 프롬프트: "사용자가 개념 A와 B가 연결된 문제를 틀렸다. 과거 C문제 오답 이력을 볼 때, 사용자는 어떤 원리 이해가 부족한가?"

### 4.4. Visualization (Frontend)
* **Library:** React Three Fiber (Three.js).
* **Interaction:**
    * Zoom/Pan 가능한 3D 네트워크 그래프.
    * Node Color: Green(숙련), Red(취약), Gray(미응시).
    * Click Event: 해당 개념 관련 문제만 모은 'Drill Mode' 진입.

---


### 4.5. Payment System (Season Pass)
* **Provider:** Toss Payments (or PortOne).
* **Product:** Season Pass (10,000 KRW).
* **Flow:**
    1. 회원가입/로그인 완료.
    2. 무료 체험(맛보기) 제한 도달 or 메인 진입 시 결제 모달 팝업.
    3. 결제 완료 → `user.is_paid = true` 및 `user.valid_until = test_date` 업데이트.

---

## 5. Technical Architecture

### 5.1. Tech Stack
* **Frontend:**
    * Framework: `Next.js 14+` (App Router)
    * Visualization: `React Three Fiber`, `Drei`
    * State Management: `Zustand`
    * Styling: `Tailwind CSS`
* **Backend:**
    * Language: `Python 3.10+`
    * Framework: `FastAPI` (Async 처리 유리)
    * Orchestration: `LangChain` or `LangGraph`
* **Database:**
    * **Vector DB:** `Pinecone` (Serverless, 관리 용이) - 문제 텍스트 임베딩 저장.
    * **Graph DB:** `Neo4j` (AuraDB Free/Pro) - 개념 간 관계 및 학습 이력 저장.
    * **RDB:** `PostgreSQL` (Supabase) - 사용자 정보, 결제 정보.
* **AI Models:**
    * OCR: `Upstage Document Parse`
    * LLM (Reasoning): `GPT-4o` (Main Logic), `GPT-4o-mini` (Simple Tasks)
    * Embedding: `OpenAI text-embedding-3-small`

### 5.2. Data Flow
1.  **Upload:** User -> Next.js -> FastAPI -> **Upstage API** -> JSON Return.
2.  **Process:** FastAPI -> **Chunking Logic** -> Embedding -> **Pinecone**.
3.  **Graph:** Chunk Data -> **LLM (Extraction)** -> **Neo4j** (Create Nodes/Rel).
4.  **Test:** User Request -> FastAPI -> Pinecone (Fetch Qs) -> Next.js (Shuffle).
5.  **Analyze:** Result -> **GraphRAG Search (Neo4j)** -> LLM (Insight) -> User Report.

---

## 6. Roadmap & Milestones

### Phase 1: Core Engine & Payment (MVP) - 2 Weeks
* [ ] Upstage API 연동 및 파싱 파이프라인 구축 (Python).
* [ ] 지문 복제 청킹 로직 구현 및 Vector DB 적재.
* [ ] 기본적인 문제 풀이 UI 및 채점 기능 개발.
* [ ] **결제 모듈 연동 (토스페이먼츠) 및 권한 제어 로직 구현.**

### Phase 2: Intelligence & Graph - 3 Weeks
* [ ] Neo4j 스키마 설계 및 LLM 자동 태깅 구현.
* [ ] GraphRAG 기반 오답 원인 분석 프롬프트 엔지니어링.
* [ ] 개인화된 해설 생성 API 개발.

### Phase 3: Visualization & Launch - 3 Weeks
* [ ] React Three Fiber 기반 3D 뇌지도(Brain Map) 구현.
* [ ] 배포 및 안정화.

---

## 7. Success Metrics (KPIs)

### MVP Phase (사회복지사 1급 - 첫 1개월)

| 지표 | 목표 | 측정 방법 |
|------|------|----------|
| **사용자 획득** | 500명 가입 | Supabase Auth 기준 |
| **유료 전환율** | 5% (25명) | 시즌 패스 구매 수 |
| **DAU (일간 활성 사용자)** | 100명 | 최소 1회 문제 풀이 |
| **세션 시간** | 평균 20분 이상 | Frontend 이벤트 추적 |
| **PDF 업로드 성공률** | 90% 이상 | 파싱 완료 / 업로드 시도 |
| **NPS (순추천지수)** | 30 이상 | 인앱 설문 |

### North Star Metric
**"주간 활성 학습 문제 수"** - 사용자가 실제로 풀이한 문제 수 (단순 조회 제외)

---

## 8. Constraints & Assumptions

### 8.1. Constraints (제약 조건)

| 구분 | 제약 | 상세 |
|------|------|------|
| **예산** | 인프라 | 월 30만원 이내 (Vercel, Supabase, Neo4j Free Tier) |
| **예산** | LLM API | 월 50만원 이내 (GPT-4o 사용량 제한 필요) |
| **인력** | 개발 | 1인 풀스택 개발 (CEO 직접 개발) |
| **시간** | MVP | 2025년 1월 사회복지사 1급 시험 전 출시 필수 |
| **기술** | PDF 파싱 | Upstage API 의존 (대안: Google Document AI) |

### 8.2. Assumptions (가정)

| ID | 가정 | 검증 방법 | 리스크 |
|----|------|----------|--------|
| **A1** | 사회복지사 1급 기출문제 PDF는 Upstage API로 90% 이상 정확히 파싱 가능하다 | 실제 기출 PDF 10개 테스트 | 🟠 Medium |
| **A2** | 사용자들은 "보기 랜덤 셔플링"을 핵심 가치로 인식한다 | 랜딩페이지 A/B 테스트 | 🟢 Low |
| **A3** | 시즌 패스 1만원은 적절한 가격대이다 | 초기 유저 인터뷰 5명 | 🟠 Medium |
| **A4** | GraphRAG 기반 취약점 분석이 사용자에게 유의미한 인사이트를 제공한다 | MVP 후 사용자 피드백 | 🔴 High |

---

## 9. Risk Analysis

| ID | 리스크 | 확률 | 영향 | 대응 전략 |
|----|--------|------|------|----------|
| **R1** | PDF 파싱 품질 불량 (표, 이미지 등) | 🟠 Medium | 🔴 High | 사회복지사 1급 기출 형식에 특화된 후처리 로직 개발 |
| **R2** | LLM API 비용 폭증 | 🟠 Medium | 🔴 High | GPT-4o-mini 우선 사용, 캐싱 적극 활용, 사용량 상한 설정 |
| **R3** | 사용자 획득 어려움 | 🟠 Medium | 🟠 Medium | 네이버 카페, 에브리타임 등 커뮤니티 타겟 마케팅 |
| **R4** | 시험 일정 전 MVP 완성 실패 | 🟢 Low | 🔴 High | MVP 범위 최소화 (CBT + 오답분석만), 3D 시각화 Phase 2로 이동 |
| **R5** | 경쟁사(에듀윌/해커스) 유사 기능 출시 | 🟢 Low | 🟠 Medium | Knowledge Graph 기반 분석이라는 차별점 강화 |

### Risk Mitigation Priority
1. **R1 (PDF 파싱)**: MVP 착수 전 기출 PDF 10개 파싱 테스트 필수
2. **R2 (LLM 비용)**: 일일/월간 API 호출 상한 설정
3. **R4 (일정)**: 주 단위 스프린트 리뷰로 진척 관리

---

## 10. Non-Functional Requirements (NFR)

### 10.1. Performance

| 항목 | 요구사항 | 측정 방법 |
|------|----------|----------|
| PDF 업로드 → 학습세트 생성 | 50페이지 PDF 기준 3분 이내 | 백엔드 로그 |
| 문제 로딩 | 1초 이내 | Lighthouse |
| 페이지 초기 로딩 | LCP 2.5초 이내 | Core Web Vitals |

### 10.2. Security

| 항목 | 요구사항 |
|------|----------|
| 인증 | Supabase Auth (이메일/소셜 로그인) |
| 데이터 전송 | HTTPS 필수 |
| 민감 정보 | API 키는 환경변수로 관리, 클라이언트 노출 금지 |
| 개인정보 | 최소 수집 원칙, 개인정보처리방침 명시 |

### 10.3. Scalability

| 항목 | MVP | 확장 Phase |
|------|-----|-----------|
| 동시 사용자 | 100명 | 1,000명 |
| 총 사용자 | 1,000명 | 10,000명 |
| PDF 저장 | 10GB | 100GB |

### 10.4. Accessibility (접근성)

| 항목 | 요구사항 |
|------|----------|
| 키보드 네비게이션 | 마우스 없이 모든 핵심 기능 사용 가능 |
| 색상 대비 | WCAG AA 기준 충족 (4.5:1 이상) |
| 스크린 리더 | 주요 UI 요소에 aria-label 적용 |
| 반응형 디자인 | 모바일/태블릿에서도 사용 가능 |

---

## 11. MVP Scope Definition

### 11.1. In Scope (MVP 포함)

| 기능 | 상세 | 우선순위 |
|------|------|----------|
| ✅ PDF 업로드 | 사회복지사 1급 기출문제 PDF 업로드 | P0 |
| ✅ 문서 파싱 | Upstage API 기반 문제/보기/해설 분리 | P0 |
| ✅ CBT 모의고사 | 보기 랜덤 셔플링, 타이머, 채점 | P0 |
| ✅ 오답 노트 | 틀린 문제 모아 풀기, 취약점 모아 풀기 | P0 |
| ✅ 결제 시스템 | 토스페이먼츠 연동 (1만원 시즌패스) | P0 |
| ✅ 오답 분석 | 틀린 문제 목록 + LLM 기반 취약 개념 도출 | P0 |
| ✅ 기본 대시보드 | 학습 진도, 정답률 통계 | P1 |
| ✅ 사용자 인증 | 이메일/소셜 로그인 (Supabase Auth) | P0 |

### 11.2. Out of Scope (MVP 제외 → Phase 2+)

| 기능 | 이유 | 예정 Phase |
|------|------|-----------|
| ❌ 3D Brain Map 시각화 | 개발 복잡도 높음, MVP 핵심 아님 | Phase 3 |
| ❌ 모바일 앱 (iOS/Android) | 웹 우선, 반응형으로 대응 | Phase 3+ |
| ❌ 다중 자격증 지원 | 사회복지사 1급 특화 후 확장 | Phase 2 |
| ❌ 커뮤니티/게시판 | 핵심 기능 아님 | 미정 |
| ❌ AI 튜터 챗봇 | GraphRAG 분석에 집중 | Phase 3 |

---

## 12. Competitive Analysis

### 12.1. 시장 현황 (사회복지사 1급)

| 항목 | 데이터 |
|------|--------|
| 연간 응시자 | ~25,000명 (2024년 25,458명) |
| 합격률 | 32~40% (2024년 32%, 5년 최저) |
| 시험 구성 | 200문항, 객관식 5지선다, 280분 |
| 주요 학습 방식 | 학원 강의 + 기출문제 반복 |

### 12.2. 경쟁사 분석

| 경쟁사 | 강점 | 약점 | Certi-Graph 차별점 |
|--------|------|------|-------------------|
| **에듀윌** | 브랜드 인지도 1위, 체계적 커리큘럼 | 고가 (수십만원), 수동적 강의 학습 | 1만원 시즌패스, 능동적 문제 풀이 |
| **해커스** | 가격 경쟁력, 무료 콘텐츠 다수 | 기출 분석 깊이 부족 | Knowledge Graph 기반 취약점 분석 |
| **일반 기출앱** | 무료/저가 | 정답 위치 암기 문제, 분석 없음 | 보기 랜덤 셔플링, AI 취약점 분석 |

### 12.3. Positioning

```
            고가격
               │
    에듀윌 ●   │
               │
               │   ● Certi-Graph (목표 포지션)
    ───────────┼───────────
    수동적     │        능동적/분석적
    (강의 중심) │        (문제풀이 중심)
               │
    해커스 ●   │   ● 기출앱
               │
            저가격
```

---

## 13. Appendix

### A. 사회복지사 1급 시험 과목 구조

| 영역 | 과목 | 문항수 |
|------|------|--------|
| 사회복지 기초 | 인간행동과 사회환경, 사회복지조사론 | 50문항 |
| 사회복지 실천 | 사회복지실천론, 사회복지실천기술론, 지역사회복지론 | 75문항 |
| 사회복지 정책과 제도 | 사회복지정책론, 사회복지행정론, 사회복지법제론 | 75문항 |
| **합계** | **8과목** | **200문항** |

### B. 관련 링크

- [Q-NET 사회복지사 1급](https://www.q-net.or.kr/site/welfare)
- [보건복지부 시험 공고](https://www.mohw.go.kr)
- [에듀윌 사회복지사](https://well.eduwill.net/Social/Main.asp)
- [해커스 사회복지사](https://sabok.edu2080.co.kr/)cy며ㅔ