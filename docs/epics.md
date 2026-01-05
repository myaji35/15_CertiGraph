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
| **Epic 2** | Study Set & Material Management | 사용자가 문제집을 만들고 PDF를 업로드하여 학습 자료를 추가할 수 있다 | FR-1, FR-2, FR-3, FR-4 |
| **Epic 3** | CBT Test Engine | 사용자가 모의고사를 응시하고 채점받을 수 있다 | FR-5 |
| **Epic 4** | Analysis & Dashboard | 사용자가 취약점 분석과 학습 진도를 확인할 수 있다 | FR-4, FR-6, FR-7 |
| **Epic 5** | Payment & Subscription | 사용자가 서비스 이용권을 구매하고 관리할 수 있다 | MVP Essential |

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

## Epic 2: Study Set & Material Management

**Goal:** 사용자가 문제집을 생성/관리하고, 문제집에 PDF 학습자료를 업로드하여 자동으로 문제를 추출할 수 있다.

**User Value:** 사용자는 자격증과 시험일자를 기반으로 문제집을 체계적으로 관리하고, PDF를 업로드하면 AI가 자동으로 문제/보기/해설을 분리하여 즉시 학습을 시작할 수 있다.

**FR Coverage:** FR-1 (PDF 업로드), FR-2 (문서 파싱), FR-3 (지능형 청킹), FR-4 (Knowledge Graph)

**Data Model:**
- **문제집 (Study Set)**: 메타데이터 컨테이너
  - 속성: name (문제집명), description (개요), certification_id (자격증), exam_year (시험연도), exam_round (회차)
  - 기능: CRUD (생성, 조회, 수정, 삭제)
  - 학습자료와 1:N 관계

- **학습자료 (Study Material)**: 문제집에 속한 PDF 파일
  - 속성: study_set_id (부모 문제집), name (자료명), pdf_url, status (parsing/ready/failed), question_count
  - 기능: 업로드 → AI 자동 파싱 → 문제 추출
  - 문제집 없이는 존재할 수 없음 (cascade delete)

**Workflow:**
1. 사용자가 문제집 생성 (메타데이터만, 시험일 자동 추천)
2. 문제집 목록에서 원하는 문제집 선택
3. 해당 문제집에 PDF 학습자료 업로드
4. AI가 자동으로 PDF 파싱 및 문제 추출
5. 문제집의 total_questions 자동 업데이트

**Architecture References:**
- Upstage Document Parse API
- Pinecone for question embeddings
- Neo4j for Knowledge Graph
- FastAPI async processing
- Supabase Storage for PDF files

---

### Story 2.1: Study Set Creation Form

**As a** user,
**I want** to create a new study set with metadata only,
**So that** I can later add PDF materials to it.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets
**When** I click "새 문제집 만들기"
**Then** I see a modal or form with:
- "문제집명" input field (required) - placeholder: "예: 2024년 사회복지사 1급"
- "자격증 종류" dropdown (required) - loaded from `GET /api/v1/certifications`
- "시험 연도" number input (optional) - default: current year
- "회차" dropdown (optional) - options: 1회차, 2회차, 3회차
- "개요" textarea (optional) - placeholder: "문제집에 대한 설명을 입력하세요"
- "취소" and "생성" buttons

**Given** I enter only required fields (name, certification)
**When** I click "생성"
**Then** `POST /api/v1/study-sets` is called with:
```json
{
  "name": "2024년 사회복지사 1급",
  "certification_id": "uuid",
  "exam_year": null,
  "exam_round": null,
  "description": "",
  "target_exam_date": "2025-01-25"  // Auto-recommended closest date
}
```

**Given** I select a certification
**When** the form updates
**Then** the system automatically fetches the nearest upcoming exam date (e.g., "2025-01-25")
**And** displays it in a read-only or editable "목표 시험일" field
**And** shows a helper text: "가장 가까운 제23회 시험일이 자동 선택되었습니다."

**And** on success:
- Modal/form closes
- Success toast appears: "문제집이 생성되었습니다"
- I am redirected to `/dashboard/study-sets/{new_id}` (study set detail page)
- The page shows "학습자료가 없습니다. 첫 번째 학습자료를 추가해보세요" message

**Given** I enter invalid data (e.g., empty name)
**When** I click "생성"
**Then** validation error appears: "문제집명을 입력해주세요"

**Given** API returns error
**When** creation fails
**Then** error toast appears with error message

**Prerequisites:** Epic 1 complete

**Technical Notes:**
- Create new component: `StudySetCreateModal.tsx` or use separate page
- Alternatively, keep `/dashboard/study/upload` but rename to `/dashboard/study-sets/new`
- Remove all PDF upload UI from this story
- Focus purely on metadata collection
- Fetch certifications from `GET /api/v1/certifications` on mount
- Use React Hook Form for validation
- Auto-redirect to study set detail page after creation

---

### Story 2.1A: Study Set List & Edit UI

**As a** user,
**I want** to view, edit, and delete my study sets,
**So that** I can manage my exam preparation materials.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets
**When** page loads
**Then** I see:
- Page title: "내 문제집"
- "새 문제집 만들기" button (triggers Story 2.1)
- Search bar for filtering study sets
- Stats cards showing:
  - 전체 문제집 개수
  - 총 문제 수 (all materials combined)
  - 학습 완료 개수 (phase 2)
- Grid of study set cards

**Given** I have study sets
**When** viewing the list
**Then** each card shows:
- 문제집명
- 자격증 badge
- 시험연도 + 회차 (if available)
- 학습자료 개수 (e.g., "학습자료 3개")
- 총 문제 수 (e.g., "문제 150개")
- 생성일
- "수정" and "삭제" buttons
- Click anywhere on card → navigate to study set detail

**Given** I click "수정" on a study set
**When** edit mode activates
**Then** I can edit:
- 문제집명 (inline or modal)
- 개요 (inline or modal)
**And** changes are saved via `PATCH /api/v1/study-sets/{id}`
**And** success toast appears: "문제집이 수정되었습니다"

**Given** I click "삭제" on a study set
**When** delete is triggered
**Then** confirmation dialog appears:
- Title: "문제집 삭제"
- Message: "이 문제집과 모든 학습자료가 삭제됩니다. 계속하시겠습니까?"
- "취소" and "삭제" buttons

**When** I confirm deletion
**Then** `DELETE /api/v1/study-sets/{id}` is called
**And** on success:
- Study set removed from list
- Success toast: "문제집이 삭제되었습니다"

**Given** I have no study sets
**When** page loads
**Then** I see empty state:
- Icon (Book)
- Message: "아직 문제집이 없습니다"
- "첫 번째 문제집 만들기" button

**Prerequisites:** Story 2.1

**Technical Notes:**
- Page: `app/(dashboard)/study-sets/page.tsx` (already partially implemented)
- Components: `StudySetCard.tsx`, `StudySetList.tsx`
- Use React Query for data fetching and cache invalidation
- Implement optimistic updates for edit/delete
- Use Tanstack Table or simple grid for layout

---

### Story 2.2: Study Set CRUD API

**As a** backend service,
**I want** to provide CRUD endpoints for study sets,
**So that** users can manage their study set metadata.

**Acceptance Criteria:**

**[CREATE] POST /api/v1/study-sets**

**Given** authenticated user sends request:
```json
{
  "name": "2024년 사회복지사 1급",
  "certification_id": "cert_uuid",
  "exam_year": 2024,
  "exam_round": 1,
  "description": "1교시 문제집"
}
```

**Then** system:
1. Validates user owns certification access (optional: check subscription)
2. Creates study_set record:
   - `id`: UUID v4
   - `user_id`: extracted from JWT
   - `name`, `certification_id`, `exam_year`, `exam_round`, `description`
   - `total_materials`: 0 (default)
   - `total_questions`: 0 (default)
   - `created_at`, `updated_at`: current timestamp
3. Returns HTTP 201 Created:
```json
{
  "data": {
    "id": "set_uuid",
    "name": "2024년 사회복지사 1급",
    "certification_id": "cert_uuid",
    "exam_year": 2024,
    "exam_round": 1,
    "description": "1교시 문제집",
    "total_materials": 0,
    "total_questions": 0,
    "created_at": "2025-01-15T09:30:00Z"
  }
}
```

**[READ ALL] GET /api/v1/study-sets**

**Given** authenticated user requests study sets
**Then** return all study sets owned by user:
```json
{
  "data": [
    {
      "id": "set_uuid",
      "name": "2024년 사회복지사 1급",
      "certification_id": "cert_uuid",
      "certification_name": "사회복지사 1급",
      "exam_year": 2024,
      "exam_round": 1,
      "description": "1교시 문제집",
      "total_materials": 3,
      "total_questions": 150,
      "created_at": "2025-01-15T09:30:00Z"
    }
  ]
}
```
**And** results are sorted by `created_at DESC` (newest first)

**[READ ONE] GET /api/v1/study-sets/{id}**

**Given** authenticated user requests specific study set
**When** user owns the study set
**Then** return study set with materials list:
```json
{
  "data": {
    "id": "set_uuid",
    "name": "2024년 사회복지사 1급",
    "certification": {
      "id": "cert_uuid",
      "name": "사회복지사 1급"
    },
    "exam_year": 2024,
    "exam_round": 1,
    "description": "1교시 문제집",
    "total_materials": 3,
    "total_questions": 150,
    "materials": [
      {
        "id": "mat_uuid",
        "name": "1교시 A형",
        "status": "ready",
        "question_count": 50,
        "created_at": "2025-01-15T10:00:00Z"
      }
    ],
    "created_at": "2025-01-15T09:30:00Z",
    "updated_at": "2025-01-15T10:00:00Z"
  }
}
```

**When** user doesn't own the study set
**Then** return HTTP 403 Forbidden

**[UPDATE] PATCH /api/v1/study-sets/{id}**

**Given** authenticated user sends update:
```json
{
  "name": "2024년 사회복지사 1급 (수정됨)",
  "description": "업데이트된 설명"
}
```

**When** user owns the study set
**Then**:
1. Update only provided fields (name, description)
2. Update `updated_at` timestamp
3. Return HTTP 200 with updated record

**And** fields NOT allowed to update:
- `certification_id` (immutable)
- `total_materials` (auto-calculated)
- `total_questions` (auto-calculated)

**[DELETE] DELETE /api/v1/study-sets/{id}**

**Given** authenticated user requests deletion
**When** user owns the study set
**Then**:
1. Delete all associated study_materials (cascade)
2. Delete study_set record
3. Return HTTP 204 No Content

**When** user doesn't own the study set
**Then** return HTTP 403 Forbidden

**Error Handling:**

**Given** invalid certification_id
**Then** HTTP 400: "유효하지 않은 자격증입니다"

**Given** duplicate name for same user
**Then** HTTP 400: "이미 존재하는 문제집명입니다"

**Prerequisites:** Story 1.5

**Technical Notes:**
- Endpoint: `api/v1/endpoints/study_sets.py`
- Repository: `repositories/study_sets.py`
- Schema: `schemas/study_set.py` (CreateStudySet, UpdateStudySet, StudySetResponse)
- Database table: `study_sets`
  ```sql
  CREATE TABLE study_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    certification_id UUID NOT NULL REFERENCES certifications(id),
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    exam_year INTEGER,
    exam_round INTEGER,
    total_materials INTEGER DEFAULT 0,
    total_questions INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, name)
  );
  ```
- Implement ownership middleware: `verify_study_set_ownership()`
- Use database trigger to update `total_materials` and `total_questions`

---

### Story 2.3: Study Set Detail Page (View Materials)

**As a** user,
**I want** to view my study set details and all uploaded materials,
**So that** I can track my learning materials and their parsing status.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets/{id}
**When** page loads
**Then** I see:

**Header Section:**
- Breadcrumb: "내 문제집 > {문제집명}"
- 문제집명 (h1)
- 자격증 badge
- 시험연도 + 회차 (if exists)
- 개요 (if exists)
- "수정" button (opens edit modal)

**Stats Cards:**
- 총 학습자료: X개
- 총 문제 수: Y개
- 파싱 완료율: Z% (ready materials / total materials)

**Materials Section:**
- Section title: "학습자료" with "추가" button
- If no materials: Empty state
  - Icon (FileText)
  - "아직 학습자료가 없습니다"
  - "첫 번째 학습자료를 추가하여 문제를 파싱해보세요"
  - "학습자료 추가" button

**Given** study set has materials
**When** viewing materials list
**Then** I see table/grid with:
- 자료명
- 상태 badge:
  - "파싱 대기" (pending) - gray
  - "파싱 중" (parsing) - blue with spinner
  - "완료" (ready) - green
  - "실패" (failed) - red
- 문제 수 (if ready)
- 업로드 일시
- Actions: "삭제" button

**Given** a material is parsing (status='parsing')
**When** viewing its row
**Then** I see:
- Progress bar (0-100%)
- Current step text ("문서 분석 중...", "문제 추출 중...", etc.)
- Auto-refresh every 3 seconds (React Query polling)

**Given** a material failed (status='failed')
**When** viewing its row
**Then** I see:
- Error icon
- "파싱 실패" badge
- "다시 업로드" button (deletes old, opens upload modal)

**Action Buttons (Bottom):**
- "모의고사 시작" button
  - Enabled only if total_questions > 0
  - Click → navigate to test session creation
- "문제집 삭제" button (danger)

**Prerequisites:** Story 2.2

**Technical Notes:**
- Page: `app/(dashboard)/study-sets/[id]/page.tsx`
- Fetch data from `GET /api/v1/study-sets/{id}` (includes materials array)
- Use React Query with polling for parsing materials:
  ```ts
  useQuery({
    queryKey: ['study-set', id],
    queryFn: () => fetchStudySet(id),
    refetchInterval: (data) =>
      data?.materials.some(m => m.status === 'parsing') ? 3000 : false
  })
  ```
- Components:
  - `StudySetHeader.tsx`
  - `StudySetStats.tsx`
  - `MaterialsTable.tsx` or `MaterialsList.tsx`
  - `ParsingProgress.tsx` (for parsing materials)
- Implement optimistic UI for material deletion

---

### Story 2.3A: Study Material Upload Modal

**As a** user,
**I want** to upload PDF files to my study set through a modal,
**So that** I can add exam materials for AI parsing.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets/{id}
**When** I click "학습자료 추가" button
**Then** modal opens with title "학습자료 업로드"

**Modal Content:**
- Drag & drop zone
  - Icon (Upload)
  - Primary text: "PDF 파일을 드래그하거나 클릭하여 선택하세요"
  - Secondary text: "PDF만 가능, 최대 50MB"
- "자료명" input field
  - Label: "자료명 (선택사항)"
  - Placeholder: "예: 2024년 1회차 1교시 A형"
  - Auto-filled with filename when file is selected
  - User can edit
- Selected file display (when file chosen):
  - File icon
  - Filename
  - File size (formatted: "2.4 MB")
  - Remove button (X)
- Footer buttons:
  - "취소" (closes modal, clears file)
  - "업로드" (disabled until file selected)

**Given** I drag a valid PDF file
**When** file is dropped
**Then**:
- File name and size displayed
- "자료명" field auto-filled with filename (without .pdf extension)
- "업로드" button becomes enabled

**Given** I drag an invalid file (non-PDF)
**When** file is dropped
**Then**:
- Error toast appears: "PDF 파일만 업로드 가능합니다"
- File is not accepted

**Given** I drag a file >50MB
**When** file is dropped
**Then**:
- Error toast appears: "파일 크기는 50MB 이하여야 합니다"
- File is not accepted

**When** I click "업로드"
**Then**:
- Upload starts
- Modal shows upload progress:
  - Progress bar (0-100%)
  - "업로드 중... X%" text
  - Cancel button becomes disabled
- File is uploaded via `POST /api/v1/study-materials/upload`

**When** upload completes successfully
**Then**:
- Success toast: "{자료명}이(가) 업로드되었습니다"
- Modal closes
- Study set detail page refreshes
- New material appears in list with "파싱 중..." status

**When** upload fails
**Then**:
- Error toast with specific message
- Progress bar turns red
- "다시 시도" button appears
- Cancel button becomes enabled

**Prerequisites:** Story 2.3

**Technical Notes:**
- Component: `MaterialUploadModal.tsx`
- Use `react-dropzone` for drag & drop
- File validation:
  - MIME type: `application/pdf`
  - Size: ≤ 50MB (52428800 bytes)
- Upload with FormData:
  ```ts
  const formData = new FormData();
  formData.append('file', file);
  formData.append('study_set_id', studySetId);
  formData.append('name', materialName || file.name.replace('.pdf', ''));
  ```
- Show upload progress using axios `onUploadProgress` or similar
- Close modal on successful upload and invalidate React Query cache

---

### Story 2.4: Study Material Upload API

**As a** backend service,
**I want** to receive PDF uploads for study materials and initiate parsing,
**So that** the document processing pipeline can extract questions.

**Acceptance Criteria:**

**[UPLOAD] POST /api/v1/study-materials/upload**

**Given** authenticated user uploads PDF
**When** request received with multipart form-data:
```
Content-Type: multipart/form-data

study_set_id: "set_uuid" (required)
file: [PDF binary] (required)
name: "2024년 1회차 1교시" (optional)
```

**Then** system performs:

**1. Validation:**
- Verify `study_set_id` exists and user owns it → else HTTP 403
- Check file MIME type = `application/pdf` → else HTTP 400
- Check file size ≤ 50MB → else HTTP 413

**2. Storage:**
- Generate material ID: `mat_{uuid}`
- Generate storage path: `materials/{user_id}/{study_set_id}/{mat_id}.pdf`
- Upload to Supabase Storage bucket `study-materials`
- Get public URL

**3. Database Record:**
```sql
INSERT INTO study_materials (
  id, study_set_id, name, pdf_url, status, question_count,
  parsing_progress, parsing_step, created_at
) VALUES (
  'mat_uuid', 'set_uuid', '2024년 1회차 1교시',
  'https://storage...', 'pending', 0, 0, NULL, NOW()
);
```

**4. Trigger Background Job:**
- Queue parsing task with material ID
- Update status to 'parsing'

**5. Response (HTTP 201):**
```json
{
  "data": {
    "id": "mat_uuid",
    "study_set_id": "set_uuid",
    "name": "2024년 1회차 1교시",
    "pdf_url": "https://...",
    "status": "parsing",
    "question_count": 0,
    "parsing_progress": 0,
    "parsing_step": "대기 중",
    "created_at": "2025-01-15T09:30:00Z"
  }
}
```

**[GET STATUS] GET /api/v1/study-materials/{id}**

**Given** authenticated user requests material status
**When** user owns the parent study_set
**Then** return current state:
```json
{
  "data": {
    "id": "mat_uuid",
    "study_set_id": "set_uuid",
    "name": "2024년 1회차 1교시",
    "status": "parsing",
    "question_count": 0,
    "parsing_progress": 45,
    "parsing_step": "문제 추출 중...",
    "error_message": null,
    "created_at": "2025-01-15T09:30:00Z",
    "completed_at": null
  }
}
```

**[DELETE] DELETE /api/v1/study-materials/{id}**

**Given** authenticated user deletes material
**When** user owns the parent study_set
**Then**:
1. Delete PDF from Supabase Storage
2. Delete all associated questions (cascade)
3. Delete material record
4. Decrement `study_sets.total_materials` and `total_questions`
5. Return HTTP 204

**Error Handling:**

| Error Condition | HTTP Code | Error Response |
|----------------|-----------|----------------|
| Missing file | 400 | `VALIDATION_MISSING_FILE`: "파일을 선택해주세요" |
| Invalid file type | 400 | `VALIDATION_FORMAT`: "PDF 파일만 업로드 가능합니다" |
| File too large | 413 | `VALIDATION_SIZE`: "파일 크기는 50MB 이하여야 합니다" |
| Study set not found | 404 | `RESOURCE_NOT_FOUND`: "문제집을 찾을 수 없습니다" |
| Not owner | 403 | `PERMISSION_DENIED`: "권한이 없습니다" |
| Storage failure | 500 | `STORAGE_ERROR`: "파일 업로드 중 오류가 발생했습니다" |

**Rate Limiting:**
- 5 uploads per hour per user
- On exceeded: HTTP 429 "업로드 한도를 초과했습니다. 잠시 후 다시 시도해주세요."

**Prerequisites:** Story 2.2

**Technical Notes:**

**Endpoint:**
- File: `api/v1/endpoints/study_materials.py`
- FastAPI `UploadFile` for multipart handling

**Database Schema:**
```sql
CREATE TABLE study_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  study_set_id UUID NOT NULL REFERENCES study_sets(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  pdf_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, parsing, ready, failed
  question_count INTEGER DEFAULT 0,
  parsing_progress INTEGER DEFAULT 0, -- 0-100
  parsing_step TEXT, -- "문서 분석 중...", "문제 추출 중..." etc
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX idx_study_materials_study_set ON study_materials(study_set_id);
CREATE INDEX idx_study_materials_status ON study_materials(status);
```

**Supabase Storage:**
- Bucket: `study-materials`
- Path pattern: `{user_id}/{study_set_id}/{material_id}.pdf`
- Public read access (for signed URLs)
- Max file size: 50MB

**Background Job:**
- Use FastAPI `BackgroundTasks` initially
- Future: Celery/Redis queue for production
- Task: `tasks/parse_material.py`

**Dependencies:**
```python
from fastapi import UploadFile, BackgroundTasks, Depends
from app.api.v1.deps import get_current_user, verify_study_set_ownership
from app.services.storage import upload_to_supabase
from app.tasks.parse_material import parse_pdf_task
```

---

### Story 2.5: Upstage Document Parse Integration

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
- On final failure, update study_material status='parse_failed'
- Log error with request_id for debugging

**And** parsing progress is trackable via `GET /api/v1/study-materials/{id}/status`:
```json
{
  "data": {
    "status": "parsing",
    "progress": 45,
    "current_step": "문서 구조 분석 중..."
  }
}
```

**Prerequisites:** Story 2.4

**Technical Notes:**
- Service: `services/parser/upstage.py`
- Use `httpx` for async HTTP calls
- Store Upstage API key in environment variable
- Implement proper error handling per Architecture patterns

---

### Story 2.6: Question Extraction & Intelligent Chunking

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

**Prerequisites:** Story 2.5

**Technical Notes:**
- Service: `services/parser/extractor.py`, `services/chunker/intelligent.py`
- Use regex patterns for Korean exam formats
- Handle edge cases: missing explanations, image-based questions
- Log extraction confidence scores
- Link questions to `study_material_id` and `study_set_id`

---

### Story 2.7: Vector Embedding & Pinecone Storage

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

**Prerequisites:** Story 2.6

**Technical Notes:**
- Service: `services/embedding/openai.py`
- Repository: `repositories/pinecone/questions.py`
- Use batch upsert for efficiency (100 vectors per batch)
- Pinecone index: `certigraph-questions`
- Include `study_material_id` and `study_set_id` in metadata

---

### Story 2.8: Knowledge Graph Construction

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
**Then** study_material status is updated to 'ready'
**And** study_set.total_questions is incremented

**Prerequisites:** Story 2.7

**Technical Notes:**
- Service: `services/graph/knowledge.py`
- Repository: `repositories/neo4j/concepts.py`, `repositories/neo4j/relationships.py`
- Use batch Cypher queries for efficiency
- Cache LLM responses for identical questions

---


## Epic 3: CBT Test Engine

**Goal:** 사용자가 문제집의 학습자료들에서 추출된 문제로 CBT 모의고사를 응시하고 실시간으로 채점받을 수 있다.

**User Value:** 사용자는 실제 시험과 유사한 환경에서 문제를 풀고, 보기 순서가 매번 바뀌어 정답 위치 암기 없이 진정한 실력을 테스트할 수 있다. 문제집 내 특정 학습자료만 선택하거나 전체 자료를 통합하여 시험을 볼 수 있다.

**FR Coverage:** FR-5 (CBT 모의고사)

**Data Model Integration:**
- **문제집 (Study Set)** → 여러 학습자료 포함
- **학습자료 (Study Material)** → 각각 파싱된 문제들 포함
- **시험 세션 (Test Session)** → study_set_id 기반으로 생성
- **문제 (Question)** → study_material_id로 출처 추적

**Test Modes:**
1. **전체 문제** - 문제집의 모든 학습자료에서 추출된 모든 문제
2. **학습자료 선택** - 특정 학습자료(들)만 선택하여 시험
3. **랜덤 N문제** - 전체에서 랜덤 추출
4. **오답 노트** - 이전에 틀린 문제만 (학습자료 구분 없이)

**Architecture References:**
- Pinecone for question retrieval (with study_material_id filter)
- Frontend randomization logic
- Supabase for session/answer storage
- PostgreSQL for study_set ↔ study_materials relationship

---

### Story 3.1: Test Configuration Modal

**As a** user,
**I want** to configure my test session with flexible options,
**So that** I can practice exactly what I need.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets/{id}
**When** I click "모의고사 시작"
**Then** modal opens: "모의고사 설정"

**Modal Content:**

**Section 1: 학습자료 선택**
- Radio options:
  - "전체 학습자료" (default) - 문제집의 모든 자료 (X문제)
  - "학습자료 선택" - 특정 자료만 선택

**Given** "학습자료 선택" is selected
**Then** checkboxes appear with list:
- [ ] "2024년 1회차 1교시 A형" (50문제)
- [ ] "2024년 1회차 2교시 A형" (50문제)
- [ ] "2024년 1회차 3교시 A형" (50문제)

**And** total selected questions count updates dynamically
**And** at least one material must be selected

**Section 2: 문제 범위**
- Radio options:
  - "전체 문제" - 선택한 자료의 모든 문제 (default)
  - "랜덤 문제" - 랜덤 추출
  - "오답 노트" - 이전에 틀린 문제만 (if exists)

**Given** "랜덤 문제" is selected
**Then** number input appears:
- Label: "문제 수"
- Min: 10
- Max: total available questions
- Default: 20

**Given** "오답 노트" is selected **And** no wrong answers exist
**Then** option is disabled with tooltip: "아직 틀린 문제가 없습니다"

**Section 3: 추가 옵션 (Optional)**
- [ ] "제한 시간 설정" - checkbox
  - If checked: number input (분) appears
  - Default: certification의 표준 시험 시간

**Footer Buttons:**
- "취소" - closes modal
- "시작하기" - creates session

**When** I click "시작하기"
**Then** `POST /api/v1/test-sessions` is called:
```json
{
  "study_set_id": "set_uuid",
  "material_ids": ["mat_uuid_1", "mat_uuid_2"],  // or null for all
  "mode": "random",  // or "all", "wrong_only"
  "question_count": 20,  // or null for all
  "time_limit_minutes": 180  // or null
}
```

**And** on success:
- Modal closes
- Loading spinner appears
- Redirected to `/test/{session_id}`

**Given** no materials have status='ready'
**When** modal opens
**Then** I see:
- Warning message: "아직 파싱이 완료된 학습자료가 없습니다"
- "시작하기" button is disabled

**Given** API returns error (e.g., not enough questions)
**Then** error toast appears with specific message

**Prerequisites:** Story 2.3 (Study Set Detail Page), Story 2.8 (Parsing Complete)

**Technical Notes:**
- Component: `TestConfigModal.tsx`
- Fetch materials from current study set (already loaded in parent)
- Filter materials with status='ready' only
- Calculate total available questions dynamically
- Validate selections before API call
- Use React Hook Form for form state management

---

### Story 3.1A: Test Session Creation API

**As a** backend service,
**I want** to create test sessions based on user configuration,
**So that** questions can be retrieved and served for the test.

**Acceptance Criteria:**

**[CREATE SESSION] POST /api/v1/test-sessions**

**Given** authenticated user sends request:
```json
{
  "study_set_id": "set_uuid",
  "material_ids": ["mat_uuid_1", "mat_uuid_2"],
  "mode": "random",
  "question_count": 20,
  "time_limit_minutes": 180
}
```

**Then** system performs:

**1. Validation:**
- Verify user owns study_set
- Verify all material_ids belong to study_set
- Verify all materials have status='ready'
- If mode='random': verify question_count ≤ available questions
- If mode='wrong_only': verify user has wrong answers

**2. Question Retrieval:**
- **If material_ids provided**: fetch questions from those materials only
- **If material_ids is null**: fetch from all materials in study_set
- **If mode='all'**: return all questions
- **If mode='random'**: random sample of question_count
- **If mode='wrong_only'**: fetch question_ids from user_answers WHERE is_correct=false

**Query Pinecone:**
```python
# Example: Random 20 from specific materials
index.query(
    namespace=user_id,
    filter={
        "study_set_id": "set_uuid",
        "study_material_id": {"$in": ["mat_uuid_1", "mat_uuid_2"]}
    },
    top_k=20,
    include_metadata=True
)
```

**3. Create Session Record:**
```sql
INSERT INTO test_sessions (
  id, user_id, study_set_id, mode, question_count,
  time_limit_minutes, status, started_at
) VALUES (
  'session_uuid', 'user_uuid', 'set_uuid', 'random', 20,
  180, 'in_progress', NOW()
);
```

**4. Store Question Order:**
```sql
-- For preserving question order and tracking
INSERT INTO session_questions (
  session_id, question_id, sequence_number, study_material_id
) VALUES
  ('session_uuid', 'q_001', 1, 'mat_uuid_1'),
  ('session_uuid', 'q_002', 2, 'mat_uuid_2'),
  ...
```

**5. Response (HTTP 201):**
```json
{
  "data": {
    "session_id": "session_uuid",
    "study_set_id": "set_uuid",
    "study_set_name": "2024년 사회복지사 1급",
    "mode": "random",
    "total_questions": 20,
    "time_limit_minutes": 180,
    "started_at": "2025-01-15T10:00:00Z",
    "questions": [
      {
        "id": "q_001",
        "sequence": 1,
        "passage": "다음 사례를 읽고...",
        "question_text": "위 사례에서...",
        "options": ["①...", "②...", "③...", "④...", "⑤..."],
        "study_material_name": "2024년 1회차 1교시"
      }
    ]
  }
}
```

**Error Handling:**

| Error Condition | HTTP Code | Error Response |
|----------------|-----------|----------------|
| Study set not found | 404 | `RESOURCE_NOT_FOUND`: "문제집을 찾을 수 없습니다" |
| Not owner | 403 | `PERMISSION_DENIED`: "권한이 없습니다" |
| Material not ready | 400 | `VALIDATION_STATUS`: "파싱이 완료되지 않은 자료가 있습니다" |
| Not enough questions | 400 | `VALIDATION_COUNT`: "요청한 문제 수보다 적은 문제만 있습니다 (X문제 가능)" |
| No wrong answers | 400 | `VALIDATION_EMPTY`: "틀린 문제가 없습니다" |

**Prerequisites:** Story 2.8 (Knowledge Graph Complete)

**Technical Notes:**

**Database Schema:**
```sql
CREATE TABLE test_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  study_set_id UUID NOT NULL REFERENCES study_sets(id),
  mode TEXT NOT NULL, -- 'all', 'random', 'wrong_only'
  question_count INTEGER NOT NULL,
  time_limit_minutes INTEGER,
  status TEXT NOT NULL DEFAULT 'in_progress', -- in_progress, completed, abandoned
  score INTEGER,
  percentage DECIMAL(5,2),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  time_taken_seconds INTEGER
);

CREATE TABLE session_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES test_sessions(id) ON DELETE CASCADE,
  question_id TEXT NOT NULL, -- Pinecone ID
  study_material_id UUID REFERENCES study_materials(id),
  sequence_number INTEGER NOT NULL,
  UNIQUE(session_id, sequence_number)
);

CREATE INDEX idx_test_sessions_user ON test_sessions(user_id, started_at DESC);
CREATE INDEX idx_session_questions_session ON session_questions(session_id, sequence_number);
```

**Endpoint:**
- File: `api/v1/endpoints/test_sessions.py`
- Service: `services/test_engine/session.py`
- Repository: `repositories/test_sessions.py`

**Question Retrieval Logic:**
```python
async def get_questions_for_session(
    user_id: str,
    study_set_id: str,
    material_ids: List[str] | None,
    mode: str,
    question_count: int | None
) -> List[Question]:
    # Build Pinecone filter
    filter_dict = {"study_set_id": study_set_id}

    if material_ids:
        filter_dict["study_material_id"] = {"$in": material_ids}

    if mode == "wrong_only":
        wrong_question_ids = await get_wrong_question_ids(user_id, study_set_id)
        filter_dict["question_id"] = {"$in": wrong_question_ids}

    # Query Pinecone
    results = pinecone_index.query(
        namespace=user_id,
        filter=filter_dict,
        top_k=question_count or 10000,  # Large number for "all"
        include_metadata=True
    )

    questions = [parse_pinecone_result(r) for r in results.matches]

    if mode == "random":
        random.shuffle(questions)
        return questions[:question_count]

    return questions
```

---

### Story 3.2: CBT Test Interface

**As a** user,
**I want** a clean, distraction-free test interface with question source information,
**So that** I can focus on answering questions and know which material each question comes from.

**Acceptance Criteria:**

**Given** I am on /test/{session_id}
**When** test page loads
**Then** I see:

**Header Section:**
- Study set name (e.g., "2024년 사회복지사 1급")
- Question counter: "1 / 20"
- Progress bar (filled based on answered questions)
- Timer (if time_limit set):
  - Countdown format: "02:45:30"
  - Warning color when < 10% time remaining

**Question Card:**
- **Source badge** (top-right):
  - "출처: 2024년 1회차 1교시" (study_material_name)
  - Clickable tooltip showing material details (optional)
- Passage (if exists):
  - Styled box with gray background
  - "다음 사례를 읽고 답하시오" label
- Question text:
  - Clear, large font
  - Support for formatting (bold, underline if from parsing)
- 5 options as clickable cards:
  - Number (①②③④⑤) + text
  - Hover effect
  - Selected: blue border + background
  - **Randomized order** (Fisher-Yates shuffle)

**Navigation Panel (Right Sidebar or Bottom):**
- Grid of question numbers (1-20)
- Colors:
  - Gray: not answered
  - Blue: answered
  - Yellow border: current question
- Click to jump to specific question

**Footer Buttons:**
- "이전" button (disabled on first question)
- "다음" button (or "제출하기" on last question)
- "시험 종료" button (danger, confirmation required)

**And** options are displayed in RANDOMIZED order
**And** shuffle mapping stored client-side:
```ts
// Example
{
  "q_001": {
    original: [0,1,2,3,4],
    shuffled: [2,0,4,1,3],
    selectedShuffled: 2,  // user clicked 3rd option
    selectedOriginal: 4   // which maps to original 5th option
  }
}
```

**Given** I select an option
**When** option is clicked
**Then**:
- Option is highlighted (blue border/background)
- Selection saved to local state
- Question marked as "answered" in navigator
- Can change answer before submission

**Given** I click "다음"
**When** on last question
**Then** button text changes to "제출하기"

**Given** I try to close browser/tab
**When** test is in progress
**Then** browser shows "시험이 진행 중입니다. 정말로 나가시겠습니까?"

**Given** time runs out (if timer enabled)
**When** timer reaches 00:00:00
**Then**:
- Auto-submit with current answers
- Alert: "시간이 종료되어 자동 제출되었습니다"

**Prerequisites:** Story 3.1A

**Technical Notes:**

**Page & Components:**
- Page: `app/test/[sessionId]/page.tsx`
- Components:
  - `TestHeader.tsx` (timer, progress, study set name)
  - `QuestionCard.tsx` (question display)
  - `OptionButton.tsx` (single option)
  - `QuestionNavigator.tsx` (grid)
  - `SourceBadge.tsx` (study material badge)

**State Management:**
```ts
// testStore.ts with Zustand
interface TestState {
  sessionId: string;
  questions: Question[];
  currentIndex: number;
  answers: Map<string, Answer>; // question_id -> answer
  shuffleMappings: Map<string, ShuffleMap>;
  timeRemaining: number | null;
  setAnswer: (questionId: string, selectedIndex: number) => void;
  goToQuestion: (index: number) => void;
  submitTest: () => Promise<void>;
}
```

**Shuffle Implementation:**
```ts
function shuffleOptions(options: string[], questionId: string): {
  shuffled: string[];
  mapping: number[];
} {
  const indices = [...Array(options.length).keys()];
  const shuffled = fisherYatesShuffle(indices);

  return {
    shuffled: shuffled.map(i => options[i]),
    mapping: shuffled
  };
}
```

**Auto-save:**
- Save answers to localStorage every selection
- On refresh: restore session state
- Warning if trying to leave page

**Timer:**
```ts
useEffect(() => {
  if (!timeRemaining) return;

  const interval = setInterval(() => {
    setTimeRemaining(prev => {
      if (prev <= 1) {
        handleAutoSubmit();
        return 0;
      }
      return prev - 1;
    });
  }, 1000);

  return () => clearInterval(interval);
}, [timeRemaining]);
```

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
- Save each answer to `user_answers` table **with study_material_id**
- Update `test_sessions` with score and completed_at
- Update Neo4j with user-concept relationships (MASTERED/WEAK_AT)

**And** response contains:
```json
{
  "data": {
    "session_id": "session_uuid",
    "score": 16,
    "total": 20,
    "percentage": 80,
    "time_taken_seconds": 1234,
    "by_material": [
      {
        "study_material_id": "mat_uuid_1",
        "study_material_name": "2024년 1회차 1교시",
        "score": 8,
        "total": 10,
        "percentage": 80
      },
      {
        "study_material_id": "mat_uuid_2",
        "study_material_name": "2024년 1회차 2교시",
        "score": 8,
        "total": 10,
        "percentage": 80
      }
    ]
  }
}
```

**And** I am redirected to /test/result/{session_id}

**Prerequisites:** Story 3.2

**Technical Notes:**

**Endpoint:**
- File: `api/v1/endpoints/test_sessions.py`
- Method: `POST /api/v1/test-sessions/{id}/submit`

**Database Updates:**
```sql
-- user_answers table (updated schema)
CREATE TABLE user_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES test_sessions(id) ON DELETE CASCADE,
  question_id TEXT NOT NULL,
  study_material_id UUID REFERENCES study_materials(id),
  selected_option INTEGER NOT NULL,
  correct_option INTEGER NOT NULL,
  is_correct BOOLEAN NOT NULL,
  answered_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_answers_session ON user_answers(session_id);
CREATE INDEX idx_user_answers_correct ON user_answers(is_correct, question_id);
```

**Scoring Logic:**
```python
async def score_test_session(session_id: str, answers: List[Answer]):
    # Get questions for session
    questions = await get_session_questions(session_id)

    # Score each answer
    results = []
    for answer in answers:
        question = questions[answer.question_id]
        is_correct = answer.selected_option == question.correct_option

        # Save to database
        await save_user_answer(
            session_id=session_id,
            question_id=answer.question_id,
            study_material_id=question.study_material_id,
            selected_option=answer.selected_option,
            correct_option=question.correct_option,
            is_correct=is_correct
        )

        results.append({
            "question_id": answer.question_id,
            "is_correct": is_correct,
            "study_material_id": question.study_material_id
        })

    # Calculate statistics
    total_score = sum(1 for r in results if r["is_correct"])
    percentage = (total_score / len(results)) * 100

    # Calculate by material
    by_material = group_by_material(results)

    # Update test session
    await update_test_session(
        session_id=session_id,
        score=total_score,
        percentage=percentage,
        status="completed",
        completed_at=datetime.now()
    )

    # Update Neo4j (for concept analysis)
    await update_user_concept_graph(user_id, results)

    return {
        "score": total_score,
        "total": len(results),
        "percentage": percentage,
        "by_material": by_material
    }
```

---

### Story 3.4: Test Result & Review Page

**As a** user,
**I want** to review my test results with detailed statistics by study material,
**So that** I can identify which materials I need to focus on.

**Acceptance Criteria:**

**Given** I am on /test/result/{session_id}
**When** page loads
**Then** I see:

**Summary Section:**
- Study set name
- Overall score: "16 / 20 (80%)"
- Performance badge: "우수" (≥80%), "양호" (60-79%), "노력필요" (<60%)
- Time taken: "20분 34초"
- Test date/time

**Statistics by Material:**
- Table or cards showing per-material breakdown:
  | 학습자료 | 정답 | 오답 | 정답률 |
  |---------|-----|------|--------|
  | 2024년 1회차 1교시 | 8 / 10 | 2 | 80% |
  | 2024년 1회차 2교시 | 8 / 10 | 2 | 80% |
  | **전체** | **16 / 20** | **4** | **80%** |

**Action Buttons:**
- "다시 풀기" - restart same test (new session, same config)
- "오답만 다시 풀기" - new session with only wrong questions
- "문제집으로 돌아가기" - navigate to study set detail

**Question Review Section:**
- Accordion or tabs: "전체 문제", "오답만 보기"
- Each question card shows:
  - **Header:**
    - Question number: "1번"
    - Source badge: "출처: 2024년 1회차 1교시"
    - Result icon: ✅ (correct) or ❌ (wrong)
  - **Content:**
    - Passage (if exists)
    - Question text
    - All 5 options with styling:
      - ✅ Green check + green border: correct answer
      - ❌ Red X + red border: user's wrong selection
      - Gray: other options
    - Explanation section (expandable or always visible)
  - **Footer:**
    - "이 문제 다시 풀기" button (optional)

**Given** test included multiple materials
**When** viewing results
**Then** I can:
- Filter questions by material (dropdown or tabs)
- See material-specific statistics
- Identify which material caused most errors

**Given** I click "오답만 다시 풀기"
**When** button is clicked
**Then**:
- New test session created with mode='wrong_only'
- Based on same study_set_id
- Includes only questions from this session where is_correct=false
- Redirected to test configuration or directly to test

**Given** I click "다시 풀기"
**When** button is clicked
**Then**:
- Same test configuration is used
- New session_id generated
- Questions may be in different order (if random mode)
- Redirected to test page

**Prerequisites:** Story 3.3

**Technical Notes:**

**Page:**
- File: `app/test/result/[sessionId]/page.tsx`
- Fetch from `GET /api/v1/test-sessions/{session_id}/result`

**API Response Example:**
```json
{
  "data": {
    "session_id": "session_uuid",
    "study_set_id": "set_uuid",
    "study_set_name": "2024년 사회복지사 1급",
    "mode": "random",
    "score": 16,
    "total": 20,
    "percentage": 80,
    "time_taken_seconds": 1234,
    "completed_at": "2025-01-15T11:30:00Z",
    "by_material": [
      {
        "study_material_id": "mat_uuid_1",
        "study_material_name": "2024년 1회차 1교시",
        "score": 8,
        "total": 10,
        "percentage": 80,
        "wrong_count": 2
      }
    ],
    "questions": [
      {
        "id": "q_001",
        "sequence": 1,
        "study_material_id": "mat_uuid_1",
        "study_material_name": "2024년 1회차 1교시",
        "passage": "다음 사례를 읽고...",
        "question_text": "위 사례에서...",
        "options": ["①...", "②...", "③...", "④...", "⑤..."],
        "correct_option": 3,
        "user_selected": 2,
        "is_correct": false,
        "explanation": "정답은 ③입니다. 해설..."
      }
    ]
  }
}
```

**Components:**
- `ResultSummary.tsx` - overall stats and badges
- `MaterialStatistics.tsx` - per-material breakdown table
- `QuestionReview.tsx` - question-by-question review
- `QuestionReviewCard.tsx` - single question display with result

**State Management:**
```ts
const [filterMaterial, setFilterMaterial] = useState<string | null>(null);
const [showOnlyWrong, setShowOnlyWrong] = useState(false);

const filteredQuestions = useMemo(() => {
  return result.questions.filter(q => {
    if (filterMaterial && q.study_material_id !== filterMaterial) return false;
    if (showOnlyWrong && q.is_correct) return false;
    return true;
  });
}, [result, filterMaterial, showOnlyWrong]);
```

**Retry Actions:**
```ts
// Retry same test
const handleRetry = async () => {
  const response = await fetch(`/api/v1/test-sessions`, {
    method: 'POST',
    body: JSON.stringify({
      study_set_id: result.study_set_id,
      material_ids: result.material_ids, // same as original
      mode: result.mode,
      question_count: result.question_count
    })
  });
  const { session_id } = await response.json();
  router.push(`/test/${session_id}`);
};

// Retry wrong only
const handleRetryWrong = async () => {
  const response = await fetch(`/api/v1/test-sessions`, {
    method: 'POST',
    body: JSON.stringify({
      study_set_id: result.study_set_id,
      mode: 'wrong_only',
      question_count: null
    })
  });
  const { session_id } = await response.json();
  router.push(`/test/${session_id}`);
};
```

---


---

### Story 3.5: Wrong Answer Retest Mode (오답 노트)

**As a** user,
**I want** to re-take only the questions I answered incorrectly,
**So that** I can focus on my weak points and ensure I don't make the same mistakes again.

**Acceptance Criteria:**

**Given** I am on the Test Selection page
**When** I select "오답 노트 (Retest)" mode
**Then** I see a list of my previous incorrect questions, grouped by Study Set or combined
**And** I can choose to start a retest session with these questions

**Given** I start a Retest Session
**When** I answer a question correctly
**Then** I get immediate feedback
**And** I am asked if I want to remove this question from my "Wrong Answer List" (Keep vs Remove)
**And** if "Remove" is selected, the `user_answers.is_correct` status for the *original* attempt remains false (for record), but the question is marked as "Mastered" in a new `mastery` table or flag.

**Given** I answer incorrect again
**When** the session ends
**Then** the question remains in my "Wrong Answer List" for future practice.

**Technical Notes:**
- New API endpoint: `POST /api/v1/tests/retest`
- Query `user_answers` where `is_correct = false` and `user_id = current_user`
- Distinct by `question_id` (if multiple wrong attempts)
- Frontend: Similar to Standard Test UI, but with "Mastered/Remove" option on result screen.

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
| **Total Stories** | 21 |
| **FR Coverage** | 8/8 (100%) |
| **Architecture Alignment** | ✅ Complete |

**Epic Breakdown:**
- Epic 1: Foundation & Authentication (6 stories)
- Epic 2: Study Set & Material Management (10 stories)
  - **Study Set CRUD:**
    - 2.1: Study Set Creation Form (metadata only)
    - 2.1A: Study Set List & Edit UI (view, edit, delete)
    - 2.2: Study Set CRUD API (all endpoints)
  - **Study Material Management:**
    - 2.3: Study Set Detail Page (view materials, status tracking)
    - 2.3A: Study Material Upload Modal (drag & drop UI)
    - 2.4: Study Material Upload API (file handling, background job trigger)
  - **PDF Parsing Pipeline:**
    - 2.5: Upstage Document Parse Integration
    - 2.6: Question Extraction & Intelligent Chunking
    - 2.7: Vector Embedding & Pinecone Storage
    - 2.8: Knowledge Graph Construction
- Epic 3: CBT Test Engine (5 stories)
  - **Test Configuration & Session:**
    - 3.1: Test Configuration Modal (material selection, mode, options)
    - 3.1A: Test Session Creation API (Pinecone query, session creation)
  - **Test Execution:**
    - 3.2: CBT Test Interface (timer, question navigation, source tracking)
    - 3.3: Answer Submission & Scoring (with material-level statistics)
    - 3.4: Test Result & Review Page (material breakdown, retry options)
- Epic 4: Analysis & Dashboard (4 stories)

---

_For implementation: Use the `create-story` workflow to generate individual story implementation plans from this epic breakdown._


---

## Epic 5: Payment & Subscription (MVP)

**Goal:** 사용자가 서비스 이용권(시즌패스)을 구매하고 권한을 획득한다.

**User Value:** 적절한 비용(1만원)을 지불하고 합격에 필요한 모든 AI 기능을 무제한으로 이용할 수 있다.

**FR Coverage:** N/A (Business Requirement)

### Story 5.1: Payment Gateway Integration (Toss Payments)

**As a** user,
**I want** to pay 10,000 KRW using my preferred payment method (Card, Easy Pay),
**So that** I can unlock the full service.

**Acceptance Criteria:**

**Given** I am a free user
**When** I try to access premium features (e.g., unlimited PDF uploads, Drill Mode) or after a trial period
**Then** a "Season Pass Purchase" modal/page appears
**And** it shows the price (10,000 KRW) and benefits

**Given** I click "Purchase"
**When** I complete the payment via Toss Payments widget
**Then** the payment is verified on the backend
**And** my user status becomes `is_paid = true`
**And** I see a success message: "시즌패스 구매가 완료되었습니다!"

**Technical Notes:**
- Use Toss Payments Widget SDK (Frontend)
- Backend verification API: `POST /api/v1/payments/confirm`
- Update `users` table: add `is_paid` (boolean), `paid_at` (timestamp), `payment_id` (text)
- Integration keys in `.env` (TOSS_CLIENT_KEY, TOSS_SECRET_KEY)

---
