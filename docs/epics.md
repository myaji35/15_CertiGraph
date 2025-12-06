# Certi-Graph - Epic Breakdown

**Author:** Q123
**Date:** 2025-12-06
**Project Level:** MVP
**Target Scale:** 사회복지사 1급 시험 대비 (연간 ~25,000명 응시자)

---

## Overview

This document provides the complete epic and story breakdown for Certi-Graph, decomposing the requirements from the [PRD](../prd.md) and [Architecture](./architecture.md) into implementable stories.

**Living Document Notice:** This is the initial version created with full PRD + Architecture context.

**Total Epics:** 4
**Total Stories:** TBD
**FR Coverage:** 8 Functional Requirements

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

## FR Coverage Map

| FR ID | Epic 1 | Epic 2 | Epic 3 | Epic 4 |
|-------|--------|--------|--------|--------|
| FR-1 (PDF 업로드) | | ✅ | | |
| FR-2 (문서 파싱) | | ✅ | | |
| FR-3 (지능형 청킹) | | ✅ | | |
| FR-4 (Knowledge Graph) | | ✅ | | ✅ |
| FR-5 (CBT 모의고사) | | | ✅ | |
| FR-6 (오답 분석) | | | | ✅ |
| FR-7 (대시보드) | | | | ✅ |
| FR-8 (사용자 인증) | ✅ | | | |

---

## Epic Structure Overview

| Epic | 제목 | 사용자 가치 | FR 커버리지 |
|------|------|------------|-------------|
| **Epic 1** | Foundation & Authentication | 사용자가 계정을 만들고 로그인할 수 있다 | FR-8 |
| **Epic 2** | PDF Upload & Parsing Pipeline | 사용자가 PDF를 업로드하고 학습 세트를 생성할 수 있다 | FR-1, FR-2, FR-3, FR-4 |
| **Epic 3** | CBT Test Engine | 사용자가 모의고사를 응시하고 채점받을 수 있다 | FR-5 |
| **Epic 4** | Analysis & Dashboard | 사용자가 취약점 분석과 학습 진도를 확인할 수 있다 | FR-4, FR-6, FR-7 |

---

## Epic 1: Foundation & Authentication

**Goal:** 프로젝트 기반 인프라를 구축하고 사용자가 계정을 생성하여 로그인할 수 있도록 한다.

**User Value:** 사용자는 이메일 또는 소셜 계정으로 안전하게 로그인하여 개인화된 학습 경험을 시작할 수 있다.

**FR Coverage:** FR-8 (사용자 인증)

**Architecture References:**
- Clerk (이메일 + Google/Kakao 소셜 로그인)
- Clerk JWT 기반 인증 흐름
- Next.js Clerk 미들웨어 + FastAPI JWT 검증

---

### Story 1.1: Project Initialization & Monorepo Setup

**As a** developer,
**I want** the monorepo structure with frontend and backend projects initialized,
**So that** I can start building features on a solid foundation.

**Acceptance Criteria:**

**Given** a fresh development environment
**When** the project is initialized
**Then** the following structure exists:
```
certigraph/
├── frontend/          # Next.js 15.5
├── backend/           # FastAPI
├── shared/            # 공통 타입
└── docker-compose.yml
```

**And** frontend is initialized with:
- Next.js 15.5 (App Router, TypeScript, Tailwind CSS, ESLint)
- shadcn/ui configured
- Zustand and TanStack Query installed

**And** backend is initialized with:
- FastAPI project structure (api/, core/, models/, services/, repositories/)
- Python virtual environment with dependencies (fastapi, uvicorn, pydantic-settings)
- `.env.example` with all required environment variables

**Prerequisites:** None

**Technical Notes:**
- Use `npx create-next-app@latest frontend --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"`
- Backend follows Architecture section "Backend 디렉토리 구조"
- Configure CORS for localhost:3000

---

### Story 1.2: Clerk & Supabase Database Setup

**As a** developer,
**I want** Clerk configured for authentication and Supabase configured with the required database schema,
**So that** users can authenticate and their data can be persisted.

**Acceptance Criteria:**

**Given** Clerk project is created
**When** Clerk dashboard is configured
**Then**:
- Email/password authentication is enabled
- Google OAuth provider is configured
- Kakao OAuth provider is configured (optional)
- Redirect URLs are set for localhost and production

**Given** Supabase project is created (DB only, no Auth)
**When** database migrations are applied
**Then** the following tables exist:
- `users` (id UUID PK, clerk_user_id TEXT UNIQUE, email, created_at, updated_at)
- `study_sets` (id UUID PK, user_id FK, name, pdf_url, status, created_at)
- `test_sessions` (id UUID PK, user_id FK, study_set_id FK, score, total_questions, completed_at)
- `user_answers` (id UUID PK, session_id FK, question_id, selected_option, is_correct)

**And** Row Level Security (RLS) is enabled with policies:
- Users can only read/write their own data (based on clerk_user_id)

**And** environment variables are configured:
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- `CLERK_SECRET_KEY`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_KEY` (backend only)

**Prerequisites:** Story 1.1

**Technical Notes:**
- Create Clerk project at clerk.com
- Configure OAuth providers in Clerk Dashboard
- Supabase is used for database only (not Auth)
- Create index on `users.clerk_user_id` for fast lookups

---

### Story 1.3: Frontend Authentication UI (Clerk)

**As a** user,
**I want** to see login and registration pages,
**So that** I can create an account or sign in to access the platform.

**Acceptance Criteria:**

**Given** I am on the landing page (/)
**When** I click "로그인" or "회원가입"
**Then** I am navigated to /sign-in or /sign-up respectively

**Given** I am on /sign-up
**When** the page loads
**Then** I see Clerk's `<SignUp />` component with:
- Email input field
- Password input field
- "Continue with Google" button
- "Continue with Kakao" button (if configured)
- All UI in Korean (Clerk localization)

**Given** I am on /sign-in
**When** the page loads
**Then** I see Clerk's `<SignIn />` component with:
- Email input field
- Password input field
- "Continue with Google" button
- "Continue with Kakao" button (if configured)
- "Forgot password?" link

**And** Clerk handles all form validation automatically

**Prerequisites:** Story 1.1, Story 1.2

**Technical Notes:**
- Create `/app/sign-in/[[...sign-in]]/page.tsx` with `<SignIn />`
- Create `/app/sign-up/[[...sign-up]]/page.tsx` with `<SignUp />`
- Install `@clerk/nextjs` package
- Wrap root layout with `<ClerkProvider>`
- Configure Clerk appearance for Korean locale
- No custom form components needed - Clerk provides all UI

---

### Story 1.4: Clerk Auth Integration & User Sync

**As a** user,
**I want** to register and login with email or social accounts,
**So that** my learning progress is saved securely.

**Acceptance Criteria:**

**Given** I am on /sign-up
**When** I complete registration through Clerk
**Then** Clerk handles the signup flow automatically
**And** on success, I am redirected to /dashboard
**And** a user record is created in Supabase `users` table with `clerk_user_id`

**Given** I am on /sign-in with valid credentials
**When** I complete login through Clerk
**Then** Clerk handles the authentication automatically
**And** JWT is managed by Clerk
**And** I am redirected to /dashboard

**Given** I click "Continue with Google"
**When** OAuth flow completes successfully
**Then** I am redirected to /dashboard with authenticated session
**And** user record is synced to Supabase if first login

**And** Clerk displays appropriate error messages automatically

**Prerequisites:** Story 1.2, Story 1.3

**Technical Notes:**
- Use Clerk `useUser()` and `useAuth()` hooks
- Implement Clerk webhook for user sync to Supabase (optional, can also sync on first API call)
- Use `middleware.ts` with `clerkMiddleware()` to protect routes
- User sync: on first authenticated API call, check if `clerk_user_id` exists in Supabase, create if not

---

### Story 1.5: Backend Auth Middleware (Clerk JWT)

**As a** backend service,
**I want** to verify Clerk JWT tokens on protected endpoints,
**So that** only authenticated users can access their data.

**Acceptance Criteria:**

**Given** a request to `/api/v1/study-sets/` without Authorization header
**When** the endpoint is called
**Then** HTTP 401 Unauthorized is returned with:
```json
{
  "error": {
    "code": "AUTH_MISSING_TOKEN",
    "message": "인증 토큰이 필요합니다."
  }
}
```

**Given** a request with invalid/expired Clerk JWT
**When** the endpoint is called
**Then** HTTP 401 Unauthorized is returned with:
```json
{
  "error": {
    "code": "AUTH_INVALID_TOKEN",
    "message": "유효하지 않은 인증 토큰입니다."
  }
}
```

**Given** a request with valid Clerk JWT
**When** the endpoint is called
**Then** request proceeds with `current_user` dependency injected
**And** `current_user.clerk_id` matches the JWT's `sub` claim

**Prerequisites:** Story 1.2

**Technical Notes:**
- Implement `get_current_user` dependency in `api/v1/deps.py`
- Use `python-jose` to verify Clerk JWT with JWKS
- Fetch Clerk JWKS from `https://{clerk-domain}/.well-known/jwks.json`
- Cache JWKS for performance (1 hour TTL)
- Extract `sub` claim as `clerk_user_id`
- Follow Architecture error response format

---

### Story 1.6: Protected Dashboard Layout

**As an** authenticated user,
**I want** to see a dashboard with navigation,
**So that** I can access all features of the platform.

**Acceptance Criteria:**

**Given** I am authenticated
**When** I navigate to /dashboard
**Then** I see:
- Header with logo and Clerk `<UserButton />` component (프로필, 로그아웃 자동 포함)
- Sidebar navigation with:
  - "대시보드" (home)
  - "학습 세트"
  - "모의고사"
  - "취약점 분석"
- Main content area

**Given** I am not authenticated
**When** I try to access /dashboard/*
**Then** I am redirected to /sign-in (via Clerk middleware)

**Given** I click the user menu and select "Sign out"
**When** logout completes
**Then** Clerk clears the session
**And** I am redirected to /

**Prerequisites:** Story 1.4

**Technical Notes:**
- Implement `(dashboard)/layout.tsx` with Header and Sidebar
- Use Clerk `clerkMiddleware()` in `middleware.ts` for route protection
- Use Clerk `<UserButton />` in Header for user menu
- Components: `Header.tsx`, `Sidebar.tsx`
- Follow Architecture frontend directory structure

---

## Epic 2: PDF Upload & Parsing Pipeline

**Goal:** 사용자가 PDF를 업로드하고 시스템이 자동으로 문제를 추출하여 학습 세트를 생성한다.

**User Value:** 사용자는 보유한 기출문제 PDF를 업로드하기만 하면, AI가 자동으로 문제/보기/해설을 분리하여 즉시 학습을 시작할 수 있다.

**FR Coverage:** FR-1 (PDF 업로드), FR-2 (문서 파싱), FR-3 (지능형 청킹), FR-4 (Knowledge Graph)

**Architecture References:**
- Upstage Document Parse API
- Pinecone for question embeddings
- Neo4j for Knowledge Graph
- FastAPI async processing

---

### Story 2.1: PDF Upload UI & File Handling

**As a** user,
**I want** to upload a PDF file through the web interface,
**So that** I can start creating a study set from my exam materials.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets/new
**When** I see the upload page
**Then** I see:
- Drag & drop zone with "PDF 파일을 여기에 드래그하거나 클릭하여 선택하세요"
- File type restriction: PDF only
- File size limit: 50MB
- "학습 세트 이름" input field

**Given** I drag a valid PDF file
**When** file is dropped
**Then** file name and size are displayed
**And** upload button becomes active

**Given** I drag an invalid file (non-PDF or >50MB)
**When** file is dropped
**Then** error message is shown: "PDF 파일만 업로드 가능합니다" or "파일 크기는 50MB 이하여야 합니다"

**When** I click "업로드 시작"
**Then** file is uploaded to backend
**And** progress bar shows upload percentage
**And** on completion, I am redirected to study set detail page with "파싱 중..." status

**Prerequisites:** Epic 1 complete

**Technical Notes:**
- Component: `PdfUploader.tsx`
- Use `react-dropzone` or native drag & drop
- Upload to FastAPI endpoint: `POST /api/v1/study-sets/upload`
- Store PDF in Supabase Storage bucket

---

### Story 2.2: Backend PDF Upload Endpoint

**As a** backend service,
**I want** to receive PDF uploads and initiate parsing,
**So that** the document processing pipeline can begin.

**Acceptance Criteria:**

**Given** authenticated user uploads PDF via `POST /api/v1/study-sets/upload`
**When** request is received with multipart form data (file + name)
**Then**:
1. File is validated (PDF, ≤50MB)
2. File is uploaded to Supabase Storage (`pdfs/{user_id}/{uuid}.pdf`)
3. `study_sets` record is created with status='uploading'
4. Background task is queued for parsing
5. Response returns:
```json
{
  "data": {
    "id": "uuid",
    "name": "사회복지사 1급 기출문제",
    "status": "parsing",
    "created_at": "2025-01-15T09:30:00Z"
  }
}
```

**Given** invalid file type
**When** upload is attempted
**Then** HTTP 400 returned:
```json
{
  "error": {
    "code": "VALIDATION_FORMAT",
    "message": "PDF 파일만 업로드 가능합니다."
  }
}
```

**Prerequisites:** Story 1.5

**Technical Notes:**
- Endpoint: `api/v1/endpoints/study_sets.py`
- Use `BackgroundTasks` for async parsing
- Follow Architecture API response format
- Implement rate limiting: 5 uploads per hour per user

---

### Story 2.3: Upstage Document Parse Integration

**As a** backend service,
**I want** to parse PDF using Upstage API,
**So that** document structure is converted to processable format.

**Acceptance Criteria:**

**Given** PDF file URL from Supabase Storage
**When** `services/parser/upstage.py` processes the document
**Then**:
1. Upstage Document Parse API is called
2. Response contains structured elements (headings, paragraphs, tables)
3. Text is extracted with position metadata
4. Images are identified for later captioning
5. Raw parse result is stored for debugging

**And** on Upstage API error:
- Retry up to 3 times with exponential backoff
- On final failure, update study_set status='parse_failed'
- Log error with request_id for debugging

**And** parsing progress is trackable via `GET /api/v1/study-sets/{id}/status`:
```json
{
  "data": {
    "status": "parsing",
    "progress": 45,
    "current_step": "문서 구조 분석 중..."
  }
}
```

**Prerequisites:** Story 2.2

**Technical Notes:**
- Service: `services/parser/upstage.py`
- Use `httpx` for async HTTP calls
- Store Upstage API key in environment variable
- Implement proper error handling per Architecture patterns

---

### Story 2.4: Question Extraction & Intelligent Chunking

**As a** backend service,
**I want** to extract individual questions from parsed document,
**So that** each question is a separate, self-contained learning unit.

**Acceptance Criteria:**

**Given** Upstage parsed document structure
**When** `services/parser/extractor.py` processes the content
**Then** questions are identified by patterns:
- "1.", "2.", "문제 1", "Q1" etc.
- 5-choice options: "①②③④⑤" or "가나다라마" or "1)2)3)4)5)"
- Answer markers: "정답:", "답:", "[정답]"
- Explanation markers: "해설:", "[해설]"

**Given** a passage-based question set ("다음 글을 읽고...")
**When** chunking is performed
**Then** the passage (지문) is duplicated into each sub-question chunk:
```json
{
  "question_id": "q_001",
  "passage": "다음 사례를 읽고 물음에 답하시오. [사례 내용...]",
  "question_text": "위 사례에서 사회복지사의 역할로 적절한 것은?",
  "options": ["①...", "②...", "③...", "④...", "⑤..."],
  "answer": 3,
  "explanation": "정답은 ③입니다. 해설..."
}
```

**And** each extracted question follows the schema:
- `question_id`: unique identifier
- `study_set_id`: parent study set
- `passage`: optional context text
- `question_text`: the question itself
- `options`: array of 5 choices
- `answer`: correct option index (1-5)
- `explanation`: answer explanation
- `difficulty`: null (to be set later)
- `concepts`: empty array (to be tagged later)

**Prerequisites:** Story 2.3

**Technical Notes:**
- Service: `services/parser/extractor.py`, `services/chunker/intelligent.py`
- Use regex patterns for Korean exam formats
- Handle edge cases: missing explanations, image-based questions
- Log extraction confidence scores

---

### Story 2.5: Vector Embedding & Pinecone Storage

**As a** backend service,
**I want** to embed questions and store in Pinecone,
**So that** questions can be retrieved for tests and similarity searches.

**Acceptance Criteria:**

**Given** extracted questions from Story 2.4
**When** `services/embedding/openai.py` processes questions
**Then**:
1. Each question text + options are concatenated for embedding
2. OpenAI `text-embedding-3-small` generates 1536-dim vector
3. Vector is upserted to Pinecone index with metadata:
```json
{
  "id": "q_001",
  "values": [0.123, -0.456, ...],
  "metadata": {
    "study_set_id": "uuid",
    "question_text": "...",
    "options": ["①...", ...],
    "answer": 3,
    "explanation": "...",
    "user_id": "uuid"
  }
}
```

**And** Pinecone namespace is `{user_id}` for data isolation

**And** on embedding failure, retry with exponential backoff

**Prerequisites:** Story 2.4

**Technical Notes:**
- Service: `services/embedding/openai.py`
- Repository: `repositories/pinecone/questions.py`
- Use batch upsert for efficiency (100 vectors per batch)
- Pinecone index: `certigraph-questions`

---

### Story 2.6: Knowledge Graph Construction

**As a** backend service,
**I want** to build a Knowledge Graph from questions,
**So that** concept relationships can power the analysis features.

**Acceptance Criteria:**

**Given** extracted questions
**When** `services/graph/knowledge.py` processes them
**Then** LLM (GPT-4o-mini) is called with prompt:
```
이 문제가 테스트하는 핵심 개념을 추출하세요.
문제: {question_text}
보기: {options}

응답 형식:
{
  "primary_concept": "사회복지실천기술",
  "secondary_concepts": ["면접기법", "라포형성"],
  "prerequisite_concepts": ["인간행동이론"]
}
```

**And** Neo4j nodes/relationships are created:
- `(:Concept {name, description})` nodes
- `(:Question {id, text})` nodes
- `(:Question)-[:TESTS]->(:Concept)` relationships
- `(:Concept)-[:PREREQUISITE]->(:Concept)` relationships

**And** if concept already exists, relationship is added without duplication

**Given** all questions are processed
**When** Knowledge Graph is complete
**Then** study_set status is updated to 'ready'

**Prerequisites:** Story 2.5

**Technical Notes:**
- Service: `services/graph/knowledge.py`
- Repository: `repositories/neo4j/concepts.py`, `repositories/neo4j/relationships.py`
- Use batch Cypher queries for efficiency
- Cache LLM responses for identical questions

---

### Story 2.7: Study Set Detail & Status Page

**As a** user,
**I want** to see my study set details and parsing status,
**So that** I know when my materials are ready for studying.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets/{id}
**When** parsing is in progress
**Then** I see:
- Study set name
- Upload date
- Progress bar with percentage
- Current step description ("문서 분석 중...", "문제 추출 중...", "AI 태깅 중...")
- Estimated remaining time (optional)

**Given** parsing is complete (status='ready')
**When** I view the page
**Then** I see:
- Total questions extracted count
- Subject/topic breakdown (if available)
- "모의고사 시작" button
- "문제 목록 보기" button
- Option to delete study set

**Given** parsing failed (status='parse_failed')
**When** I view the page
**Then** I see:
- Error message explaining the issue
- "다시 시도" button
- "고객 지원 문의" link

**Prerequisites:** Story 2.2, Story 2.6

**Technical Notes:**
- Page: `app/(dashboard)/study-sets/[id]/page.tsx`
- Use React Query for polling status updates (every 3 seconds while parsing)
- Component: `ParsingProgress.tsx`

---

## Epic 3: CBT Test Engine

**Goal:** 사용자가 CBT 환경에서 모의고사를 응시하고 실시간으로 채점받을 수 있다.

**User Value:** 사용자는 실제 시험과 유사한 환경에서 문제를 풀고, 보기 순서가 매번 바뀌어 정답 위치 암기 없이 진정한 실력을 테스트할 수 있다.

**FR Coverage:** FR-5 (CBT 모의고사)

**Architecture References:**
- Pinecone for question retrieval
- Frontend randomization logic
- Supabase for session/answer storage

---

### Story 3.1: Test Session Initialization

**As a** user,
**I want** to start a new test session,
**So that** I can practice with my uploaded questions.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets/{id} with status='ready'
**When** I click "모의고사 시작"
**Then** modal appears with options:
- "전체 문제" (all questions)
- "랜덤 20문제", "랜덤 50문제"
- "틀린 문제만" (if previous attempts exist)

**When** I select option and click "시작"
**Then** `POST /api/v1/tests/start` is called:
```json
{
  "study_set_id": "uuid",
  "mode": "random",
  "question_count": 20
}
```

**And** response contains:
```json
{
  "data": {
    "session_id": "uuid",
    "questions": [
      {
        "id": "q_001",
        "question_text": "...",
        "options": ["①...", ...],  // Original order
        "passage": "..." // if exists
      }
    ],
    "total_questions": 20,
    "time_limit_minutes": null
  }
}
```

**And** I am redirected to /dashboard/test/{session_id}

**Prerequisites:** Epic 2 complete

**Technical Notes:**
- Endpoint: `api/v1/endpoints/tests.py`
- Service: `services/test_engine/session.py`
- Fetch questions from Pinecone with metadata
- Create `test_sessions` record with status='in_progress'

---

### Story 3.2: CBT Test Interface

**As a** user,
**I want** a clean, distraction-free test interface,
**So that** I can focus on answering questions.

**Acceptance Criteria:**

**Given** I am on /dashboard/test/{session_id}
**When** test page loads
**Then** I see:
- Question number and total (1 / 20)
- Progress bar
- Timer (optional, if time limit set)
- Question text (with passage if applicable)
- 5 options as clickable buttons
- Navigation: "이전", "다음", "제출하기"
- Question navigator panel (grid of numbers, answered=blue, current=yellow)

**And** options are displayed in RANDOMIZED order (different from DB order)
**And** the shuffle mapping is stored client-side for answer submission

**Given** I click an option
**When** option is selected
**Then** option is highlighted
**And** selection is saved to local state
**And** I can change my answer before submission

**Given** I click "다음"
**When** on last question
**Then** button changes to "제출하기"

**Prerequisites:** Story 3.1

**Technical Notes:**
- Page: `app/(dashboard)/test/[sessionId]/page.tsx`
- Components: `QuestionCard.tsx`, `OptionButton.tsx`, `TestProgress.tsx`
- Store: `testStore.ts` for current session state
- Implement Fisher-Yates shuffle for options
- Store original→shuffled index mapping

---

### Story 3.3: Answer Submission & Scoring

**As a** user,
**I want** to submit my answers and see my score,
**So that** I know how well I performed.

**Acceptance Criteria:**

**Given** I have answered some/all questions
**When** I click "제출하기"
**Then** confirmation modal appears: "제출하시겠습니까? 제출 후에는 수정할 수 없습니다."

**When** I confirm submission
**Then** `POST /api/v1/tests/submit` is called:
```json
{
  "session_id": "uuid",
  "answers": [
    {"question_id": "q_001", "selected_option": 3},
    {"question_id": "q_002", "selected_option": 1},
    ...
  ]
}
```

**And** backend scores each answer:
- Compare selected_option with correct answer (accounting for shuffle)
- Calculate total score and percentage
- Save each answer to `user_answers` table
- Update `test_sessions` with score and completed_at

**And** response contains:
```json
{
  "data": {
    "score": 16,
    "total": 20,
    "percentage": 80,
    "time_taken_seconds": 1234
  }
}
```

**And** I am redirected to /dashboard/test/result/{session_id}

**Prerequisites:** Story 3.2

**Technical Notes:**
- Endpoint: `api/v1/endpoints/tests.py`
- Service: `services/test_engine/scoring.py`
- Handle shuffle mapping: client sends original question_id + selected shuffled index
- Backend maps back to original answer index for comparison

---

### Story 3.4: Test Result & Review Page

**As a** user,
**I want** to review my test results with correct answers,
**So that** I can learn from my mistakes.

**Acceptance Criteria:**

**Given** I am on /dashboard/test/result/{session_id}
**When** page loads
**Then** I see:
- Overall score: "16 / 20 (80%)"
- Performance badge: "우수" (≥80%), "양호" (60-79%), "노력필요" (<60%)
- Time taken
- "다시 풀기" button
- "오답만 다시 풀기" button

**And** below summary, question-by-question review:
- Question text
- All 5 options with:
  - ✅ Green highlight on correct answer
  - ❌ Red highlight on user's wrong selection (if wrong)
  - User's selection marked
- Explanation text
- "이 문제 다시 풀기" button

**Given** I click "오답만 다시 풀기"
**When** new session starts
**Then** only incorrectly answered questions are included

**Prerequisites:** Story 3.3

**Technical Notes:**
- Page: `app/(dashboard)/test/result/[sessionId]/page.tsx`
- Component: `ResultSummary.tsx`
- Fetch from `GET /api/v1/tests/{session_id}/result`
- Include question details with user_answer and correct_answer

---

## Epic 4: Analysis & Dashboard

**Goal:** 사용자가 자신의 취약점을 분석하고 학습 진도를 한눈에 파악할 수 있다.

**User Value:** 사용자는 단순 오답 체크를 넘어 "왜 틀렸는지", "어떤 개념이 부족한지"를 구조적으로 파악하고 효율적으로 학습할 수 있다.

**FR Coverage:** FR-4 (Knowledge Graph), FR-6 (오답 분석), FR-7 (대시보드)

**Architecture References:**
- Neo4j GraphRAG for concept analysis
- GPT-4o for insight generation
- React Query for dashboard data

---

### Story 4.1: Weak Concept Analysis API

**As a** backend service,
**I want** to analyze user's weak concepts using GraphRAG,
**So that** personalized learning recommendations can be generated.

**Acceptance Criteria:**

**Given** user has completed at least one test session
**When** `GET /api/v1/analysis/weak-concepts` is called
**Then** system:
1. Fetches user's incorrect answers from `user_answers`
2. For each wrong question, retrieves linked concepts from Neo4j
3. Aggregates concept weakness scores:
   - `weakness_score = wrong_count / total_attempts`
4. Uses GraphRAG to find prerequisite concepts:
   - "사회복지실천기술을 못하는 것은 면접기법 이해 부족 때문일 수 있다"
5. Calls LLM for insight generation:
```
사용자가 다음 개념들에서 약점을 보입니다:
- 사회복지실천기술 (5문제 중 3문제 오답)
- 면접기법 (3문제 중 2문제 오답)

이 사용자의 학습 약점을 분석하고 개선 방향을 제시해주세요.
```

**And** response:
```json
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
    "insight": "면접기법의 기초 개념을 먼저 복습하시면 사회복지실천기술 문제의 정답률이 향상될 것입니다.",
    "recommended_study": ["면접기법 기초", "라포형성 원칙"]
  }
}
```

**Prerequisites:** Epic 3 complete, Story 2.6

**Technical Notes:**
- Endpoint: `api/v1/endpoints/analysis.py`
- Service: `services/analysis/graphrag.py`
- Use Neo4j Cypher for graph traversal
- Cache LLM insights for same weakness patterns (1 hour TTL)

---

### Story 4.2: Weak Concept Analysis UI

**As a** user,
**I want** to see my weak concepts visualized,
**So that** I can focus my study on areas that need improvement.

**Acceptance Criteria:**

**Given** I am on /dashboard/analysis
**When** page loads
**Then** I see:
- "취약 개념 분석" heading
- If no test data: "아직 모의고사를 응시하지 않았습니다. 먼저 모의고사를 풀어보세요."
- If data exists:
  - List of weak concepts sorted by weakness_score (highest first)
  - Each concept card shows:
    - Concept name
    - Weakness bar (red gradient based on score)
    - "X문제 중 Y문제 오답"
    - Related prerequisite concepts as tags
  - AI insight box with personalized recommendation
  - "이 개념 집중 학습" button → starts test with only questions linked to this concept

**Given** I click "이 개념 집중 학습" on a concept
**When** drill mode starts
**Then** new test session created with only questions tagged with that concept

**Prerequisites:** Story 4.1, Story 3.1

**Technical Notes:**
- Page: `app/(dashboard)/analysis/page.tsx`
- Components: `WeakConceptList.tsx`, `ConceptCard.tsx`, `StudyRecommendation.tsx`
- Use React Query with 5-minute cache

---

### Story 4.3: Learning Dashboard

**As a** user,
**I want** to see my overall learning progress,
**So that** I can track my improvement over time.

**Acceptance Criteria:**

**Given** I am on /dashboard (home)
**When** page loads
**Then** I see:
- Welcome message: "{username}님, 오늘도 화이팅!"
- Quick stats cards:
  - "총 학습 문제": X문제
  - "평균 정답률": X%
  - "학습 세트": X개
  - "모의고사 응시": X회
- Recent activity:
  - Last 5 test sessions with date, score, study set name
- Study streak calendar (optional, phase 2)
- "새 학습 세트 추가" quick action button
- "오늘의 추천 학습" based on weak concepts

**Given** user has no data yet
**When** dashboard loads
**Then** onboarding prompt: "첫 번째 PDF를 업로드하고 학습을 시작해보세요!"

**Prerequisites:** Epic 1 complete

**Technical Notes:**
- Page: `app/(dashboard)/page.tsx`
- Aggregate data from multiple tables
- Use React Query for data fetching
- Implement skeleton loading states

---

### Story 4.4: User Progress Tracking (Neo4j)

**As a** backend service,
**I want** to update user's concept mastery in Knowledge Graph,
**So that** recommendations improve over time.

**Acceptance Criteria:**

**Given** user completes a test session
**When** answers are scored
**Then** for each question:
1. If correct: increment `(:User)-[:MASTERED {count}]->(:Concept)`
2. If wrong: increment `(:User)-[:WEAK_AT {count}]->(:Concept)`

**And** concept mastery levels are calculated:
- `mastery_ratio = mastered_count / (mastered_count + weak_count)`
- "숙련" (≥0.8), "학습중" (0.4-0.79), "취약" (<0.4)

**Given** `GET /api/v1/analysis/progress` is called
**When** user's graph data is queried
**Then** response includes:
```json
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

**Prerequisites:** Story 2.6, Story 3.3

**Technical Notes:**
- Repository: `repositories/neo4j/relationships.py`
- Update graph after each test submission
- Use MERGE for upsert behavior
- Cache progress data (invalidate on new test completion)

---

## Final Validation

### FR Coverage Matrix

| FR ID | 기능 | Stories | Coverage |
|-------|------|---------|----------|
| **FR-1** | PDF 업로드 | 2.1, 2.2 | ✅ 100% |
| **FR-2** | 문서 파싱 | 2.3, 2.4 | ✅ 100% |
| **FR-3** | 지능형 청킹 | 2.4 | ✅ 100% |
| **FR-4** | Knowledge Graph | 2.6, 4.1, 4.4 | ✅ 100% |
| **FR-5** | CBT 모의고사 | 3.1, 3.2, 3.3, 3.4 | ✅ 100% |
| **FR-6** | 오답 분석 | 4.1, 4.2 | ✅ 100% |
| **FR-7** | 대시보드 | 4.3 | ✅ 100% |
| **FR-8** | 사용자 인증 | 1.2, 1.3, 1.4, 1.5, 1.6 | ✅ 100% |

### Architecture Integration Validation

- ✅ All API endpoints follow Architecture patterns
- ✅ Database schemas match Architecture specification
- ✅ Authentication flow uses Clerk as designed
- ✅ Error responses follow defined format
- ✅ Naming conventions applied consistently

### Story Quality Validation

- ✅ All stories are single-session completable
- ✅ Acceptance criteria are BDD format with specifics
- ✅ No forward dependencies
- ✅ Technical notes reference Architecture sections
- ✅ Prerequisites are clearly stated

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Epics** | 4 |
| **Total Stories** | 17 |
| **FR Coverage** | 8/8 (100%) |
| **Architecture Alignment** | ✅ Complete |

**Epic Breakdown:**
- Epic 1: Foundation & Authentication (6 stories)
- Epic 2: PDF Upload & Parsing Pipeline (7 stories)
- Epic 3: CBT Test Engine (4 stories)
- Epic 4: Analysis & Dashboard (4 stories)

---

_For implementation: Use the `create-story` workflow to generate individual story implementation plans from this epic breakdown._

