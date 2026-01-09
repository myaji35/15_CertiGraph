# Parallel Test Execution Groups

## Overview

This document organizes the 450+ test scenarios into execution groups optimized for parallel testing. Tests are grouped based on:
- **Dependency analysis**: Tests that share state or must run sequentially are grouped together
- **Resource isolation**: Tests accessing the same database records, user sessions, or external services
- **Page/Component isolation**: Tests on the same page can run in parallel if they test different features

## Execution Strategy

- **Parallel Groups**: Can run simultaneously across different workers
- **Sequential Groups**: Tests within these groups must run in order
- **Worker Recommendation**: 4-8 workers for optimal performance

---

## Group 1: Authentication & User Management (Isolated)

**Parallelizable**: YES (each test uses different user accounts)
**Worker Count**: 2-3
**Execution Time**: ~5-8 minutes

### Subgroup 1A: Sign Up Flow (Sequential)
```typescript
// tests/auth/signup.spec.ts
- AUTH-001: New user signup with Clerk
- AUTH-002: Email verification flow
- AUTH-003: Duplicate email prevention
- AUTH-004: Invalid email format handling
```

### Subgroup 1B: Login Flow (Parallel with 1A)
```typescript
// tests/auth/login.spec.ts
- AUTH-005: Existing user login
- AUTH-006: Incorrect password handling
- AUTH-007: Account lockout after failed attempts
- AUTH-008: Session persistence after browser close
```

### Subgroup 1C: Session Management (Parallel with 1A, 1B)
```typescript
// tests/auth/session.spec.ts
- AUTH-009: Session timeout after inactivity
- AUTH-010: Multi-device login handling
- AUTH-011: Logout clears session data
```

**Dependencies**: None
**Test Data**: Dedicated test users (test_signup_001@example.com, test_login_001@example.com, etc.)

---

## Group 2: Certification Discovery (Highly Parallelizable)

**Parallelizable**: YES (read-only operations)
**Worker Count**: 4-6
**Execution Time**: ~3-5 minutes

### Subgroup 2A: Certification List
```typescript
// tests/certifications/list.spec.ts
- CERT-001: Display all certifications
- CERT-002: Filter by category (국가기술, 국가전문, 민간, 국제)
- CERT-003: Filter by exam month
- CERT-004: Filter by year (2025, 2026)
- CERT-005: Sort by name, popularity, upcoming exam
```

### Subgroup 2B: Certification Detail
```typescript
// tests/certifications/detail.spec.ts
- CERT-006: View certification detail page
- CERT-007: Display exam schedule (2025)
- CERT-008: Display exam schedule (2026)
- CERT-009: Show passing criteria and exam subjects
- CERT-010: Website link navigation
```

### Subgroup 2C: Calendar View
```typescript
// tests/certifications/calendar.spec.ts
- CERT-011: Monthly calendar view (2025/01)
- CERT-012: Monthly calendar view (2026/12)
- CERT-013: Upcoming exams widget (next 30 days)
- CERT-014: Upcoming exams widget (next 90 days)
```

**Dependencies**: Requires certification seed data
**Test Data**: Static certification data from `certification_scraper.py`

---

## Group 3: Subscription & Payment (Sequential)

**Parallelizable**: NO (uses Toss Payments sandbox, may have rate limits)
**Worker Count**: 1
**Execution Time**: ~10-15 minutes

### Subgroup 3A: Free Trial Enforcement (Sequential)
```typescript
// tests/subscription/free-trial.spec.ts
- SUB-001: New user starts test session 1/2 (free)
- SUB-002: User completes test session 1
- SUB-003: User starts test session 2/2 (free)
- SUB-004: User completes test session 2
- SUB-005: Paywall appears on test session 3
- SUB-006: Free trial counter resets per PDF
```

### Subgroup 3B: Payment Flow (Sequential - depends on 3A paywall)
```typescript
// tests/subscription/payment.spec.ts
- PAY-001: Select certification and exam date
- PAY-002: View season pass details (₩10,000, valid until exam date)
- PAY-003: Click "시험패스 구매하기"
- PAY-004: Toss Payments widget loads
- PAY-005: Enter test card (5272836251672858)
- PAY-006: Payment success callback
- PAY-007: Subscription created in database
- PAY-008: User can now take unlimited tests
```

### Subgroup 3C: Payment Edge Cases (Sequential)
```typescript
// tests/subscription/payment-edge-cases.spec.ts
- PAY-009: Payment failure (insufficient funds card)
- PAY-010: Payment failure (invalid card)
- PAY-011: Payment cancellation by user
- PAY-012: Duplicate subscription prevention
- PAY-013: Subscription expiration after exam date
```

**Dependencies**:
- Free trial tests must run before payment tests
- Each test must use different user accounts
- Requires Toss Payments sandbox credentials

**Test Data**:
- Test users: test_freetrial_001@example.com, test_payment_001@example.com
- Test cards: Success (5272836251672858), Fail (4000000000000002)

---

## Group 4: Study Set Management (Partially Parallel)

**Parallelizable**: PARTIAL (create/read parallel, update/delete sequential per user)
**Worker Count**: 3-4
**Execution Time**: ~8-12 minutes

### Subgroup 4A: Study Set Creation (Parallel)
```typescript
// tests/study-sets/create.spec.ts
- STUDY-001: Create study set for 정보처리기사 (user A)
- STUDY-002: Create study set for SQLD (user B)
- STUDY-003: Create study set for 사회복지사 1급 (user C)
- STUDY-004: Create multiple study sets for same cert (user D)
```

### Subgroup 4B: Study Set Listing (Parallel with 4A)
```typescript
// tests/study-sets/list.spec.ts
- STUDY-005: Display user's study sets (user A)
- STUDY-006: Empty state for new user (user E)
- STUDY-007: Sort by creation date (user A)
- STUDY-008: Filter by certification (user D - has multiple)
```

### Subgroup 4C: Study Set Update/Delete (Sequential per user)
```typescript
// tests/study-sets/update-delete.spec.ts
- STUDY-009: Rename study set (user A)
- STUDY-010: Delete study set (user A)
- STUDY-011: Cannot delete study set with active tests (user B)
```

**Dependencies**:
- Subgroup 4C depends on 4A (needs existing study sets)
- Each subgroup can use different users for parallel execution

**Test Data**:
- Test users: test_studyset_A@example.com through test_studyset_E@example.com
- Test PDFs: small_2mb.pdf, medium_15mb.pdf

---

## Group 5: PDF Upload & Processing (Sequential per user, Parallel across users)

**Parallelizable**: PARTIAL (Upstage OCR API may have rate limits)
**Worker Count**: 2-3
**Execution Time**: ~15-20 minutes (OCR processing is slow)

### Subgroup 5A: PDF Upload Validation (Parallel)
```typescript
// tests/pdf/upload-validation.spec.ts
- PDF-001: Upload valid PDF (2MB) - user A
- PDF-002: Upload valid PDF (15MB) - user B
- PDF-003: Reject PDF > 50MB - user C
- PDF-004: Reject non-PDF file (.docx) - user D
- PDF-005: Reject corrupted PDF - user E
```

### Subgroup 5B: Upstage OCR Processing (Sequential per user)
```typescript
// tests/pdf/ocr-processing.spec.ts
- PDF-006: OCR extracts text correctly (user A, small_2mb.pdf)
- PDF-007: OCR handles images (captions with GPT-4o) (user A)
- PDF-008: OCR handles tables (user B, medium_15mb.pdf)
- PDF-009: OCR timeout handling (user C, large_48mb.pdf)
```

### Subgroup 5C: Markdown Conversion (Sequential - depends on 5B)
```typescript
// tests/pdf/markdown-conversion.spec.ts
- PDF-010: Convert OCR result to markdown (user A)
- PDF-011: Intelligent chunking with 지문 복제 (user A)
- PDF-012: Extract question-answer pairs (user B)
- PDF-013: Store chunks in vector DB (Pinecone) (user A)
```

**Dependencies**:
- 5B depends on 5A (successful upload)
- 5C depends on 5B (OCR completion)
- Upstage API rate limits: max 3 concurrent requests

**Test Data**:
- Test PDFs: small_2mb.pdf, medium_15mb.pdf, large_48mb.pdf, corrupted.pdf, test.docx
- Test users: test_pdf_A@example.com through test_pdf_E@example.com

---

## Group 6: Test Taking (Sequential per user, Parallel across users)

**Parallelizable**: PARTIAL (each user's test session is isolated)
**Worker Count**: 4-5
**Execution Time**: ~12-18 minutes

### Subgroup 6A: Test Session Start (Parallel)
```typescript
// tests/test-taking/start-session.spec.ts
- TEST-001: Start test session (user A, study set 1)
- TEST-002: Display D-Day until exam (user A)
- TEST-003: Display 과락 warning (40% per subject) (user A)
- TEST-004: Load first question with shuffled options (user B)
```

### Subgroup 6B: Answer Submission (Sequential per user)
```typescript
// tests/test-taking/answer-submission.spec.ts
- TEST-005: Select answer option (user A, Q1)
- TEST-006: Submit answer (user A, Q1)
- TEST-007: Auto-advance to next question (user A, Q2)
- TEST-008: Answer shuffling (same Q different order) (user B, Q1)
```

### Subgroup 6C: Test Completion (Sequential per user)
```typescript
// tests/test-taking/completion.spec.ts
- TEST-009: Answer all questions (user A)
- TEST-010: Submit final answer (user A)
- TEST-011: Calculate total score (user A)
- TEST-012: Calculate per-subject scores (user A)
- TEST-013: Check 과락 (cutoff) per subject (user A)
- TEST-014: Display pass/fail result (user A)
```

### Subgroup 6D: Edge Cases (Parallel with 6A-6C, different users)
```typescript
// tests/test-taking/edge-cases.spec.ts
- TEST-015: Session timeout after 30min inactivity (user C)
- TEST-016: Browser refresh preserves session (user D)
```

**Dependencies**:
- 6B depends on 6A (session started)
- 6C depends on 6B (answers submitted)
- Each user must run A→B→C sequentially
- Different users (A, B, C, D) can run in parallel

**Test Data**:
- Test users: test_exam_A@example.com through test_exam_D@example.com
- Test study sets with known question counts

---

## Group 7: Test Results & GraphRAG Analysis (Sequential per user)

**Parallelizable**: PARTIAL (GraphRAG AI calls may be rate-limited)
**Worker Count**: 2-3
**Execution Time**: ~10-15 minutes

### Subgroup 7A: Result Display (Sequential)
```typescript
// tests/results/display.spec.ts
- RESULT-001: Display overall score (user A)
- RESULT-002: Display per-subject breakdown (user A)
- RESULT-003: Display 과락 status (user A)
- RESULT-004: Display time spent per question (user A)
```

### Subgroup 7B: GraphRAG Analysis (Sequential - depends on 7A)
```typescript
// tests/results/graphrag-analysis.spec.ts
- RESULT-005: Trigger GraphRAG analysis (user A)
- RESULT-006: Extract weak concepts from wrong answers (user A)
- RESULT-007: Distinguish concept gap vs careless mistake (user A)
- RESULT-008: Generate concept prerequisite graph (user A)
- RESULT-009: Store analysis in Neo4j (user A)
```

### Subgroup 7C: Review Mode (Parallel with 7B, different user)
```typescript
// tests/results/review.spec.ts
- RESULT-010: View all questions with answers (user B)
- RESULT-011: Filter by correct/incorrect (user B)
- RESULT-012: View AI explanation for wrong answer (user B)
```

**Dependencies**:
- 7B depends on 7A (results displayed)
- GraphRAG API rate limits: max 2 concurrent requests
- User A and User B can run in parallel

**Test Data**:
- Test users with completed test sessions
- Pre-seeded incorrect answers for analysis

---

## Group 8: Knowledge Graph 3D Visualization (Parallel)

**Parallelizable**: YES (read-only, different users)
**Worker Count**: 3-4
**Execution Time**: ~6-10 minutes

### Subgroup 8A: Initial Render
```typescript
// tests/knowledge-graph/render.spec.ts
- KG-001: Load 3D brain map (user A)
- KG-002: Display nodes for all concepts (user A)
- KG-003: Color coding (Green=mastered, Red=weak, Gray=untested) (user A)
- KG-004: Display edges (prerequisite relationships) (user A)
```

### Subgroup 8B: Interaction (Parallel with 8A, different user)
```typescript
// tests/knowledge-graph/interaction.spec.ts
- KG-005: Click node to view concept details (user B)
- KG-006: Drill down to weak concept questions (user B)
- KG-007: Start practice test for weak concepts (user B)
- KG-008: Rotate/zoom 3D graph (user B)
```

### Subgroup 8C: Dynamic Updates (Parallel with 8A, 8B, different user)
```typescript
// tests/knowledge-graph/updates.spec.ts
- KG-009: Node color changes after test completion (user C)
- KG-010: New edges appear as concepts are learned (user C)
- KG-011: Graph reflects real-time progress (user C)
```

**Dependencies**:
- User C must have completed a test (for dynamic updates)
- Users A, B, C use different accounts (parallel execution)

**Test Data**:
- Users with different knowledge states (mastered, weak, untested)

---

## Group 9: Dashboard & Analytics (Parallel)

**Parallelizable**: YES (read-only)
**Worker Count**: 3-4
**Execution Time**: ~5-8 minutes

### Subgroup 9A: Study Progress
```typescript
// tests/dashboard/progress.spec.ts
- DASH-001: Display total tests taken (user A)
- DASH-002: Display average score trend (user A)
- DASH-003: Display study streak (days) (user A)
- DASH-004: Display D-Day countdown (user A)
```

### Subgroup 9B: Exam Prediction (Parallel with 9A, different user)
```typescript
// tests/dashboard/prediction.spec.ts
- DASH-005: Calculate passing probability (user B)
- DASH-006: Display weak subjects (user B)
- DASH-007: Recommend study focus areas (user B)
```

### Subgroup 9C: Cohort Statistics (Parallel with 9A, 9B, different user)
```typescript
// tests/dashboard/cohort-stats.spec.ts
- DASH-008: Display cohort size (user C)
- DASH-009: Display my rank in cohort (user C)
- DASH-010: Display cohort average score (user C)
```

**Dependencies**:
- Users must have test history
- Cohort stats require multiple users in same cohort

**Test Data**:
- Pre-seeded test results for analytics
- Users in same cohort: test_cohort_001@example.com through test_cohort_010@example.com

---

## Group 10: Certification Badges (Parallel)

**Parallelizable**: YES (read-only, SVG generation)
**Worker Count**: 2-3
**Execution Time**: ~3-5 minutes

### Subgroup 10A: Badge Generation
```typescript
// tests/badges/generation.spec.ts
- BADGE-001: Generate badge for 정보처리기사 (flat style)
- BADGE-002: Generate badge for SQLD (gradient style)
- BADGE-003: Generate badge for 2025 (default theme)
- BADGE-004: Generate badge for 2026 (custom theme)
```

### Subgroup 10B: Badge Embedding (Parallel with 10A)
```typescript
// tests/badges/embedding.spec.ts
- BADGE-005: Embed badge in blog post (markdown)
- BADGE-006: Badge caching (304 Not Modified)
```

**Dependencies**: None (stateless API)
**Test Data**: Certification IDs, years, styles, themes

---

## Group 11: API Integration Tests (Parallel)

**Parallelizable**: YES (stateless API endpoints)
**Worker Count**: 4-6
**Execution Time**: ~5-8 minutes

### Subgroup 11A: Certification API
```typescript
// tests/api/certifications.spec.ts
- API-001: GET /certifications (list)
- API-002: GET /certifications/:id (detail)
- API-003: GET /certifications/calendar/:year/:month
- API-004: GET /certifications/:id/nearest-exam-date
```

### Subgroup 11B: Study Set API (Parallel with 11A)
```typescript
// tests/api/study-sets.spec.ts
- API-005: POST /study-sets (create)
- API-006: GET /study-sets (list)
- API-007: PUT /study-sets/:id (update)
- API-008: DELETE /study-sets/:id (delete)
```

### Subgroup 11C: Test API (Parallel with 11A, 11B)
```typescript
// tests/api/tests.spec.ts
- API-009: POST /tests/start (start session)
- API-010: POST /tests/:id/answers (submit answer)
- API-011: POST /tests/:id/complete (complete test)
- API-012: GET /tests/:id/results (get results)
```

### Subgroup 11D: Admin API (Parallel with 11A-11C)
```typescript
// tests/api/admin.spec.ts
- API-013: GET /admin/users (list all users)
- API-014: GET /admin/users/:email/study-sets
- API-015: POST /admin/users/:id/force-subscription
```

**Dependencies**: None (API tests are isolated)
**Test Data**: Test API keys, test users

---

## Group 12: Performance Tests (Sequential)

**Parallelizable**: NO (measures system performance under load)
**Worker Count**: 1
**Execution Time**: ~10-15 minutes

### Subgroup 12A: Load Testing
```typescript
// tests/performance/load.spec.ts
- PERF-001: 100 concurrent users browsing certifications
- PERF-002: 50 concurrent PDF uploads
- PERF-003: 200 concurrent test sessions
```

### Subgroup 12B: Response Time
```typescript
// tests/performance/response-time.spec.ts
- PERF-004: Homepage load < 2s (p95)
- PERF-005: Certification list < 1s (p95)
- PERF-006: Test question load < 500ms (p95)
- PERF-007: GraphRAG analysis < 10s (p95)
```

**Dependencies**: Must run in isolation (not parallel with other tests)

---

## Group 13: Security Tests (Parallel)

**Parallelizable**: YES (different attack vectors)
**Worker Count**: 2-3
**Execution Time**: ~5-8 minutes

### Subgroup 13A: Authentication Security
```typescript
// tests/security/auth.spec.ts
- SEC-001: Prevent SQL injection in login
- SEC-002: Prevent XSS in user input
- SEC-003: Enforce rate limiting on login
```

### Subgroup 13B: Authorization Security (Parallel with 13A)
```typescript
// tests/security/authorization.spec.ts
- SEC-004: User A cannot access user B's study sets
- SEC-005: Non-admin cannot access /admin/* endpoints
- SEC-006: Expired session cannot access protected routes
```

**Dependencies**: Requires different user accounts
**Test Data**: Test users with different roles

---

## Group 14: Cross-Browser Tests (Parallel)

**Parallelizable**: YES (different browsers)
**Worker Count**: 3 (Chromium, Firefox, WebKit)
**Execution Time**: ~15-20 minutes

```typescript
// All critical user journeys run on 3 browsers
- CUJ-001: Complete new user journey (Chromium)
- CUJ-001: Complete new user journey (Firefox)
- CUJ-001: Complete new user journey (WebKit)
```

**Dependencies**: Requires all 3 browser drivers installed

---

## Execution Plan

### Local Development (4 workers)
```bash
# Run isolated groups in parallel
npx playwright test tests/certifications/ tests/badges/ tests/api/ tests/security/ --workers=4

# Run sequential groups one at a time
npx playwright test tests/subscription/ --workers=1
npx playwright test tests/pdf/ --workers=2
npx playwright test tests/test-taking/ --workers=4
```

### CI/CD Pipeline (8 workers)
```yaml
# Stage 1: Fast parallel tests (5-10 min)
- Group 1: Auth (workers=2)
- Group 2: Certifications (workers=4)
- Group 10: Badges (workers=2)

# Stage 2: Medium parallel tests (10-15 min)
- Group 4: Study Sets (workers=3)
- Group 8: Knowledge Graph (workers=3)
- Group 9: Dashboard (workers=2)

# Stage 3: Slow sequential tests (20-30 min)
- Group 3: Subscription (workers=1)
- Group 5: PDF Upload (workers=2)
- Group 6: Test Taking (workers=4)
- Group 7: Results (workers=2)

# Stage 4: Performance & Cross-browser (30-40 min)
- Group 12: Performance (workers=1)
- Group 14: Cross-browser (workers=3)
```

### Nightly Full Run (All 450+ tests)
```bash
# Estimated total time: 60-90 minutes with 8 workers
npx playwright test --workers=8
```

---

## Playwright Configuration for Parallel Execution

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',

  // Global timeout
  timeout: 60 * 1000, // 60s per test

  // Retries
  retries: process.env.CI ? 2 : 1,

  // Parallel workers
  workers: process.env.CI ? 8 : 4,

  // Fully parallel mode (tests in different files run in parallel)
  fullyParallel: true,

  // Fail fast
  maxFailures: process.env.CI ? 10 : 3,

  use: {
    baseURL: 'http://localhost:3030',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  // Projects (browsers)
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
  ],

  // Test match patterns
  testMatch: [
    '**/tests/**/*.spec.ts',
  ],

  // Ignore patterns (sequential groups)
  testIgnore: [
    // Run these separately with workers=1
    '**/tests/subscription/**',
    '**/tests/performance/**',
  ],
});
```

---

## Test Data Isolation Strategy

### Dedicated User Accounts Per Group
```typescript
// tests/fixtures/test-users.ts
export const TEST_USERS = {
  auth: {
    signup: 'test_signup_001@example.com',
    login: 'test_login_001@example.com',
  },
  studySets: {
    userA: 'test_studyset_A@example.com',
    userB: 'test_studyset_B@example.com',
    userC: 'test_studyset_C@example.com',
  },
  payment: {
    freeTrial: 'test_freetrial_001@example.com',
    paidUser: 'test_payment_001@example.com',
  },
  pdf: {
    userA: 'test_pdf_A@example.com',
    userB: 'test_pdf_B@example.com',
  },
  testTaking: {
    userA: 'test_exam_A@example.com',
    userB: 'test_exam_B@example.com',
  },
};
```

### Database Cleanup Strategy
```typescript
// tests/fixtures/cleanup.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  // Auto-cleanup after each test
  isolatedUser: async ({ page }, use) => {
    const userId = `test_${Date.now()}@example.com`;

    // Setup: Create user
    await createTestUser(userId);

    // Run test
    await use(userId);

    // Teardown: Delete user and all related data
    await deleteTestUser(userId);
  },
});
```

---

## Summary

**Total Test Count**: 450+ scenarios
**Execution Groups**: 14 groups
**Parallel Groups**: 11 groups (can run simultaneously)
**Sequential Groups**: 3 groups (must run in isolation)

**Estimated Execution Time**:
- Local (4 workers): 60-90 minutes
- CI/CD (8 workers): 40-60 minutes
- Nightly (8 workers, all browsers): 90-120 minutes

**Key Principles**:
1. **Isolation**: Each test uses dedicated user accounts and test data
2. **Parallelization**: Read-only tests run in parallel, write tests are isolated per user
3. **Dependencies**: Explicit dependency chains within sequential groups
4. **Resource Management**: Respect external API rate limits (Upstage, GraphRAG, Toss)
5. **Fail Fast**: Stop after 3-10 failures to save CI/CD time
