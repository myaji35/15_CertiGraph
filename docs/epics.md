# Certi-Graph - Epic & Story Breakdown

**Author:** Q123
**Date:** 2025-12-18 (Restructured)
**Version:** v2.0
**Project Level:** MVP
**Target Scale:** 사회복지사 1급 시험 대비 (연간 ~25,000명 응시)

---

## Overview

이 문서는 Certi-Graph의 전체 Epic과 Story 구조를 정의합니다. [PRD](../prd.md)와 [Architecture](./architecture.md)를 기반으로 구현 가능한 단위로 분해했습니다.

**Total Epics:** 6
**Total Stories:** 24
**FR Coverage:** 8 Functional Requirements (100%)

---

## Functional Requirements Inventory

| FR ID | 기능 | 상세 | 우선순위 |
|-------|------|------|----------|
| **FR-1** | PDF 업로드 | 사회복지사 1급 기출문제 PDF 업로드 | P0 |
| **FR-2** | 문서 파싱 | Upstage API 기반 문제/보기/해설/지문 분리 | P0 |
| **FR-3** | 지능형 청킹 | 지문 복제 전략, Question/Options/Answer/Explanation 스키마 | P0 |
| **FR-4** | Knowledge Graph 구축 | Neo4j, LLM 자동 태깅, Concept Node 연결 | P0 |
| **FR-5** | CBT 모의고사 | 보기 랜덤 셔플링, 타이머, 채점 | P0 |
| **FR-6** | 오답 분석 | GraphRAG 기반 취약 개념 도출 | P0 |
| **FR-7** | 기본 대시보드 | 학습 진도, 정답률 통계 | P1 |
| **FR-8** | 사용자 인증 | 이메일/소셜 로그인 (Clerk) | P0 |

---

## Epic Structure Overview

| Epic | 제목 | 사용자 가치 | FR 커버리지 | Stories |
|------|------|------------|-------------|---------|
| **Epic 1** | Project Foundation | 개발 기반 인프라 구축 | - | 3 |
| **Epic 2** | User Authentication | 안전한 로그인/회원가입 | FR-8 | 4 |
| **Epic 3** | PDF Processing Pipeline | PDF → 학습 세트 자동 생성 | FR-1, FR-2, FR-3 | 5 |
| **Epic 4** | Knowledge Graph | 개념 관계 그래프 구축 | FR-4 | 4 |
| **Epic 5** | CBT Test Engine | 실전 모의고사 응시 | FR-5 | 4 |
| **Epic 6** | Analytics & Dashboard | 취약점 분석 및 학습 현황 | FR-6, FR-7 | 4 |

---

## FR Coverage Matrix

| FR ID | Epic 1 | Epic 2 | Epic 3 | Epic 4 | Epic 5 | Epic 6 |
|-------|--------|--------|--------|--------|--------|--------|
| FR-1 (PDF 업로드) | | | ✅ | | | |
| FR-2 (문서 파싱) | | | ✅ | | | |
| FR-3 (지능형 청킹) | | | ✅ | | | |
| FR-4 (Knowledge Graph) | | | | ✅ | | |
| FR-5 (CBT 모의고사) | | | | | ✅ | |
| FR-6 (오답 분석) | | | | | | ✅ |
| FR-7 (대시보드) | | | | | | ✅ |
| FR-8 (사용자 인증) | | ✅ | | | | |

---

# Epic 1: Project Foundation

**Goal:** 프론트엔드와 백엔드 프로젝트를 초기화하고 개발 환경을 구성한다.

**User Value:** 개발자가 안정적인 환경에서 기능 개발을 시작할 수 있다.

**Prerequisites:** 없음

---

## Story 1.1: Frontend Project Initialization

**As a** developer
**I want** Next.js 프로젝트가 초기화되어 있길
**So that** 프론트엔드 기능 개발을 시작할 수 있다.

### Acceptance Criteria

```gherkin
Given 개발 환경이 준비되어 있을 때
When 프론트엔드 프로젝트를 초기화하면
Then 다음 구조가 생성된다:
  - frontend/src/app/ (App Router)
  - frontend/src/components/ui/ (shadcn/ui)
  - frontend/src/lib/ (utilities)
  - frontend/src/stores/ (Zustand)
  - frontend/src/types/ (TypeScript types)

And 다음 패키지가 설치된다:
  - Next.js 15.x
  - React 19.x
  - TypeScript 5.x
  - Tailwind CSS 3.x
  - Zustand
  - TanStack Query
  - shadcn/ui (button, card, input, dialog 등)

And npm run dev 실행 시 localhost:3000에서 정상 동작한다
```

### Technical Notes
- `npx create-next-app@latest frontend --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"`
- `npx shadcn@latest init` 후 필수 컴포넌트 설치
- `.env.example` 파일 생성

### Estimated Points: 3

---

## Story 1.2: Backend Project Initialization

**As a** developer
**I want** FastAPI 프로젝트가 초기화되어 있길
**So that** 백엔드 API 개발을 시작할 수 있다.

### Acceptance Criteria

```gherkin
Given 개발 환경이 준비되어 있을 때
When 백엔드 프로젝트를 초기화하면
Then 다음 구조가 생성된다:
  - backend/app/api/v1/endpoints/
  - backend/app/core/ (config, security)
  - backend/app/models/ (Pydantic schemas)
  - backend/app/services/
  - backend/app/repositories/
  - backend/tests/

And 다음 패키지가 설치된다:
  - FastAPI
  - uvicorn[standard]
  - pydantic-settings
  - python-jose[cryptography]
  - httpx
  - pytest, pytest-asyncio

And uvicorn 실행 시 localhost:8000/docs에서 Swagger UI가 표시된다
And /health 엔드포인트가 {"status": "healthy"} 반환
```

### Technical Notes
- Python 3.10+ 가상환경 사용
- `requirements.txt` 및 `requirements-dev.txt` 분리
- `.env.example` 파일 생성

### Estimated Points: 3

---

## Story 1.3: Database & External Services Setup

**As a** developer
**I want** 외부 서비스(Supabase, Pinecone, Neo4j) 연결이 설정되어 있길
**So that** 데이터 저장 기능을 구현할 수 있다.

### Acceptance Criteria

```gherkin
Given 외부 서비스 계정이 생성되어 있을 때
When 데이터베이스 설정을 완료하면
Then Supabase에 다음 테이블이 생성된다:
  - users (id, clerk_user_id, email, created_at, updated_at)
  - study_sets (id, user_id, name, pdf_url, status, question_count, created_at)
  - test_sessions (id, user_id, study_set_id, score, total_questions, started_at, completed_at)
  - user_answers (id, session_id, question_id, selected_option, is_correct, answered_at)

And Pinecone 인덱스가 생성된다:
  - 인덱스명: certigraph-questions
  - Dimension: 1536 (text-embedding-3-small)
  - Metric: cosine

And Neo4j AuraDB 인스턴스가 생성된다:
  - 연결 테스트 성공

And 백엔드에서 각 서비스 연결 테스트가 통과한다
```

### Technical Notes
- Supabase: RLS(Row Level Security) 정책 설정
- Pinecone: Serverless 플랜 사용
- Neo4j: Free Tier AuraDB
- 환경변수: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `PINECONE_API_KEY`, `NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASSWORD`

### Estimated Points: 5

---

# Epic 2: User Authentication

**Goal:** 사용자가 Clerk를 통해 안전하게 회원가입/로그인할 수 있다.

**User Value:** 사용자는 이메일 또는 Google 계정으로 빠르게 가입하고 개인화된 학습을 시작할 수 있다.

**FR Coverage:** FR-8 (사용자 인증)

**Prerequisites:** Epic 1 완료

---

## Story 2.1: Clerk Project Setup

**As a** developer
**I want** Clerk 프로젝트가 설정되어 있길
**So that** 인증 기능을 구현할 수 있다.

### Acceptance Criteria

```gherkin
Given Clerk 대시보드에 접근할 수 있을 때
When Clerk 프로젝트를 설정하면
Then 다음이 구성된다:
  - 이메일/비밀번호 인증 활성화
  - Google OAuth 프로바이더 구성
  - Redirect URLs 설정 (localhost:3000, production URL)
  - 한국어 로케일 설정

And 환경변수가 설정된다:
  - NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
  - CLERK_SECRET_KEY
  - NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
  - NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
```

### Technical Notes
- Clerk Dashboard에서 OAuth 설정
- Kakao OAuth는 Phase 2로 연기 (Google만 MVP)

### Estimated Points: 2

---

## Story 2.2: Frontend Auth Pages

**As a** user
**I want** 로그인/회원가입 페이지가 있길
**So that** 계정을 만들고 로그인할 수 있다.

### Acceptance Criteria

```gherkin
Given 로그인되지 않은 상태에서
When /sign-in 페이지에 접근하면
Then Clerk SignIn 컴포넌트가 표시된다:
  - 이메일/비밀번호 입력 필드
  - "Continue with Google" 버튼
  - "회원가입" 링크

Given 로그인되지 않은 상태에서
When /sign-up 페이지에 접근하면
Then Clerk SignUp 컴포넌트가 표시된다:
  - 이메일/비밀번호 입력 필드
  - "Continue with Google" 버튼
  - "로그인" 링크

Given 인증되지 않은 상태에서
When /dashboard/* 경로에 접근하면
Then /sign-in으로 리다이렉트된다
```

### Technical Notes
- `app/sign-in/[[...sign-in]]/page.tsx`
- `app/sign-up/[[...sign-up]]/page.tsx`
- `middleware.ts`에서 Clerk 미들웨어 설정
- `ClerkProvider`로 root layout 래핑

### Estimated Points: 3

---

## Story 2.3: Backend JWT Verification

**As a** backend service
**I want** Clerk JWT를 검증할 수 있길
**So that** 인증된 사용자만 API에 접근하도록 할 수 있다.

### Acceptance Criteria

```gherkin
Given Authorization 헤더가 없는 요청이 들어올 때
When 보호된 엔드포인트에 접근하면
Then HTTP 401 반환:
  {
    "error": {
      "code": "AUTH_MISSING_TOKEN",
      "message": "인증 토큰이 필요합니다."
    }
  }

Given 유효하지 않은 JWT가 포함된 요청이 들어올 때
When 보호된 엔드포인트에 접근하면
Then HTTP 401 반환:
  {
    "error": {
      "code": "AUTH_INVALID_TOKEN",
      "message": "유효하지 않은 인증 토큰입니다."
    }
  }

Given 유효한 Clerk JWT가 포함된 요청이 들어올 때
When 보호된 엔드포인트에 접근하면
Then 요청이 정상 처리되고 current_user가 주입된다
```

### Technical Notes
- `python-jose`로 JWT 검증
- Clerk JWKS URL에서 공개키 가져오기
- `app/api/v1/deps.py`에 `get_current_user` 의존성 구현
- JWKS 캐싱 (1시간 TTL)

### Estimated Points: 5

---

## Story 2.4: User Sync & Dashboard Layout

**As a** user
**I want** 로그인 후 대시보드를 볼 수 있길
**So that** 서비스를 사용할 수 있다.

### Acceptance Criteria

```gherkin
Given 처음 로그인하는 사용자일 때
When 로그인에 성공하면
Then Supabase users 테이블에 레코드가 생성된다:
  - clerk_user_id: Clerk에서 받은 user_id
  - email: 사용자 이메일

Given 로그인된 상태에서
When /dashboard에 접근하면
Then 다음 레이아웃이 표시된다:
  - Header: 로고, UserButton (프로필/로그아웃)
  - Sidebar: 대시보드, 학습 세트, 모의고사, 취약점 분석
  - Main content area

Given UserButton에서 로그아웃을 클릭하면
When 로그아웃이 완료되면
Then 세션이 종료되고 / 페이지로 리다이렉트된다
```

### Technical Notes
- 첫 API 호출 시 사용자 동기화 (Webhook 대신 간단한 방식)
- `app/(dashboard)/layout.tsx` 구현
- `components/layout/Header.tsx`, `Sidebar.tsx`
- Clerk `<UserButton />` 사용

### Estimated Points: 5

---

# Epic 3: PDF Processing Pipeline

**Goal:** 사용자가 PDF를 업로드하면 자동으로 문제를 추출하여 학습 세트를 생성한다.

**User Value:** PDF만 올리면 AI가 자동으로 문제/보기/해설을 분리하여 즉시 학습을 시작할 수 있다.

**FR Coverage:** FR-1 (PDF 업로드), FR-2 (문서 파싱), FR-3 (지능형 청킹)

**Prerequisites:** Epic 2 완료

---

## Story 3.1: PDF Upload UI

**As a** user
**I want** PDF 파일을 업로드할 수 있길
**So that** 내 기출문제로 학습 세트를 만들 수 있다.

### Acceptance Criteria

```gherkin
Given /dashboard/study-sets/new 페이지에 접근했을 때
When 페이지가 로드되면
Then 다음이 표시된다:
  - 드래그 앤 드롭 영역: "PDF 파일을 드래그하거나 클릭하세요"
  - 파일 제한: PDF만, 최대 50MB
  - "학습 세트 이름" 입력 필드

Given 유효한 PDF 파일을 드래그했을 때
When 파일을 드롭하면
Then 파일명과 크기가 표시된다
And "업로드 시작" 버튼이 활성화된다

Given 유효하지 않은 파일(비PDF 또는 >50MB)을 드래그했을 때
When 파일을 드롭하면
Then 에러 메시지가 표시된다:
  - "PDF 파일만 업로드 가능합니다"
  - "파일 크기는 50MB 이하여야 합니다"

Given 유효한 PDF가 선택된 상태에서
When "업로드 시작" 버튼을 클릭하면
Then 업로드 진행률이 표시된다
And 완료 시 학습 세트 상세 페이지로 이동한다
```

### Technical Notes
- `components/study-set/PdfUploader.tsx`
- react-dropzone 또는 native drag & drop
- TanStack Query mutation 사용

### Estimated Points: 5

---

## Story 3.2: Backend Upload Endpoint & Storage

**As a** backend service
**I want** PDF 파일을 받아 저장할 수 있길
**So that** 파싱 파이프라인을 시작할 수 있다.

### Acceptance Criteria

```gherkin
Given 인증된 사용자가 PDF를 업로드할 때
When POST /api/v1/study-sets/upload 호출하면
Then 다음이 수행된다:
  1. 파일 검증 (PDF, ≤50MB)
  2. Supabase Storage에 업로드 (pdfs/{user_id}/{uuid}.pdf)
  3. study_sets 레코드 생성 (status='uploading')
  4. 백그라운드 파싱 작업 시작
  5. 응답 반환:
     {
       "data": {
         "id": "uuid",
         "name": "학습 세트명",
         "status": "parsing",
         "created_at": "ISO8601"
       }
     }

Given 잘못된 파일 형식일 때
When 업로드를 시도하면
Then HTTP 400 반환:
  {
    "error": {
      "code": "VALIDATION_FORMAT",
      "message": "PDF 파일만 업로드 가능합니다."
    }
  }
```

### Technical Notes
- `app/api/v1/endpoints/study_sets.py`
- FastAPI `BackgroundTasks` 사용
- Rate limiting: 시간당 5개 업로드

### Estimated Points: 5

---

## Story 3.3: Upstage Document Parse Integration

**As a** backend service
**I want** Upstage API로 PDF를 파싱할 수 있길
**So that** 문서 구조를 추출할 수 있다.

### Acceptance Criteria

```gherkin
Given PDF URL이 주어졌을 때
When Upstage Document Parse API를 호출하면
Then 다음이 반환된다:
  - 문서 구조 (heading, paragraph, table)
  - 텍스트 내용
  - 이미지 위치 정보

Given API 호출이 실패했을 때
When 에러가 발생하면
Then 3회까지 재시도 (exponential backoff)
And 최종 실패 시 study_set.status = 'parse_failed'

Given 파싱 진행 중일 때
When GET /api/v1/study-sets/{id}/status 호출하면
Then 진행 상태가 반환된다:
  {
    "data": {
      "status": "parsing",
      "progress": 45,
      "current_step": "문서 구조 분석 중..."
    }
  }
```

### Technical Notes
- `app/services/parser/upstage.py`
- httpx async client 사용
- 환경변수: `UPSTAGE_API_KEY`

### Estimated Points: 5

---

## Story 3.4: Question Extraction & Intelligent Chunking

**As a** backend service
**I want** 파싱된 문서에서 문제를 추출할 수 있길
**So that** 개별 문제 단위로 저장할 수 있다.

### Acceptance Criteria

```gherkin
Given Upstage 파싱 결과가 있을 때
When 문제 추출을 실행하면
Then 다음 패턴으로 문제가 식별된다:
  - 문제 번호: "1.", "문제 1", "Q1" 등
  - 보기: "①②③④⑤", "1)2)3)4)5)" 등
  - 정답: "정답:", "[정답]" 등
  - 해설: "해설:", "[해설]" 등

Given 지문형 문제("다음 글을 읽고...")가 있을 때
When 청킹을 실행하면
Then 지문이 각 하위 문제에 복제된다:
  {
    "question_id": "q_001",
    "passage": "다음 사례를 읽고 물음에 답하시오...",
    "question_text": "위 사례에서...",
    "options": ["①...", "②...", "③...", "④...", "⑤..."],
    "answer": 3,
    "explanation": "해설..."
  }

And 추출된 문제 수가 study_sets.question_count에 저장된다
```

### Technical Notes
- `app/services/parser/extractor.py`
- `app/services/chunker/intelligent.py`
- 정규식 패턴으로 한국어 시험 형식 처리
- 누락된 해설은 null 허용

### Estimated Points: 8

---

## Story 3.5: Study Set Detail Page

**As a** user
**I want** 학습 세트 상세 정보를 볼 수 있길
**So that** 파싱 상태를 확인하고 학습을 시작할 수 있다.

### Acceptance Criteria

```gherkin
Given 파싱 중인 학습 세트일 때
When /dashboard/study-sets/{id}에 접근하면
Then 다음이 표시된다:
  - 학습 세트 이름
  - 업로드 날짜
  - 진행률 바
  - 현재 단계: "문서 분석 중...", "문제 추출 중..." 등

Given 파싱 완료(status='ready')된 학습 세트일 때
When 페이지를 보면
Then 다음이 표시된다:
  - 총 문제 수
  - "모의고사 시작" 버튼
  - "문제 목록 보기" 버튼
  - "삭제" 버튼

Given 파싱 실패(status='parse_failed')된 학습 세트일 때
When 페이지를 보면
Then 다음이 표시된다:
  - 에러 메시지
  - "다시 시도" 버튼
```

### Technical Notes
- `app/(dashboard)/study-sets/[id]/page.tsx`
- React Query polling (3초 간격, 파싱 중일 때만)
- `components/study-set/ParsingProgress.tsx`

### Estimated Points: 5

---

# Epic 4: Knowledge Graph & Embeddings

**Goal:** 추출된 문제를 벡터화하고 개념 그래프를 구축한다.

**User Value:** AI가 문제 간의 개념 관계를 파악하여 취약점 분석의 기반을 만든다.

**FR Coverage:** FR-4 (Knowledge Graph 구축)

**Prerequisites:** Epic 3 완료

---

## Story 4.1: Vector Embedding & Pinecone Storage

**As a** backend service
**I want** 문제를 벡터화하여 Pinecone에 저장할 수 있길
**So that** 유사 문제 검색이 가능하다.

### Acceptance Criteria

```gherkin
Given 추출된 문제들이 있을 때
When 임베딩 서비스를 실행하면
Then 각 문제에 대해:
  1. question_text + options 결합
  2. OpenAI text-embedding-3-small로 1536차원 벡터 생성
  3. Pinecone에 upsert:
     {
       "id": "q_001",
       "values": [0.123, -0.456, ...],
       "metadata": {
         "study_set_id": "uuid",
         "user_id": "uuid",
         "question_text": "...",
         "options": [...],
         "answer": 3
       }
     }

And 배치 처리로 100개씩 업로드
And namespace는 user_id로 분리
```

### Technical Notes
- `app/services/embedding/openai.py`
- `app/repositories/pinecone/questions.py`
- 환경변수: `OPENAI_API_KEY`, `PINECONE_API_KEY`

### Estimated Points: 5

---

## Story 4.2: LLM Concept Extraction

**As a** backend service
**I want** LLM으로 문제의 개념을 추출할 수 있길
**So that** Knowledge Graph 노드를 생성할 수 있다.

### Acceptance Criteria

```gherkin
Given 문제 텍스트가 있을 때
When LLM 개념 추출을 실행하면
Then GPT-4o-mini가 다음 형식으로 응답:
  {
    "primary_concept": "사회복지실천기술",
    "secondary_concepts": ["면접기법", "라포형성"],
    "prerequisite_concepts": ["인간행동이론"],
    "subject": "사회복지 실천",
    "chapter": "사회복지실천기술론"
  }

And 응답이 캐시된다 (동일 문제 재처리 방지)
And API 호출 실패 시 3회 재시도
```

### Technical Notes
- `app/services/graph/extractor.py`
- LangChain ChatOpenAI 사용
- 구조화된 출력 (Pydantic 모델)

### Estimated Points: 5

---

## Story 4.3: Neo4j Graph Construction

**As a** backend service
**I want** 개념과 관계를 Neo4j에 저장할 수 있길
**So that** GraphRAG 분석이 가능하다.

### Acceptance Criteria

```gherkin
Given LLM이 추출한 개념들이 있을 때
When Neo4j에 저장하면
Then 다음 노드가 생성된다:
  - (:Concept {name, description, subject, chapter})
  - (:Question {id, text, study_set_id})

And 다음 관계가 생성된다:
  - (:Question)-[:TESTS]->(:Concept)
  - (:Concept)-[:PREREQUISITE]->(:Concept)

And 중복 노드는 MERGE로 처리 (생성 안 함)
And study_set 파싱 완료 시 status='ready'로 업데이트
```

### Technical Notes
- `app/repositories/neo4j/concepts.py`
- `app/repositories/neo4j/relationships.py`
- Cypher MERGE 쿼리 사용

### Estimated Points: 5

---

## Story 4.4: Study Set List Page

**As a** user
**I want** 내 학습 세트 목록을 볼 수 있길
**So that** 원하는 학습 세트를 선택할 수 있다.

### Acceptance Criteria

```gherkin
Given 로그인된 상태에서
When /dashboard/study-sets에 접근하면
Then 내 학습 세트 목록이 표시된다:
  - 학습 세트 이름
  - 상태 (파싱 중/준비됨/실패)
  - 문제 수
  - 생성 날짜
  - 최근 응시 결과 (있으면)

And "새 학습 세트 만들기" 버튼이 있다
And 학습 세트가 없으면 빈 상태 안내가 표시된다
```

### Technical Notes
- `app/(dashboard)/study-sets/page.tsx`
- `components/study-set/StudySetList.tsx`
- `components/study-set/StudySetCard.tsx`

### Estimated Points: 3

---

# Epic 5: CBT Test Engine

**Goal:** 사용자가 실제 시험과 유사한 환경에서 모의고사를 응시할 수 있다.

**User Value:** 보기 순서가 매번 바뀌어 정답 위치 암기 없이 진정한 실력을 테스트할 수 있다.

**FR Coverage:** FR-5 (CBT 모의고사)

**Prerequisites:** Epic 4 완료

---

## Story 5.1: Test Session Initialization

**As a** user
**I want** 모의고사를 시작할 수 있길
**So that** 내 실력을 테스트할 수 있다.

### Acceptance Criteria

```gherkin
Given status='ready'인 학습 세트 상세 페이지에서
When "모의고사 시작" 버튼을 클릭하면
Then 모달이 표시된다:
  - "전체 문제" 옵션
  - "랜덤 20문제" 옵션
  - "랜덤 50문제" 옵션
  - "틀린 문제만" 옵션 (이전 응시 기록이 있을 때)

When 옵션을 선택하고 "시작"을 클릭하면
Then POST /api/v1/tests/start 호출:
  {
    "study_set_id": "uuid",
    "mode": "random",
    "question_count": 20
  }

And 응답으로 세션 정보와 문제 목록 수신
And /dashboard/test/{session_id}로 이동
```

### Technical Notes
- `app/api/v1/endpoints/tests.py`
- `app/services/test_engine/session.py`
- Pinecone에서 문제 조회

### Estimated Points: 5

---

## Story 5.2: CBT Test Interface

**As a** user
**I want** 집중할 수 있는 테스트 화면을 보고 싶다
**So that** 실제 시험처럼 문제를 풀 수 있다.

### Acceptance Criteria

```gherkin
Given /dashboard/test/{sessionId} 페이지에서
When 테스트 화면이 로드되면
Then 다음이 표시된다:
  - 문제 번호와 총 문제 수 (1 / 20)
  - 진행률 바
  - 타이머 (선택적)
  - 문제 텍스트 (지문 포함 시 지문도)
  - 5개 보기 버튼 (랜덤 순서)
  - 네비게이션: "이전", "다음"
  - 문제 번호 그리드 (답변 완료=파란색, 현재=노란색)

Given 보기가 표시될 때
When 매 세션마다
Then 보기 순서가 랜덤하게 셔플된다
And 셔플 매핑이 클라이언트에 저장된다

Given 보기를 클릭했을 때
When 선택하면
Then 해당 보기가 하이라이트된다
And 언제든 선택을 변경할 수 있다
```

### Technical Notes
- `app/(dashboard)/test/[sessionId]/page.tsx`
- `components/test/QuestionCard.tsx`
- `components/test/OptionButton.tsx`
- Fisher-Yates 셔플 알고리즘
- Zustand로 테스트 상태 관리

### Estimated Points: 8

---

## Story 5.3: Answer Submission & Scoring

**As a** user
**I want** 답안을 제출하고 점수를 확인하고 싶다
**So that** 내 실력을 알 수 있다.

### Acceptance Criteria

```gherkin
Given 문제를 풀고 있는 중에
When "제출하기" 버튼을 클릭하면
Then 확인 모달이 표시된다:
  "제출하시겠습니까? 제출 후에는 수정할 수 없습니다."
  - 답변한 문제 수 / 전체 문제 수 표시

When 제출을 확인하면
Then POST /api/v1/tests/submit 호출:
  {
    "session_id": "uuid",
    "answers": [
      {"question_id": "q_001", "selected_option": 3},
      ...
    ]
  }

And 백엔드에서 채점:
  - 셔플된 인덱스 → 원본 정답과 비교
  - 정답 수 계산
  - user_answers 테이블에 저장
  - test_sessions 업데이트 (score, completed_at)

And 응답:
  {
    "data": {
      "score": 16,
      "total": 20,
      "percentage": 80,
      "time_taken_seconds": 1234
    }
  }

And /dashboard/test/result/{sessionId}로 이동
```

### Technical Notes
- `app/services/test_engine/scoring.py`
- 셔플 매핑 처리 로직

### Estimated Points: 5

---

## Story 5.4: Test Result & Review Page

**As a** user
**I want** 시험 결과를 상세히 확인하고 싶다
**So that** 틀린 문제를 복습할 수 있다.

### Acceptance Criteria

```gherkin
Given /dashboard/test/result/{sessionId} 페이지에서
When 결과 페이지가 로드되면
Then 다음이 표시된다:
  - 점수: "16 / 20 (80%)"
  - 등급 뱃지: "우수"(≥80%), "양호"(60-79%), "노력필요"(<60%)
  - 소요 시간
  - "다시 풀기" 버튼
  - "오답만 다시 풀기" 버튼

And 문제별 리뷰 섹션:
  - 문제 텍스트
  - 5개 보기:
    - ✅ 정답: 초록색 배경
    - ❌ 내 오답: 빨간색 배경
    - 내 선택 표시
  - 해설 텍스트

Given "오답만 다시 풀기" 버튼을 클릭하면
When 새 세션이 시작되면
Then 틀린 문제만으로 테스트가 구성된다
```

### Technical Notes
- `app/(dashboard)/test/result/[sessionId]/page.tsx`
- `components/test/ResultSummary.tsx`
- `components/test/QuestionReview.tsx`

### Estimated Points: 5

---

# Epic 6: Analytics & Dashboard

**Goal:** 사용자가 취약점을 분석하고 학습 진도를 한눈에 파악할 수 있다.

**User Value:** 단순 오답 체크를 넘어 "어떤 개념이 부족한지" 구조적으로 파악하고 효율적으로 학습할 수 있다.

**FR Coverage:** FR-6 (오답 분석), FR-7 (대시보드)

**Prerequisites:** Epic 5 완료

---

## Story 6.1: Weak Concept Analysis API

**As a** backend service
**I want** 사용자의 취약 개념을 분석할 수 있길
**So that** 개인화된 학습 추천이 가능하다.

### Acceptance Criteria

```gherkin
Given 사용자가 최소 1회 테스트를 완료했을 때
When GET /api/v1/analysis/weak-concepts 호출하면
Then 다음 분석이 수행된다:
  1. user_answers에서 오답 조회
  2. 각 오답 문제의 연결된 개념 조회 (Neo4j)
  3. 취약점 점수 계산: wrong_count / total_attempts
  4. GraphRAG로 선수 개념 탐색
  5. LLM으로 인사이트 생성

And 응답:
  {
    "data": {
      "weak_concepts": [
        {
          "concept": "사회복지실천기술",
          "weakness_score": 0.6,
          "wrong_count": 3,
          "total_count": 5,
          "related_concepts": ["면접기법", "라포형성"]
        }
      ],
      "insight": "면접기법의 기초 개념을 복습하시면...",
      "recommended_study": ["면접기법 기초", "라포형성 원칙"]
    }
  }
```

### Technical Notes
- `app/api/v1/endpoints/analysis.py`
- `app/services/analysis/graphrag.py`
- LLM 인사이트 캐싱 (1시간 TTL)

### Estimated Points: 8

---

## Story 6.2: Weak Concept Analysis UI

**As a** user
**I want** 취약 개념을 시각적으로 확인하고 싶다
**So that** 집중해야 할 부분을 알 수 있다.

### Acceptance Criteria

```gherkin
Given /dashboard/analysis 페이지에서
When 테스트 기록이 없으면
Then 안내 메시지: "먼저 모의고사를 응시해주세요."

Given 테스트 기록이 있을 때
When 페이지가 로드되면
Then 다음이 표시된다:
  - "취약 개념 분석" 제목
  - 취약 개념 카드 목록 (취약도 높은 순):
    - 개념 이름
    - 취약도 바 (빨간색 그라데이션)
    - "X문제 중 Y문제 오답"
    - 연관 개념 태그
  - AI 인사이트 박스
  - "이 개념 집중 학습" 버튼

Given "이 개념 집중 학습" 버튼을 클릭하면
When 클릭하면
Then 해당 개념 관련 문제만으로 테스트 세션이 시작된다
```

### Technical Notes
- `app/(dashboard)/analysis/page.tsx`
- `components/analysis/WeakConceptList.tsx`
- `components/analysis/ConceptCard.tsx`
- `components/analysis/StudyRecommendation.tsx`

### Estimated Points: 5

---

## Story 6.3: Learning Dashboard

**As a** user
**I want** 전체 학습 현황을 한눈에 보고 싶다
**So that** 내 진도를 파악할 수 있다.

### Acceptance Criteria

```gherkin
Given /dashboard (홈) 페이지에서
When 페이지가 로드되면
Then 다음이 표시된다:
  - 환영 메시지: "{이름}님, 오늘도 화이팅!"
  - 통계 카드:
    - 총 학습 문제 수
    - 평균 정답률
    - 학습 세트 수
    - 모의고사 응시 횟수
  - 최근 활동 (최근 5개 테스트 결과)
  - "오늘의 추천 학습" (취약 개념 기반)
  - "새 학습 세트 만들기" 버튼

Given 학습 데이터가 없을 때
When 페이지가 로드되면
Then 온보딩 안내: "첫 번째 PDF를 업로드해서 학습을 시작해보세요!"
```

### Technical Notes
- `app/(dashboard)/page.tsx`
- `components/dashboard/StatsCard.tsx`
- `components/dashboard/RecentActivity.tsx`
- 여러 테이블에서 데이터 집계

### Estimated Points: 5

---

## Story 6.4: User Progress Tracking

**As a** backend service
**I want** 사용자의 개념별 숙련도를 추적할 수 있길
**So that** 시간에 따른 성장을 보여줄 수 있다.

### Acceptance Criteria

```gherkin
Given 사용자가 테스트를 완료했을 때
When 채점이 완료되면
Then Neo4j에 다음 관계가 업데이트된다:
  - 정답: (:User)-[:MASTERED {count}]->(:Concept) count++
  - 오답: (:User)-[:WEAK_AT {count}]->(:Concept) count++

And 숙련도 계산:
  mastery_ratio = mastered / (mastered + weak)
  - "숙련" (≥0.8)
  - "학습중" (0.4-0.79)
  - "취약" (<0.4)

Given GET /api/v1/analysis/progress 호출하면
When 진도 조회하면
Then 응답:
  {
    "data": {
      "total_concepts": 45,
      "mastered": 20,
      "learning": 15,
      "weak": 10,
      "concepts": [
        {"name": "사회복지정책", "mastery": 0.85, "level": "숙련"},
        {"name": "면접기법", "mastery": 0.35, "level": "취약"}
      ]
    }
  }
```

### Technical Notes
- `app/repositories/neo4j/relationships.py`
- MERGE + SET으로 카운트 업데이트
- 테스트 완료 시 자동 실행

### Estimated Points: 5

---

# Validation & Summary

## FR Coverage Matrix (Final)

| FR ID | 기능 | Stories | Coverage |
|-------|------|---------|----------|
| **FR-1** | PDF 업로드 | 3.1, 3.2 | ✅ 100% |
| **FR-2** | 문서 파싱 | 3.3, 3.4 | ✅ 100% |
| **FR-3** | 지능형 청킹 | 3.4 | ✅ 100% |
| **FR-4** | Knowledge Graph | 4.1, 4.2, 4.3 | ✅ 100% |
| **FR-5** | CBT 모의고사 | 5.1, 5.2, 5.3, 5.4 | ✅ 100% |
| **FR-6** | 오답 분석 | 6.1, 6.2 | ✅ 100% |
| **FR-7** | 대시보드 | 6.3, 6.4 | ✅ 100% |
| **FR-8** | 사용자 인증 | 2.1, 2.2, 2.3, 2.4 | ✅ 100% |

## Story Points Summary

| Epic | Stories | Total Points |
|------|---------|--------------|
| Epic 1: Project Foundation | 3 | 11 |
| Epic 2: User Authentication | 4 | 15 |
| Epic 3: PDF Processing Pipeline | 5 | 28 |
| Epic 4: Knowledge Graph | 4 | 18 |
| Epic 5: CBT Test Engine | 4 | 23 |
| Epic 6: Analytics & Dashboard | 4 | 23 |
| **Total** | **24** | **118** |

## Implementation Order

```
Epic 1 (Foundation)
    ↓
Epic 2 (Authentication)
    ↓
Epic 3 (PDF Processing) ──→ Epic 4 (Knowledge Graph)
                                    ↓
                            Epic 5 (Test Engine)
                                    ↓
                            Epic 6 (Analytics)
```

## Architecture Alignment

- ✅ All API endpoints follow Architecture patterns
- ✅ Database schemas match Architecture specification
- ✅ Authentication flow uses Clerk as designed
- ✅ Error responses follow defined format
- ✅ Naming conventions applied consistently

---

**Document Status:** ✅ READY FOR IMPLEMENTATION

**Next Steps:**
1. Epic 1 Story 1.1부터 순차적으로 구현
2. 각 Story 완료 후 코드 리뷰
3. Epic 완료 후 통합 테스트

---

_For implementation: Use `/bmad:bmm:workflows:dev-story` to execute individual stories from this breakdown._
