# Story 1.3: Database & External Services Setup

**Status:** drafted

## Story

**As a** developer,
**I want** 외부 서비스(Supabase, Pinecone, Neo4j) 연결이 설정되어 있길,
**So that** 데이터 저장 기능을 구현할 수 있다.

## Acceptance Criteria

### AC1: Supabase Tables
```gherkin
Given 외부 서비스 계정이 생성되어 있을 때
When 데이터베이스 설정을 완료하면
Then Supabase에 다음 테이블이 생성된다:
  - users (id, clerk_user_id, email, created_at, updated_at)
  - study_sets (id, user_id, name, pdf_url, status, question_count, created_at)
  - test_sessions (id, user_id, study_set_id, score, total_questions, started_at, completed_at)
  - user_answers (id, session_id, question_id, selected_option, is_correct, answered_at)
```

### AC2: Pinecone Index
```gherkin
Given Pinecone 계정이 있을 때
When 인덱스를 생성하면
Then 다음 인덱스가 생성된다:
  - 인덱스명: certigraph-questions
  - Dimension: 1536 (text-embedding-3-small)
  - Metric: cosine
```

### AC3: Neo4j Instance
```gherkin
Given Neo4j AuraDB 계정이 있을 때
When 인스턴스를 생성하면
Then 연결 테스트가 성공한다
```

### AC4: Backend Connection Test
```gherkin
Given 모든 외부 서비스가 설정되었을 때
When 백엔드에서 연결 테스트를 실행하면
Then 각 서비스 연결이 성공한다:
  - Supabase: 테이블 조회 성공
  - Pinecone: 인덱스 조회 성공
  - Neo4j: 쿼리 실행 성공
```

## Tasks / Subtasks

**Note:** Migration files already exist in `backend/migrations/` (6 migration files ready for execution).

- [ ] Task 1: Supabase Setup (AC: 1) - **USER ACTION REQUIRED**
  - [ ] 1.1: Create Supabase project at https://supabase.com
  - [x] 1.2: SQL migration files exist (001-006_*.sql in backend/migrations/)
  - [ ] 1.3: Run migration files in Supabase SQL Editor
  - [ ] 1.4: Create 'pdfs' storage bucket (50MB limit, PDF only)
  - [ ] 1.5: Note SUPABASE_URL and SUPABASE_SERVICE_KEY

- [ ] Task 2: Pinecone Setup (AC: 2) - **USER ACTION REQUIRED**
  - [ ] 2.1: Create Pinecone account at https://pinecone.io
  - [ ] 2.2: Create certigraph-questions index (dim: 1536, metric: cosine)
  - [ ] 2.3: Note PINECONE_API_KEY

- [ ] Task 3: Neo4j Setup (AC: 3) - **USER ACTION REQUIRED**
  - [ ] 3.1: Create Neo4j AuraDB account at https://neo4j.com/cloud/
  - [ ] 3.2: Create free-tier instance
  - [ ] 3.3: Note NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD

- [ ] Task 4: Environment Variables (AC: 4) - **USER ACTION REQUIRED**
  - [ ] 4.1: Update backend/.env with actual service values
  - [ ] 4.2: Update frontend/.env.local with Supabase values

- [ ] Task 5: Connection Test (AC: 4)
  - [x] 5.1: Health endpoint exists in backend/app/main.py
  - [ ] 5.2: Test Supabase connection (requires valid credentials)
  - [ ] 5.3: Test Pinecone connection (requires valid credentials)
  - [ ] 5.4: Test Neo4j connection (requires valid credentials)

## Dev Notes

### Required User Actions

**This story requires external service account setup by the user:**

1. **Supabase** (https://supabase.com)
   - Create new project
   - Get `SUPABASE_URL` and `SUPABASE_SERVICE_KEY`
   - Run migration SQL to create tables

2. **Pinecone** (https://pinecone.io)
   - Create account (Serverless Free Tier available)
   - Create index: name=`certigraph-questions`, dimension=1536, metric=cosine
   - Get `PINECONE_API_KEY`

3. **Neo4j AuraDB** (https://neo4j.com/cloud/platform/aura-graph-database/)
   - Create free-tier instance
   - Get `NEO4J_URI`, `NEO4J_USER`, `NEO4J_PASSWORD`

### SQL Migration Files (Pre-existing)

**Location:** `backend/migrations/`

Migration files are already prepared:
1. `001_initial_schema.sql` - users, study_sets, test_sessions, user_answers tables
2. `002_add_pdf_hash_and_questions.sql` - PDF hash tracking
3. `003_add_exam_metadata.sql` - Exam metadata fields
4. `004_add_learning_status.sql` - Learning progress tracking
5. `005_add_free_trial_limits.sql` - Trial usage limits
6. `006_add_certification_subscriptions.sql` - Subscription system

**To apply:** Run each SQL file in order in Supabase SQL Editor

### Environment Variables Update

After setting up services, update these files:

**backend/.env:**
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=eyJ...your-actual-service-key
PINECONE_API_KEY=your-pinecone-api-key
NEO4J_URI=neo4j+s://your-instance.databases.neo4j.io
NEO4J_USER=neo4j
NEO4J_PASSWORD=your-neo4j-password
```

**frontend/.env.local:**
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...your-anon-key
```

### Testing Standards
- Each service connection should be testable independently
- Connection tests should fail gracefully with clear error messages
- Use health check endpoints for service verification

### References

- [Architecture: Database Schema](docs/architecture.md)
- [Epic 1: Project Foundation](docs/epics.md)

## Dev Agent Record

### Context Reference
- Story created by dev-story workflow
- Epic 1, Story 3 - External services setup

### Agent Model Used
Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References
(To be filled during implementation)

### Completion Notes List
(To be filled after implementation)

### File List
(To be filled after implementation)

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-12-18 | Story created with setup guide | Claude Opus 4.5 |
