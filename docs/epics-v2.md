# Certi-Graph - Epic Breakdown (v2.0)

**Author:** Q123
**Date:** 2026-01-08 (Updated from 2025-12-06)
**Version:** 2.0 - Implementation Aligned
**Project Level:** MVP
**Target Scale:** 사회복지사 1급 시험 대비 (연간 ~25,000명 응시자)

---

## Change Log

### v2.0 (2026-01-08)
- GCP Cloud SQL로 데이터베이스 변경 (Supabase 대체)
- VIP 패스 시스템 stories 추가
- API 경로 수정 (/api/v1 → /v1)
- Phase 2로 연기: Pinecone, Neo4j, GraphRAG
- MVP 우선순위 재조정

---

## Overview

This document provides the complete epic and story breakdown for Certi-Graph, aligned with Architecture v2.0.

**Total Epics:** 5
**Total Stories:** 29 (26 original + 3 VIP stories)
**MVP Stories:** 21
**Phase 2 Stories:** 8

---

## Functional Requirements Inventory (v2.0)

| FR ID | 기능 | 상세 | 우선순위 | 구현 단계 |
|-------|------|------|----------|----------|
| **FR-1** | PDF 업로드 | 사회복지사 1급 기출문제 PDF 업로드 | P0 | MVP |
| **FR-2** | 문서 파싱 | Upstage API 기반 문제/보기/해설/지문 분리 | P0 | MVP |
| **FR-3** | 지능형 청킹 | 지문 복제 전략, Question/Options/Answer/Explanation 스키마 | P0 | MVP |
| **FR-4** | Knowledge Graph 구축 | ~~Neo4j, LLM 자동 태깅~~ | P1 | Phase 2 |
| **FR-5** | CBT 모의고사 | 보기 랜덤 셔플링, 타이머, 채점 | P0 | MVP |
| **FR-6** | 오답 분석 | ~~GraphRAG 기반~~ 단순 통계 분석 | P1 | MVP/Phase 2 |
| **FR-7** | 기본 대시보드 | 학습 진도, 정답률 통계 | P1 | MVP |
| **FR-8** | 사용자 인증 | 이메일/소셜 로그인 (Clerk) | P0 | MVP |
| **FR-9** | VIP 패스 | 특별 권한 사용자 관리 | P0 | MVP |

---

## MVP Implementation Timeline

### Week 1-2: Foundation
- Epic 1: Foundation & Authentication (6 stories)
- Epic 5A: VIP System (3 stories)

### Week 3-4: Core Features
- Epic 2: Study Set & Material Management (6 stories - reduced)

### Week 5-6: Test Engine
- Epic 3: CBT Test Engine (5 stories)

### Week 7-8: Dashboard & Payment
- Epic 4: Basic Dashboard (2 stories - simplified)
- Epic 5B: Payment Integration (1 story)

---

## Epic Structure Overview

| Epic | 제목 | 사용자 가치 | Story Count | Priority |
|------|------|------------|-------------|----------|
| **Epic 1** | Foundation & Authentication | 사용자가 계정을 만들고 로그인할 수 있다 | 6 | P0 |
| **Epic 2** | Study Set & Material Management | 문제집을 만들고 PDF를 업로드하여 학습 자료를 추가 | 10 → 6 (MVP) | P0 |
| **Epic 3** | CBT Test Engine | 모의고사를 응시하고 채점받을 수 있다 | 5 | P0 |
| **Epic 4** | Analysis & Dashboard | 학습 진도와 기본 통계를 확인 | 4 → 2 (MVP) | P1 |
| **Epic 5** | VIP & Payment | VIP 권한 관리 및 서비스 이용권 구매 | 1 → 4 | P0 |

---

## Epic 1: Foundation & Authentication

**Goal:** 프로젝트 기반 인프라를 구축하고 사용자가 계정을 생성하여 로그인할 수 있도록 한다.

**User Value:** 사용자는 이메일 또는 소셜 계정으로 안전하게 로그인하여 개인화된 학습 경험을 시작할 수 있다.

**FR Coverage:** FR-8 (사용자 인증)

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
├── frontend/          # Next.js 14+
├── backend/           # FastAPI
├── shared/            # 공통 타입
└── docker-compose.yml # Local dev only
```

**Status:** ✅ COMPLETED

---

### Story 1.2: GCP Cloud SQL Database Setup (UPDATED)

**As a** developer,
**I want** GCP Cloud SQL PostgreSQL configured,
**So that** the application has a production-ready database.

**Acceptance Criteria:**

**Given** GCP project credentials
**When** I set up the database
**Then**:
1. GCP Cloud SQL instance is created (PostgreSQL 14)
2. Cloud SQL Proxy is configured (port 5433)
3. Database schema is created:
   ```sql
   -- Core tables
   CREATE TABLE users (
       id SERIAL PRIMARY KEY,
       clerk_user_id VARCHAR(255) UNIQUE NOT NULL,
       email VARCHAR(255) NOT NULL,
       is_vip BOOLEAN DEFAULT FALSE,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );

   CREATE TABLE subscriptions (
       id SERIAL PRIMARY KEY,
       user_id INTEGER REFERENCES users(id),
       certification_id VARCHAR(50),
       certification_name VARCHAR(255),
       exam_date DATE,
       status VARCHAR(50) DEFAULT 'active'
   );

   CREATE TABLE study_sets (
       id SERIAL PRIMARY KEY,
       user_id INTEGER REFERENCES users(id),
       name VARCHAR(255) NOT NULL,
       certification_id VARCHAR(50)
   );

   CREATE TABLE study_materials (
       id SERIAL PRIMARY KEY,
       study_set_id INTEGER REFERENCES study_sets(id) ON DELETE CASCADE,
       title VARCHAR(255),
       pdf_url TEXT,
       status VARCHAR(50) DEFAULT 'pending',
       total_questions INTEGER DEFAULT 0
   );
   ```
4. Environment variables configured:
   ```
   USE_CLOUD_SQL=true
   CLOUD_SQL_HOST=localhost
   CLOUD_SQL_PORT=5433
   CLOUD_SQL_DATABASE=certigraph
   CLOUD_SQL_CONNECTION_NAME=project:region:instance
   ```

**Technical Notes:**
- Use Cloud SQL Proxy for local development
- Production uses Cloud Run → Cloud SQL private IP
- Alembic for migrations

**Status:** ✅ COMPLETED (GCP 구현됨)

---

### Story 1.3: Frontend Authentication UI (Clerk)

**As a** user,
**I want** to sign up and log in using email or social accounts,
**So that** I can access personalized features.

**Acceptance Criteria:**

**Given** I visit the application
**When** I click "로그인"
**Then** I see Clerk's sign-in component with:
- Email/password option
- Google OAuth
- Kakao OAuth (if configured)

**Status:** ✅ COMPLETED

---

### Story 1.4: Clerk Auth Integration & User Sync

**As a** system,
**I want** to sync Clerk users with our database,
**So that** we can track user data and permissions.

**Acceptance Criteria:**

**Given** a user logs in via Clerk
**When** they first access the API
**Then**:
1. JWT is validated
2. User record is created/updated in Cloud SQL:
   - clerk_user_id
   - email
   - is_vip (check against VIP_CLERK_IDS)

**Status:** ✅ COMPLETED

---

### Story 1.5: Backend Auth Middleware (Clerk JWT)

**As a** backend system,
**I want** to verify Clerk JWTs on all protected endpoints,
**So that** only authenticated users can access resources.

**Acceptance Criteria:**

**Given** a request to `/v1/*` endpoints
**When** the request includes Authorization header
**Then**:
1. JWT is verified against Clerk JWKS
2. User context is extracted
3. 401 returned if invalid

**API Endpoints:**
```python
@router.get("/v1/users/me")  # Note: /v1 not /api/v1
async def get_current_user(current_user: CurrentUser = Depends(get_current_user)):
    return current_user
```

**Status:** ✅ COMPLETED

---

### Story 1.6: Protected Dashboard Layout

**As a** user,
**I want** to access my dashboard after login,
**So that** I can see my study materials and progress.

**Acceptance Criteria:**

**Given** I am logged in
**When** I visit /dashboard
**Then** I see:
- Navigation with user menu
- Study sets section
- Quick stats (if VIP, show crown icon)

**Status:** ✅ COMPLETED

---

## Epic 2: Study Set & Material Management (MVP Reduced)

**Goal:** 사용자가 문제집을 만들고 PDF를 업로드하여 학습 자료를 추가할 수 있다.

**User Value:** 사용자는 시험 대비를 위한 학습 자료를 체계적으로 관리할 수 있다.

**FR Coverage:** FR-1, FR-2, FR-3 (FR-4 deferred to Phase 2)

**MVP Stories:** 6 (Stories 2.1-2.6)
**Phase 2 Stories:** 4 (Stories 2.7-2.10)

---

### Story 2.1: Study Set Creation Form

**As a** user,
**I want** to create a new study set,
**So that** I can organize my study materials.

**Acceptance Criteria:**

**Given** I am on /dashboard/study-sets/new
**When** I fill in the form:
- Name (required)
- Description (optional)
- Certification (VIP users can select any, others use subscription)
**Then** a study set is created in Cloud SQL

**VIP Enhancement:**
- VIP users see certification dropdown
- Non-VIP users see locked certification from subscription

**Status:** ✅ COMPLETED

---

### Story 2.2: Study Set CRUD API (UPDATED)

**As a** frontend,
**I want** APIs to manage study sets,
**So that** users can create, read, update, delete their study sets.

**API Endpoints (Updated paths):**
```
POST   /v1/study-sets
GET    /v1/study-sets
GET    /v1/study-sets/{id}
PUT    /v1/study-sets/{id}
DELETE /v1/study-sets/{id}
```

**Database:** GCP Cloud SQL (not Supabase)

**VIP Logic:**
```python
# Check VIP status
if current_user.clerk_id in VIP_CLERK_IDS:
    # Allow any certification
else:
    # Validate subscription
```

**Status:** ✅ COMPLETED

---

### Story 2.3: Study Set Detail Page

**As a** user,
**I want** to view my study set details and materials,
**So that** I can manage my learning content.

**Status:** ✅ COMPLETED

---

### Story 2.4: Study Material Upload API (UPDATED)

**As a** user,
**I want** to upload PDF files to my study set,
**So that** I can add learning materials.

**API Endpoint:**
```
POST /v1/study-materials/{study_set_id}/upload
```

**Process:**
1. Upload PDF to GCP Cloud Storage (not Supabase Storage)
2. Create study_material record in Cloud SQL
3. Queue for processing

**Status:** 🚧 PARTIAL (upload works, processing not implemented)

---

### Story 2.5: Upstage Document Parse Integration

**As a** system,
**I want** to parse uploaded PDFs using Upstage API,
**So that** questions can be extracted.

**Status:** ❌ NOT STARTED (Critical MVP feature)

---

### Story 2.6: Question Extraction & Basic Storage

**As a** system,
**I want** to extract questions from parsed PDFs,
**So that** users can take tests.

**Simplified for MVP:**
- Store questions in Cloud SQL `questions` table
- No vector embeddings yet (Phase 2)
- Basic JSON structure for options

**Status:** ❌ NOT STARTED (Critical MVP feature)

---

### ~~Story 2.7: Vector Embedding & Pinecone Storage~~ (DEFERRED)

**Status:** 📅 DEFERRED TO PHASE 2

---

### ~~Story 2.8: Knowledge Graph Construction~~ (DEFERRED)

**Status:** 📅 DEFERRED TO PHASE 2

---

## Epic 3: CBT Test Engine

**Goal:** 사용자가 모의고사를 응시하고 채점받을 수 있다.

**User Value:** 실제 시험과 유사한 환경에서 연습할 수 있다.

**FR Coverage:** FR-5

**All 5 stories remain in MVP**

---

### Story 3.1: Test Configuration Modal

**As a** user,
**I want** to configure my test settings,
**So that** I can customize my practice experience.

**Status:** ❌ NOT STARTED

---

### Story 3.2: Test Session Creation API (UPDATED)

**As a** frontend,
**I want** to create test sessions,
**So that** users can start tests.

**API Endpoint:**
```
POST /v1/tests/start
```

**Status:** ❌ NOT STARTED

---

### Story 3.3: CBT Test Interface

**As a** user,
**I want** to take tests with randomized options,
**So that** I don't memorize answer positions.

**Key Feature:** Fisher-Yates shuffle on client-side

**Status:** ❌ NOT STARTED

---

### Story 3.4: Answer Submission & Scoring

**As a** user,
**I want** to submit answers and see results,
**So that** I know my performance.

**Status:** ❌ NOT STARTED

---

### Story 3.5: Test Result & Review Page

**As a** user,
**I want** to review my test results,
**So that** I can learn from mistakes.

**Status:** ❌ NOT STARTED

---

## Epic 4: Basic Dashboard (MVP Simplified)

**Goal:** 사용자가 기본적인 학습 통계를 확인할 수 있다.

**User Value:** 학습 진도를 한눈에 파악할 수 있다.

**FR Coverage:** FR-7 (FR-6 simplified)

**MVP Stories:** 2 (simplified)
**Phase 2 Stories:** 2 (advanced analytics)

---

### Story 4.1: Basic Statistics API

**As a** frontend,
**I want** to fetch basic user statistics,
**So that** I can display progress.

**API Endpoint:**
```
GET /v1/dashboard/stats
```

**Returns:**
- Total study sets
- Total questions uploaded
- Tests taken
- Average score

**Status:** ❌ NOT STARTED

---

### Story 4.2: Simple Dashboard UI

**As a** user,
**I want** to see my learning statistics,
**So that** I can track progress.

**Components:**
- Study set count card
- Question count card
- Test count card
- Average score card

**Status:** 🚧 PARTIAL (UI exists, needs data)

---

### ~~Story 4.3: GraphRAG Analysis~~ (DEFERRED)

**Status:** 📅 DEFERRED TO PHASE 2

---

### ~~Story 4.4: Advanced Progress Tracking~~ (DEFERRED)

**Status:** 📅 DEFERRED TO PHASE 2

---

## Epic 5: VIP System & Payment

**Goal:** VIP 사용자 관리 및 일반 사용자 결제 처리

**User Value:** VIP는 무제한 접근, 일반 사용자는 결제 후 접근

**FR Coverage:** FR-9 (VIP), Payment requirement

**Total Stories:** 4 (3 VIP + 1 Payment)

---

### Story 5.0: VIP User Management System (NEW)

**As a** system administrator,
**I want** to manage VIP users with special privileges,
**So that** specific users can access all features without payment.

**Acceptance Criteria:**

**Given** VIP_CLERK_IDS configuration
**When** a VIP user logs in
**Then**:
1. User is marked as is_vip in database
2. Subscription check returns VIP pass
3. All payment checks are bypassed

**Implementation:**
```python
# backend/app/api/v1/endpoints/subscriptions.py
VIP_CLERK_IDS = [
    "user_36T9Qa8HsuaM1fMjTisw4frRH1Z"  # myaji35@gmail.com
]

@router.get("/v1/subscriptions/my-subscriptions")
async def get_subscriptions(current_user: CurrentUser):
    if current_user.clerk_id in VIP_CLERK_IDS:
        return {
            "subscriptions": [{
                "id": "vip-pass",
                "certification_name": "VIP 무료 이용권",
                "exam_date": "2099-12-31",
                "is_vip": True
            }]
        }
```

**Status:** ✅ COMPLETED

---

### Story 5.0A: VIP User Interface (NEW)

**As a** VIP user,
**I want** to see my special status in the UI,
**So that** I know I have full access to all features.

**Acceptance Criteria:**

**Given** I am a VIP user
**When** I view any subscription-related UI
**Then** I see:
- Purple gradient background
- 👑 Crown icon
- "VIP 무료 이용권" text
- All certifications unlocked

**Implementation:**
```tsx
// frontend/src/app/dashboard/study-sets/new/page.tsx
{userSubscription?.id === 'vip-pass' ? (
  <div className="bg-gradient-to-r from-purple-50 to-pink-50
                  dark:from-purple-900/20 dark:to-pink-900/20
                  border-2 border-purple-300 dark:border-purple-700">
    <h3>👑 VIP 무료 이용권</h3>
    <select>{/* All certifications */}</select>
  </div>
) : (
  // Regular subscription UI
)}
```

**Status:** ✅ COMPLETED

---

### Story 5.0B: VIP Permission Bypass (NEW)

**As a** VIP user,
**I want** to bypass all limitations and payment requirements,
**So that** I can use all features freely.

**Acceptance Criteria:**

**Given** I am a VIP user
**When** I use any feature
**Then**:
- No PDF upload limits
- No test count limits
- No payment popups
- All certifications accessible

**Status:** ✅ COMPLETED

---

### Story 5.1: Payment Gateway Integration (Toss Payments)

**As a** regular user,
**I want** to purchase a season pass,
**So that** I can access all features.

**Acceptance Criteria:**

**Given** I am not a VIP user
**When** I click "Purchase Season Pass"
**Then**:
1. Toss Payments widget opens
2. Payment is processed (₩10,000)
3. Subscription is created in database

**API Endpoint:**
```
POST /v1/payments/confirm
```

**Status:** ❌ NOT STARTED (Can be post-MVP)

---

## Phase 2 Deferred Items

### Deferred Stories (8 total)

1. **Story 2.7:** Vector Embedding & Pinecone Storage
   - Reason: Simplify MVP, not critical for basic functionality
   - Impact: No semantic search, basic keyword search only

2. **Story 2.8:** Knowledge Graph Construction (Neo4j)
   - Reason: Complex implementation, not MVP critical
   - Impact: No concept relationships, no prerequisite tracking

3. **Story 2.9:** Advanced Question Analysis
   - Reason: Depends on Knowledge Graph
   - Impact: Basic statistics only

4. **Story 2.10:** Semantic Search
   - Reason: Depends on Pinecone
   - Impact: Exact match search only

5. **Story 4.3:** GraphRAG Analysis
   - Reason: Depends on Neo4j
   - Impact: No AI-powered insights

6. **Story 4.4:** Advanced Progress Tracking
   - Reason: Depends on Knowledge Graph
   - Impact: Basic progress only

7. **Story 4.5:** Weak Concept Identification
   - Reason: Depends on GraphRAG
   - Impact: Simple wrong answer tracking only

8. **Story 4.6:** Learning Path Recommendations
   - Reason: Depends on Knowledge Graph
   - Impact: No personalized recommendations

### Phase 2 Timeline (Post-MVP)

**Month 1 (Feb 2025):**
- Setup Pinecone account and indexes
- Implement vector embeddings
- Add semantic search

**Month 2 (Mar 2025):**
- Setup Neo4j AuraDB
- Build Knowledge Graph
- Implement concept relationships

**Month 3 (Apr 2025):**
- GraphRAG analysis engine
- Advanced analytics dashboard
- Learning path recommendations

---

## Implementation Status Summary

### MVP Progress (21 stories)

| Epic | Total | Done | In Progress | Not Started |
|------|-------|------|-------------|-------------|
| Epic 1 (Auth) | 6 | 6 | 0 | 0 |
| Epic 2 (Study) | 6 | 3 | 1 | 2 |
| Epic 3 (Test) | 5 | 0 | 0 | 5 |
| Epic 4 (Dashboard) | 2 | 0 | 1 | 1 |
| Epic 5 (VIP/Pay) | 4 | 3 | 0 | 1 |
| **TOTAL** | **23** | **12** | **2** | **9** |

**MVP Completion: 52%**

### Critical Path (Must Complete for MVP)

1. ⚠️ **Story 2.5:** Upstage OCR Integration
2. ⚠️ **Story 2.6:** Question Extraction
3. ⚠️ **Epic 3:** All test engine stories
4. ⚠️ **Story 4.1:** Basic statistics API

---

## Risk Assessment

### High Risk Items

1. **Upstage API Integration** (Story 2.5)
   - Risk: API accuracy < 90% for Korean PDFs
   - Mitigation: Test with real exam PDFs early
   - Fallback: Google Document AI

2. **Test Engine Complexity** (Epic 3)
   - Risk: 5 interdependent stories
   - Mitigation: Start early (Week 5)
   - Fallback: Simplify to basic Q&A

3. **Timeline** (8 weeks to launch)
   - Risk: 9 stories not started
   - Mitigation: Focus on critical path
   - Fallback: Launch without payment

### Low Risk Items

1. **VIP System** - ✅ Already implemented
2. **Basic Dashboard** - Simple statistics only
3. **GCP Infrastructure** - ✅ Already configured

---

## Recommendations

### Immediate Actions

1. **Week 1-2 (NOW):**
   - Complete Story 2.5 (Upstage OCR) - CRITICAL
   - Complete Story 2.6 (Question Extraction) - CRITICAL
   - Fix Story 2.4 (PDF processing pipeline)

2. **Week 3-4:**
   - Start Epic 3 (Test Engine) - 5 stories
   - Test with real exam PDFs

3. **Week 5-6:**
   - Complete Epic 3
   - Implement basic dashboard

4. **Week 7-8:**
   - Integration testing
   - Bug fixes
   - Payment (optional)

### Success Criteria for MVP

- ✅ Users can sign up and log in
- ✅ VIP users have full access
- ⚠️ Users can upload PDFs and extract questions
- ⚠️ Users can take randomized tests
- ⚠️ Users can see basic statistics
- ⭕ Payment integration (optional)

---

**Document Version:** 2.0
**Last Updated:** 2026-01-08
**Next Review:** Weekly during MVP development