# Test Parallelization Strategy - CertiGraph

**Document Version:** 1.0
**Created:** 2026-01-05
**Author:** Test Architecture Team
**Total Test Cases:** 312 (198 Unit, 72 Integration, 42 E2E)

---

## Executive Summary

This document defines a comprehensive parallel test execution strategy for the CertiGraph application, covering 312 test scenarios across unit, integration, and E2E levels. The strategy optimizes test execution time while maintaining test reliability and data integrity through careful isolation and dependency management.

**Key Metrics:**
- **Serial Execution Estimate:** ~180 minutes
- **Parallel Execution Estimate:** ~25-35 minutes (85% reduction)
- **Recommended Workers:** 8-12 parallel workers
- **Database Strategy:** Isolated test databases per worker
- **Risk Level:** Medium (requires careful resource isolation)

---

## Table of Contents

1. [Parallel Execution Groups](#1-parallel-execution-groups)
2. [Sequential Execution Groups](#2-sequential-execution-groups)
3. [Resource Isolation Strategy](#3-resource-isolation-strategy)
4. [Dependency Mapping](#4-dependency-mapping)
5. [Execution Plan](#5-execution-plan)
6. [Playwright Configuration](#6-playwright-configuration)
7. [Risk Assessment](#7-risk-assessment)
8. [Monitoring & Debugging](#8-monitoring--debugging)

---

## 1. Parallel Execution Groups

### Group P1: Frontend Component Unit Tests (Fully Parallel)
**Test Count:** 68 tests
**Estimated Duration:** 3-5 minutes
**Parallelization Factor:** 8 workers
**Dependencies:** None

#### Tests Included:
- `FE-UNIT-001` to `FE-UNIT-068`
  - NotionCard (8 tests)
  - NotionStatCard (8 tests)
  - NotionPageHeader (8 tests)
  - NotionEmptyState (5 tests)
  - NotionLayout (11 tests)
  - QuestionCard (8 tests)
  - QuestionNavigator (6 tests)
  - TestStartModal (6 tests)
  - PdfUploader (8 tests)

#### Rationale:
- Pure component rendering tests with no external dependencies
- No shared state between tests
- No API calls or database access
- Each test uses isolated React Testing Library render contexts
- No file system operations

#### Isolation Strategy:
```javascript
// Each test runs in isolated memory space
describe.concurrent('NotionCard Tests', () => {
  test.concurrent('FE-UNIT-001', async () => { /* ... */ });
  test.concurrent('FE-UNIT-002', async () => { /* ... */ });
});
```

---

### Group P2: Backend Service Unit Tests (Fully Parallel)
**Test Count:** 130 tests
**Estimated Duration:** 5-8 minutes
**Parallelization Factor:** 10 workers
**Dependencies:** None (mocked dependencies)

#### Tests Included:
- `BE-UNIT-001` to `BE-UNIT-039`
  - PDF Hash Service (5 tests)
  - Question Extractor (8 tests)
  - Scoring Service (6 tests)
  - Weakness Analysis (5 tests)
  - Session Management (6 tests)
  - Config Management (4 tests)
  - Security/Auth (5 tests)

#### Rationale:
- Pure functions with mocked external dependencies
- No database writes (uses in-memory mocks)
- No file system writes (mocked)
- Stateless service logic
- Fast execution (<100ms per test)

#### Isolation Strategy:
```python
# pytest-xdist configuration
# Each test uses isolated fixtures
@pytest.fixture(scope="function")
def isolated_service():
    return ServiceClass()

# Run with: pytest -n 10 tests/unit/
```

---

### Group P3: Read-Only API Integration Tests (Mostly Parallel)
**Test Count:** 24 tests
**Estimated Duration:** 4-6 minutes
**Parallelization Factor:** 6 workers
**Dependencies:** Read-only test database

#### Tests Included:
- `INT-002`: GET /api/v1/study-sets (list)
- `INT-003`: GET /api/v1/study-sets/{id} (detail)
- `INT-008`: GET /api/v1/tests/result/{id}
- Authentication verification tests (INT-014, INT-015)
- Analysis read operations (INT-019, INT-020)

#### Rationale:
- Only reads from database, no mutations
- Can share read-only fixture data
- No data contamination between tests
- Safe to run concurrently

#### Isolation Strategy:
- Use database transaction rollback after each test
- Pre-seed read-only fixture data before test suite
- Each worker connects to same database but different transactions

```python
@pytest.fixture(scope="session")
def readonly_db_data():
    """Seed once, used by all read tests"""
    seed_users()
    seed_study_sets()
    yield
    # No cleanup needed

@pytest.fixture(scope="function")
def db_transaction(readonly_db_data):
    """Each test runs in isolated transaction"""
    with db.begin():
        yield
        # Auto-rollback on exit
```

---

### Group P4: Independent E2E User Journeys (Parallel with User Isolation)
**Test Count:** 28 tests
**Estimated Duration:** 12-15 minutes
**Parallelization Factor:** 4 workers
**Dependencies:** Isolated user accounts per worker

#### Tests Included:
- User onboarding flows (different email addresses)
- Dashboard navigation (isolated sessions)
- Read-only browsing tests
- Static page verification

#### Sub-groups:
**P4.1: Anonymous/Public Pages (8 tests)**
- Landing page tests
- Documentation pages
- Pricing page
- FAQ/Help pages

**P4.2: Dashboard Navigation (8 tests)**
- FE-DASH-001: Main dashboard display
- FE-DASH-002: Menu navigation
- Stats card rendering
- Chart display tests

**P4.3: Study Set Read Operations (12 tests)**
- FE-STUDYSET-001: List view
- Study set detail view (no modification)
- Search and filter operations

#### Rationale:
- Each test uses unique user account (test-user-1@example.com, test-user-2@example.com)
- No shared data modification
- Concurrent sessions don't interfere
- Browser contexts are fully isolated

#### Isolation Strategy:
```javascript
// Playwright user pool strategy
const USER_POOL = [
  { email: 'test-p4-1@certigraph.test', password: 'Test1234!' },
  { email: 'test-p4-2@certigraph.test', password: 'Test1234!' },
  { email: 'test-p4-3@certigraph.test', password: 'Test1234!' },
  { email: 'test-p4-4@certigraph.test', password: 'Test1234!' },
];

test.describe.configure({ mode: 'parallel' });

test('Dashboard test', async ({ page }, testInfo) => {
  const workerIndex = testInfo.parallelIndex;
  const user = USER_POOL[workerIndex];
  await login(page, user);
  // ... test logic
});
```

---

## 2. Sequential Execution Groups

### Group S1: Write-Heavy API Integration Tests (Sequential)
**Test Count:** 32 tests
**Estimated Duration:** 8-12 minutes
**Parallelization Factor:** 1 worker (sequential)
**Dependencies:** Database state from previous tests

#### Tests Included:
- `INT-001`: POST /api/v1/study-sets (create)
- `INT-004`: DELETE /api/v1/study-sets/{id}
- `INT-005`: POST /api/v1/tests/start
- `INT-006`: POST /api/v1/tests/answer
- `INT-007`: POST /api/v1/tests/complete
- `INT-009` to `INT-013`: PDF processing pipeline

#### Execution Order:
```
1. Create Study Set (INT-001)
   ↓
2. Upload PDF (INT-009)
   ↓
3. OCR Processing (INT-010)
   ↓
4. Question Extraction (INT-011)
   ↓
5. Start Test Session (INT-005)
   ↓
6. Submit Answers (INT-006)
   ↓
7. Complete Test (INT-007)
   ↓
8. Verify Results (INT-008)
   ↓
9. Analyze Weaknesses (INT-018)
   ↓
10. Delete Study Set (INT-004)
```

#### Rationale:
- Each test depends on previous test's data
- Database mutations affect subsequent tests
- Complex workflow requires ordered execution
- Failure in early steps invalidates later tests

#### Isolation Strategy:
- Single worker executes entire chain
- Database cleanup after complete sequence
- Use beforeAll/afterAll hooks for setup/teardown

```javascript
describe('Study Set Lifecycle', () => {
  let studySetId;
  let testSessionId;

  beforeAll(async () => {
    await cleanDatabase();
  });

  test('INT-001: Create study set', async () => {
    studySetId = await createStudySet();
    expect(studySetId).toBeDefined();
  });

  test('INT-009: Upload PDF', async () => {
    expect(studySetId).toBeDefined();
    await uploadPDF(studySetId);
  });

  // ... sequential tests

  afterAll(async () => {
    await cleanDatabase();
  });
});
```

---

### Group S2: Critical E2E User Journeys (Sequential)
**Test Count:** 14 tests
**Estimated Duration:** 10-15 minutes
**Parallelization Factor:** 1 worker
**Dependencies:** Complete user journey from signup to analysis

#### Tests Included:
- `E2E-001`: Signup → Login → Dashboard
- `E2E-002`: PDF Upload → Study Set Creation
- `E2E-003`: Study Set Selection → Test Completion → Results
- `E2E-004`: Weakness Analysis → Retest → Improvement Verification

#### Execution Flow:
```
E2E-001: User Onboarding
  ↓
E2E-002: Content Upload
  ↓
E2E-003: First Test Completion
  ↓
E2E-004: Learning Improvement Cycle
  ↓
Payment & Subscription Tests
  ↓
Admin Operations
```

#### Rationale:
- Simulates real user journey
- Each step builds on previous step's state
- Tests holistic system behavior
- Validates cross-feature integration

---

### Group S3: Payment Flow Tests (Sequential)
**Test Count:** 12 tests
**Estimated Duration:** 5-8 minutes
**Parallelization Factor:** 1 worker
**Dependencies:** Payment gateway state

#### Tests Included:
- Free trial initiation
- Trial limit enforcement (2 sessions)
- Payment page access
- Payment completion
- Subscription activation
- Feature unlock verification

#### Execution Order:
```
1. User creates account
2. Uses free trial (session 1)
3. Uses free trial (session 2)
4. Trial limit reached
5. Redirect to payment page
6. Complete payment (test mode)
7. Verify subscription active
8. Access premium features
9. Test subscription expiry
10. Renewal flow
```

#### Rationale:
- Payment state is stateful and cannot be parallelized
- Toss Payments test mode has rate limits
- Trial counting is global per user
- Subscription state affects feature access

---

## 3. Resource Isolation Strategy

### 3.1 Database Isolation

#### Approach: Database Per Worker
```yaml
Database Strategy: Isolated PostgreSQL Databases

Worker 1: certigraph_test_w1
Worker 2: certigraph_test_w2
Worker 3: certigraph_test_w3
...
Worker 12: certigraph_test_w12
```

#### Implementation:
```javascript
// playwright.config.ts
export default defineConfig({
  workers: process.env.CI ? 4 : 8,
  globalSetup: './tests/global-setup.ts',

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
  },
});

// tests/global-setup.ts
export default async function globalSetup() {
  const workerCount = process.env.TEST_WORKERS || 8;

  for (let i = 0; i < workerCount; i++) {
    await createDatabase(`certigraph_test_w${i}`);
    await runMigrations(`certigraph_test_w${i}`);
    await seedFixtureData(`certigraph_test_w${i}`);
  }
}
```

#### Database Connection Routing:
```python
# backend/tests/conftest.py
import os
import pytest

@pytest.fixture(scope="session")
def db_url():
    worker_id = os.environ.get('PYTEST_XDIST_WORKER', 'w0')
    worker_num = worker_id.replace('gw', '').replace('w', '')
    return f"postgresql://localhost/certigraph_test_w{worker_num}"

@pytest.fixture(scope="function")
def db_session(db_url):
    engine = create_engine(db_url)
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.rollback()
    session.close()
```

#### Cleanup Strategy:
```bash
# After test suite
DROP DATABASE certigraph_test_w0;
DROP DATABASE certigraph_test_w1;
# ... etc

# Or use automated cleanup
npm run test:cleanup
```

---

### 3.2 User Account Strategy

#### User Pool Architecture:
```javascript
// tests/fixtures/user-pool.ts
export const USER_POOLS = {
  // Group P4: Parallel E2E tests (4 workers)
  parallel: [
    { email: 'parallel-1@test.certigraph.io', password: 'Test1234!', role: 'student' },
    { email: 'parallel-2@test.certigraph.io', password: 'Test1234!', role: 'student' },
    { email: 'parallel-3@test.certigraph.io', password: 'Test1234!', role: 'student' },
    { email: 'parallel-4@test.certigraph.io', password: 'Test1234!', role: 'student' },
  ],

  // Group S2: Sequential E2E journey
  sequential: [
    { email: 'seq-journey@test.certigraph.io', password: 'Test1234!', role: 'student' },
  ],

  // Group S3: Payment tests
  payment: [
    { email: 'payment-test@test.certigraph.io', password: 'Test1234!', role: 'student' },
  ],

  // Admin tests
  admin: [
    { email: 'admin-test@test.certigraph.io', password: 'Admin1234!', role: 'admin' },
  ],
};

// Auto-assign user based on test group
export function getUserForTest(testInfo: TestInfo) {
  const { parallelIndex, project } = testInfo;

  if (project.name.includes('parallel')) {
    return USER_POOLS.parallel[parallelIndex % USER_POOLS.parallel.length];
  }

  if (project.name.includes('sequential')) {
    return USER_POOLS.sequential[0];
  }

  if (project.name.includes('payment')) {
    return USER_POOLS.payment[0];
  }

  return USER_POOLS.admin[0];
}
```

#### User Data Isolation:
```javascript
// Each test cleans up its user data
test.afterEach(async ({ request }, testInfo) => {
  const user = getUserForTest(testInfo);

  // Clean up user's study sets
  await request.delete(`/api/v1/users/${user.id}/study-sets`, {
    headers: { Authorization: `Bearer ${user.token}` }
  });

  // Reset user's test sessions
  await request.delete(`/api/v1/users/${user.id}/sessions`);
});
```

---

### 3.3 File Upload Isolation

#### Upload Directory Strategy:
```
/tmp/test-uploads/
  ├── w0/  (Worker 0)
  │   ├── user-1/
  │   │   └── test-pdf-123.pdf
  │   └── user-2/
  ├── w1/  (Worker 1)
  │   └── user-3/
  ├── w2/  (Worker 2)
  ...
```

#### Implementation:
```javascript
// tests/helpers/file-upload.ts
import path from 'path';
import os from 'os';

export function getUploadDir(testInfo: TestInfo) {
  const workerId = testInfo.parallelIndex;
  return path.join(os.tmpdir(), 'test-uploads', `w${workerId}`);
}

export async function uploadTestPDF(page: Page, testInfo: TestInfo) {
  const uploadDir = getUploadDir(testInfo);
  const testFile = path.join(uploadDir, 'sample-exam.pdf');

  // Copy fixture to worker-specific directory
  await fs.copyFile(
    './tests/fixtures/sample-exam.pdf',
    testFile
  );

  await page.setInputFiles('input[type="file"]', testFile);
}

// Cleanup after test
test.afterEach(async ({}, testInfo) => {
  const uploadDir = getUploadDir(testInfo);
  await fs.rm(uploadDir, { recursive: true, force: true });
});
```

---

### 3.4 Session Management

#### Browser Context Isolation:
```javascript
// playwright.config.ts
export default defineConfig({
  use: {
    // Each test gets fresh browser context
    contextOptions: {
      storageState: undefined, // No shared cookies/localStorage
    },
  },

  // Each worker has its own browser instance
  workers: 8,
  fullyParallel: false, // Respect test grouping
});
```

#### Session Cleanup:
```javascript
test.beforeEach(async ({ context }) => {
  // Clear all cookies and storage before test
  await context.clearCookies();
  await context.clearPermissions();
});

test.afterEach(async ({ context }) => {
  // Close context to prevent session leakage
  await context.close();
});
```

---

## 4. Dependency Mapping

### 4.1 Test Dependency Graph

```mermaid
graph TD
    A[FE Component Tests] --> |No Dependencies| Z[Can Run Anytime]
    B[BE Unit Tests] --> |No Dependencies| Z

    C[Auth Tests] --> D[User CRUD Tests]
    D --> E[Study Set Tests]
    E --> F[PDF Upload Tests]
    F --> G[Question Extraction Tests]
    G --> H[Test Session Tests]
    H --> I[Results & Analysis Tests]

    J[Payment Tests] --> K[Premium Feature Tests]

    L[Admin Tests] --> M[User Management]

    N[Knowledge Graph Tests] --> I

    style A fill:#90EE90
    style B fill:#90EE90
    style C fill:#FFB6C1
    style J fill:#FFB6C1
    style Z fill:#90EE90
```

**Legend:**
- Green: Fully parallelizable (no dependencies)
- Pink: Sequential dependencies (must run in order)

---

### 4.2 Dependency Matrix

| Test Group | Depends On | Modifies Global State | Safe for Parallel |
|-----------|------------|----------------------|------------------|
| FE-UNIT-001~068 | None | No | ✅ Yes |
| BE-UNIT-001~039 | None | No | ✅ Yes |
| INT-002, INT-003, INT-008 | Read-only data | No | ✅ Yes |
| INT-001 (Create) | None | Yes (DB) | ⚠️ Isolated |
| INT-004 (Delete) | INT-001 | Yes (DB) | ❌ No |
| INT-005~007 (Test Flow) | INT-001 | Yes (DB, Session) | ❌ No |
| INT-009~013 (PDF Pipeline) | INT-001 | Yes (DB, Files) | ❌ No |
| E2E-001 (Onboarding) | None | Yes (User DB) | ⚠️ Isolated |
| E2E-002 (Upload) | E2E-001 | Yes (All) | ❌ No |
| E2E-003 (Test Taking) | E2E-002 | Yes (All) | ❌ No |
| E2E-004 (Learning Loop) | E2E-003 | Yes (All) | ❌ No |
| Payment Tests | User exists | Yes (Payment DB) | ❌ No |
| Admin Tests | Users exist | Yes (User DB) | ⚠️ Isolated |

---

### 4.3 State Mutation Map

#### Database Tables Affected:

| Test Group | Users | Study_Sets | Materials | Questions | Sessions | Payments | Graph_Nodes |
|-----------|-------|-----------|----------|-----------|---------|---------|------------|
| FE Unit | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| BE Unit | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| INT Read | ✅ Read | ✅ Read | ✅ Read | ✅ Read | ✅ Read | ❌ | ✅ Read |
| INT Write | ✅ Write | ✅ Write | ✅ Write | ✅ Write | ✅ Write | ❌ | ✅ Write |
| E2E Journey | ✅ Write | ✅ Write | ✅ Write | ✅ Write | ✅ Write | ✅ Write | ✅ Write |
| Payment | ✅ Write | ❌ | ❌ | ❌ | ❌ | ✅ Write | ❌ |
| Admin | ✅ Write | ✅ Write | ❌ | ❌ | ❌ | ❌ | ❌ |

**Conflict Analysis:**
- **High Risk:** INT Write + E2E Journey (both write to all tables)
- **Medium Risk:** Admin + Payment (both write to Users table)
- **Low Risk:** INT Read + FE/BE Unit (read-only vs no access)

---

## 5. Execution Plan

### 5.1 Execution Timeline (Optimized)

```
┌─────────────────────────────────────────────────────────────┐
│ Parallel Phase 1: Unit Tests (0-8 minutes)                  │
├─────────────────────────────────────────────────────────────┤
│ Worker 1: FE-UNIT-001~008  (NotionCard)          │████      │
│ Worker 2: FE-UNIT-009~016  (NotionStatCard)      │████      │
│ Worker 3: FE-UNIT-017~024  (NotionPageHeader)    │████      │
│ Worker 4: FE-UNIT-025~040  (NotionLayout etc.)   │████████  │
│ Worker 5: BE-UNIT-001~010  (Hash, Extractor)     │█████     │
│ Worker 6: BE-UNIT-011~020  (Scoring, Analysis)   │█████     │
│ Worker 7: BE-UNIT-021~030  (Session, Config)     │████      │
│ Worker 8: BE-UNIT-031~039  (Security)            │███       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Parallel Phase 2: Read-Only Integration (8-14 minutes)      │
├─────────────────────────────────────────────────────────────┤
│ Worker 1: INT-002, INT-003 (Study Set Reads)     │████      │
│ Worker 2: INT-008 (Results Read)                 │███       │
│ Worker 3: INT-014, INT-015 (Auth)                │████      │
│ Worker 4: INT-019, INT-020 (Analysis Reads)      │█████     │
│ Worker 5: Dashboard E2E (FE-DASH-001~003)        │████████  │
│ Worker 6: Static Pages E2E                       │████      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Sequential Phase 1: API Integration Chain (14-26 minutes)   │
├─────────────────────────────────────────────────────────────┤
│ Worker 1 (Sequential):                                       │
│   INT-001 Create → INT-009 Upload → INT-010 OCR →          │
│   INT-011 Extract → INT-005 Start Test →                    │
│   INT-006 Submit → INT-007 Complete →                       │
│   INT-008 Results → INT-018 Analyze → INT-004 Delete       │
│   │████████████████████████████████████████████│            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Sequential Phase 2: E2E Journeys (26-41 minutes)            │
├─────────────────────────────────────────────────────────────┤
│ Worker 1: E2E-001→002→003→004 (Main Journey)    │██████████│
│ Worker 2: Payment Flow Tests (S3 Group)          │██████    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Parallel Phase 3: Edge Cases & Performance (41-50 minutes)  │
├─────────────────────────────────────────────────────────────┤
│ Worker 1: E2E-005~007 (Error Handling)           │████      │
│ Worker 2: E2E-008~010 (Performance)              │██████    │
│ Worker 3: Browser Compatibility                  │█████     │
│ Worker 4: Accessibility Tests                    │████      │
└─────────────────────────────────────────────────────────────┘

Total Duration: ~50 minutes (vs 180 minutes serial)
```

---

### 5.2 Worker Allocation Strategy

#### Recommended Configuration:

```javascript
// playwright.config.ts
export default defineConfig({
  // Local development: 8 workers
  // CI environment: 4 workers (resource constrained)
  workers: process.env.CI ? 4 : 8,

  // Maximum test failures before aborting
  maxFailures: process.env.CI ? 10 : undefined,

  // Retry flaky tests
  retries: process.env.CI ? 2 : 0,

  projects: [
    {
      name: 'unit-tests-fe',
      testMatch: '**/tests/unit/frontend/**/*.spec.ts',
      fullyParallel: true, // All tests can run in parallel
    },
    {
      name: 'unit-tests-be',
      testMatch: '**/tests/unit/backend/**/*.spec.ts',
      fullyParallel: true,
    },
    {
      name: 'integration-read',
      testMatch: '**/tests/integration/read-only/**/*.spec.ts',
      fullyParallel: true,
    },
    {
      name: 'integration-write',
      testMatch: '**/tests/integration/write/**/*.spec.ts',
      fullyParallel: false, // Sequential execution
      workers: 1,
    },
    {
      name: 'e2e-parallel',
      testMatch: '**/tests/e2e/parallel/**/*.spec.ts',
      fullyParallel: true,
      workers: 4, // Limited parallelism for E2E
    },
    {
      name: 'e2e-sequential',
      testMatch: '**/tests/e2e/sequential/**/*.spec.ts',
      fullyParallel: false,
      workers: 1, // Strict sequential
    },
  ],
});
```

---

### 5.3 Execution Commands

```bash
# Run all tests with optimal parallelization
npm run test:all

# Run only parallel-safe tests (fast feedback)
npm run test:parallel

# Run sequential tests (slower, comprehensive)
npm run test:sequential

# Run specific group
npm run test:unit:fe
npm run test:unit:be
npm run test:integration
npm run test:e2e

# CI/CD pipeline command
npm run test:ci
```

**package.json configuration:**
```json
{
  "scripts": {
    "test:all": "playwright test",
    "test:parallel": "playwright test --project=unit-tests-fe --project=unit-tests-be --project=integration-read --project=e2e-parallel",
    "test:sequential": "playwright test --project=integration-write --project=e2e-sequential",
    "test:unit:fe": "playwright test --project=unit-tests-fe",
    "test:unit:be": "playwright test --project=unit-tests-be",
    "test:integration": "playwright test --grep integration",
    "test:e2e": "playwright test --grep e2e",
    "test:ci": "playwright test --workers=4 --retries=2 --reporter=junit,html",
    "test:cleanup": "node scripts/cleanup-test-databases.js"
  }
}
```

---

### 5.4 Cleanup Strategies

#### Per-Test Cleanup:
```javascript
// tests/fixtures/cleanup.ts
export const testCleanup = base.extend({
  async cleanupAfterTest({}, use, testInfo) {
    await use();

    // Cleanup based on test type
    if (testInfo.project.name.includes('e2e')) {
      await cleanupBrowserStorage();
      await cleanupUploadedFiles(testInfo);
    }

    if (testInfo.project.name.includes('integration')) {
      await rollbackDatabaseTransaction();
    }
  },
});
```

#### Between-Group Cleanup:
```javascript
// tests/global-teardown.ts
export default async function globalTeardown() {
  console.log('Starting global cleanup...');

  // Drop all test databases
  for (let i = 0; i < 12; i++) {
    await dropDatabase(`certigraph_test_w${i}`);
  }

  // Clean temp file uploads
  await fs.rm('/tmp/test-uploads', { recursive: true, force: true });

  // Reset test users in Auth provider
  await resetClerkTestUsers();

  console.log('Cleanup complete!');
}
```

---

## 6. Playwright Configuration

### 6.1 Complete Configuration File

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

/**
 * CertiGraph Test Configuration
 * Optimized for parallel execution with resource isolation
 */
export default defineConfig({
  testDir: './tests',

  /* Maximum time one test can run for */
  timeout: 30 * 1000,

  /* Test expectations timeout */
  expect: {
    timeout: 5000,
  },

  /* Run tests in files in parallel */
  fullyParallel: false, // Controlled by project config

  /* Fail the build on CI if you accidentally left test.only */
  forbidOnly: !!process.env.CI,

  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,

  /* Opt out of parallel tests on CI */
  workers: process.env.CI ? 4 : 8,

  /* Reporter to use */
  reporter: [
    ['list'],
    ['html', { outputFolder: 'test-results/html-report' }],
    ['json', { outputFile: 'test-results/results.json' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
  ],

  /* Shared settings for all the projects below */
  use: {
    /* Base URL to use in actions like `await page.goto('/')` */
    baseURL: process.env.BASE_URL || 'http://localhost:3000',

    /* Collect trace when retrying the failed test */
    trace: 'on-first-retry',

    /* Screenshot on failure */
    screenshot: 'only-on-failure',

    /* Video on failure */
    video: 'retain-on-failure',

    /* Timeout for each action */
    actionTimeout: 10000,

    /* Navigation timeout */
    navigationTimeout: 15000,
  },

  /* Global setup and teardown */
  globalSetup: require.resolve('./tests/global-setup.ts'),
  globalTeardown: require.resolve('./tests/global-teardown.ts'),

  /* Configure projects for major browsers and test types */
  projects: [
    // ============================================================
    // PARALLEL GROUPS (Fully Parallelizable)
    // ============================================================

    {
      name: 'unit-tests-fe',
      testMatch: '**/tests/unit/frontend/**/*.spec.ts',
      fullyParallel: true,
      use: {
        // No browser needed for unit tests
        browserName: undefined,
      },
    },

    {
      name: 'unit-tests-be',
      testMatch: '**/tests/unit/backend/**/*.spec.ts',
      fullyParallel: true,
      use: {
        browserName: undefined,
      },
    },

    {
      name: 'integration-read-only',
      testMatch: '**/tests/integration/read-only/**/*.spec.ts',
      fullyParallel: true,
      workers: 6,
      use: {
        ...devices['Desktop Chrome'],
      },
    },

    {
      name: 'e2e-parallel-chrome',
      testMatch: '**/tests/e2e/parallel/**/*.spec.ts',
      fullyParallel: true,
      workers: 4,
      use: {
        ...devices['Desktop Chrome'],
      },
    },

    // ============================================================
    // SEQUENTIAL GROUPS (Must Run in Order)
    // ============================================================

    {
      name: 'integration-write-sequential',
      testMatch: '**/tests/integration/sequential/**/*.spec.ts',
      fullyParallel: false,
      workers: 1,
      use: {
        ...devices['Desktop Chrome'],
      },
    },

    {
      name: 'e2e-journey-sequential',
      testMatch: '**/tests/e2e/sequential/**/*.spec.ts',
      fullyParallel: false,
      workers: 1,
      use: {
        ...devices['Desktop Chrome'],
      },
    },

    {
      name: 'payment-flow-sequential',
      testMatch: '**/tests/payment/**/*.spec.ts',
      fullyParallel: false,
      workers: 1,
      use: {
        ...devices['Desktop Chrome'],
      },
    },

    // ============================================================
    // CROSS-BROWSER TESTING (Run after main tests pass)
    // ============================================================

    {
      name: 'cross-browser-firefox',
      testMatch: '**/tests/e2e/parallel/**/*.spec.ts',
      fullyParallel: true,
      workers: 2,
      use: {
        ...devices['Desktop Firefox'],
      },
      dependencies: ['e2e-parallel-chrome'],
    },

    {
      name: 'cross-browser-safari',
      testMatch: '**/tests/e2e/parallel/**/*.spec.ts',
      fullyParallel: true,
      workers: 2,
      use: {
        ...devices['Desktop Safari'],
      },
      dependencies: ['e2e-parallel-chrome'],
    },

    // ============================================================
    // MOBILE TESTING
    // ============================================================

    {
      name: 'mobile-chrome',
      testMatch: '**/tests/e2e/mobile/**/*.spec.ts',
      fullyParallel: true,
      workers: 2,
      use: {
        ...devices['Pixel 5'],
      },
    },

    {
      name: 'mobile-safari',
      testMatch: '**/tests/e2e/mobile/**/*.spec.ts',
      fullyParallel: true,
      workers: 2,
      use: {
        ...devices['iPhone 13'],
      },
    },
  ],

  /* Development server configuration */
  webServer: [
    {
      command: 'npm run dev:frontend',
      port: 3000,
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
    },
    {
      command: 'npm run dev:backend',
      port: 8000,
      timeout: 120 * 1000,
      reuseExistingServer: !process.env.CI,
    },
  ],
});
```

---

### 6.2 Environment Variables

```bash
# .env.test
# Test environment configuration

# Database
DATABASE_URL=postgresql://localhost:5432/certigraph_test_w0
TEST_DB_PREFIX=certigraph_test_w

# Backend
BACKEND_URL=http://localhost:8000
BACKEND_DEV_MODE=true

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
BASE_URL=http://localhost:3000

# Auth (Clerk Test Environment)
CLERK_SECRET_KEY=sk_test_xxxxxx
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxx
CLERK_WEBHOOK_SECRET=whsec_test_xxxxxx

# Payment (Toss Payments Test Mode)
TOSS_CLIENT_KEY=test_ck_xxxxxx
TOSS_SECRET_KEY=test_sk_xxxxxx

# External APIs (Mock/Test Mode)
UPSTAGE_API_KEY=test_upstage_xxxxxx
OPENAI_API_KEY=test_openai_xxxxxx
PINECONE_API_KEY=test_pinecone_xxxxxx
NEO4J_URI=bolt://localhost:7687
NEO4J_USER=neo4j_test
NEO4J_PASSWORD=test_password

# Test Configuration
TEST_WORKERS=8
TEST_TIMEOUT=30000
TEST_RETRIES=0
PARALLEL_TESTS=true

# CI Configuration
CI=false
CI_WORKERS=4
CI_RETRIES=2
```

---

### 6.3 Test Organization Structure

```
tests/
├── unit/
│   ├── frontend/
│   │   ├── components/
│   │   │   ├── notion-card.spec.ts         (FE-UNIT-001~008)
│   │   │   ├── notion-stat-card.spec.ts    (FE-UNIT-009~016)
│   │   │   ├── question-card.spec.ts       (FE-UNIT-041~048)
│   │   │   └── ...
│   │   └── hooks/
│   │       └── use-study-sets.spec.ts
│   └── backend/
│       ├── services/
│       │   ├── pdf-hash.spec.ts            (BE-UNIT-001~005)
│       │   ├── question-extractor.spec.ts  (BE-UNIT-006~013)
│       │   └── scoring.spec.ts             (BE-UNIT-014~019)
│       └── utils/
│
├── integration/
│   ├── read-only/                          (PARALLEL)
│   │   ├── study-sets-read.spec.ts         (INT-002, INT-003)
│   │   ├── test-results-read.spec.ts       (INT-008)
│   │   └── auth-verify.spec.ts             (INT-014, INT-015)
│   └── sequential/                         (SEQUENTIAL)
│       ├── study-set-lifecycle.spec.ts     (INT-001→004)
│       └── pdf-processing-pipeline.spec.ts (INT-009→013)
│
├── e2e/
│   ├── parallel/                           (PARALLEL - 4 workers)
│   │   ├── dashboard-navigation.spec.ts    (FE-DASH-001~003)
│   │   ├── study-set-browsing.spec.ts
│   │   └── static-pages.spec.ts
│   ├── sequential/                         (SEQUENTIAL - 1 worker)
│   │   ├── user-journey-main.spec.ts       (E2E-001→004)
│   │   └── learning-improvement-cycle.spec.ts
│   └── mobile/
│       └── responsive-layout.spec.ts
│
├── payment/                                (SEQUENTIAL - 1 worker)
│   ├── free-trial.spec.ts
│   └── season-pass-purchase.spec.ts
│
├── performance/
│   ├── load-testing.spec.ts
│   └── large-pdf-upload.spec.ts
│
├── accessibility/
│   └── wcag-compliance.spec.ts
│
├── fixtures/
│   ├── user-pool.ts
│   ├── test-data.ts
│   └── cleanup.ts
│
├── helpers/
│   ├── auth.ts
│   ├── database.ts
│   └── file-upload.ts
│
├── global-setup.ts
└── global-teardown.ts
```

---

## 7. Risk Assessment

### 7.1 Parallel Execution Risks

| Risk ID | Risk Description | Probability | Impact | Mitigation Strategy | Status |
|---------|------------------|-------------|--------|---------------------|--------|
| **R1** | Database race conditions | Medium | High | Use isolated databases per worker | ✅ Mitigated |
| **R2** | Flaky tests due to timing | High | Medium | Implement explicit waits, increase timeouts | ⚠️ Monitor |
| **R3** | Resource exhaustion (CPU/Memory) | Medium | High | Limit workers based on system resources | ✅ Mitigated |
| **R4** | Test data contamination | Medium | High | Clean up after each test, use unique identifiers | ✅ Mitigated |
| **R5** | Network port conflicts | Low | Medium | Use dynamic port allocation | ✅ Mitigated |
| **R6** | External API rate limits | Medium | Medium | Use mocks for unit tests, throttle integration tests | ⚠️ Monitor |
| **R7** | File system conflicts | Low | Medium | Worker-specific upload directories | ✅ Mitigated |
| **R8** | Payment gateway test mode limits | High | Medium | Run payment tests sequentially, use retry logic | ✅ Mitigated |
| **R9** | Browser session leakage | Medium | Low | Explicit context cleanup in afterEach | ✅ Mitigated |
| **R10** | Insufficient test isolation | Medium | High | Strict project separation, dependency analysis | ✅ Mitigated |

---

### 7.2 Risk Mitigation Implementation

#### R1: Database Race Conditions
```javascript
// BEFORE (High Risk)
test('Create study set', async () => {
  await db.studySets.create({ name: 'Test Set' });
  // Another parallel test might insert same data
});

// AFTER (Mitigated)
test('Create study set', async ({ workerInfo }) => {
  const dbName = `certigraph_test_w${workerInfo.workerIndex}`;
  const db = connectToDatabase(dbName);
  await db.studySets.create({
    name: `Test Set ${workerInfo.workerIndex}`
  });
});
```

#### R2: Flaky Tests (Timing Issues)
```javascript
// BEFORE (Flaky)
test('Load dashboard', async ({ page }) => {
  await page.goto('/dashboard');
  await page.click('button'); // Might click before button is ready
});

// AFTER (Stable)
test('Load dashboard', async ({ page }) => {
  await page.goto('/dashboard');
  await page.waitForLoadState('networkidle');
  await page.getByRole('button', { name: 'Start Test' }).waitFor();
  await page.click('button');
});
```

#### R6: External API Rate Limits
```javascript
// Integration test - use mock
test('Extract questions from PDF', async () => {
  // Mock Upstage API to avoid rate limits
  await page.route('**/upstage.ai/api/**', route => {
    route.fulfill({
      status: 200,
      body: JSON.stringify(mockOCRResponse),
    });
  });

  await uploadPDF();
  await verifyQuestionsExtracted();
});
```

#### R8: Payment Gateway Limits
```javascript
// Sequential execution with retry
test.describe.serial('Payment Flow', () => {
  test.setTimeout(60000); // Longer timeout

  test('Complete payment', async ({ page }) => {
    // Retry logic for flaky payment API
    await test.step('Initiate payment', async () => {
      await initiatePayment();
    });

    await test.step('Confirm payment', async () => {
      await confirmPayment();
    });
  });
});
```

---

### 7.3 Rollback Plan

If parallel execution causes issues:

**Phase 1: Immediate Fallback**
```bash
# Disable parallelization temporarily
export PARALLEL_TESTS=false
export TEST_WORKERS=1
npm run test:sequential
```

**Phase 2: Gradual Re-enablement**
```bash
# Enable only unit test parallelization
npm run test:unit:fe &
npm run test:unit:be &
wait
npm run test:integration
npm run test:e2e
```

**Phase 3: Identify Problem Tests**
```bash
# Run with verbose logging
DEBUG=pw:api npm run test:all

# Isolate flaky tests
npm run test:flaky-detector
```

---

## 8. Monitoring & Debugging

### 8.1 Test Execution Metrics

```javascript
// tests/reporters/metrics-reporter.ts
import { Reporter, TestCase, TestResult } from '@playwright/test/reporter';

class MetricsReporter implements Reporter {
  private metrics = {
    totalTests: 0,
    passedTests: 0,
    failedTests: 0,
    skippedTests: 0,
    flakyTests: 0,
    avgDuration: 0,
    slowestTests: [],
  };

  onTestEnd(test: TestCase, result: TestResult) {
    this.metrics.totalTests++;

    if (result.status === 'passed') {
      this.metrics.passedTests++;
    } else if (result.status === 'failed') {
      this.metrics.failedTests++;
    } else if (result.status === 'skipped') {
      this.metrics.skippedTests++;
    }

    if (result.retry > 0 && result.status === 'passed') {
      this.metrics.flakyTests++;
    }

    if (result.duration > 5000) {
      this.metrics.slowestTests.push({
        name: test.title,
        duration: result.duration,
      });
    }
  }

  onEnd() {
    console.log('\n=== Test Execution Metrics ===');
    console.log(`Total: ${this.metrics.totalTests}`);
    console.log(`Passed: ${this.metrics.passedTests}`);
    console.log(`Failed: ${this.metrics.failedTests}`);
    console.log(`Flaky: ${this.metrics.flakyTests}`);
    console.log(`Pass Rate: ${(this.metrics.passedTests / this.metrics.totalTests * 100).toFixed(2)}%`);

    if (this.metrics.slowestTests.length > 0) {
      console.log('\n=== Slowest Tests ===');
      this.metrics.slowestTests
        .sort((a, b) => b.duration - a.duration)
        .slice(0, 10)
        .forEach(test => {
          console.log(`${test.name}: ${test.duration}ms`);
        });
    }
  }
}

export default MetricsReporter;
```

**Add to playwright.config.ts:**
```typescript
reporter: [
  ['list'],
  ['html'],
  ['./tests/reporters/metrics-reporter.ts'],
],
```

---

### 8.2 Flaky Test Detection

```javascript
// scripts/detect-flaky-tests.js
const { execSync } = require('child_process');

async function detectFlakyTests() {
  const runs = 10;
  const results = {};

  for (let i = 0; i < runs; i++) {
    console.log(`Run ${i + 1}/${runs}...`);

    try {
      const output = execSync('npm run test:all', { encoding: 'utf-8' });

      // Parse test results
      const testResults = parseTestResults(output);

      testResults.forEach(test => {
        if (!results[test.name]) {
          results[test.name] = { passed: 0, failed: 0 };
        }

        if (test.status === 'passed') {
          results[test.name].passed++;
        } else {
          results[test.name].failed++;
        }
      });
    } catch (error) {
      console.error(`Run ${i + 1} failed`);
    }
  }

  // Identify flaky tests (passed and failed at least once)
  const flakyTests = Object.entries(results)
    .filter(([_, counts]) => counts.passed > 0 && counts.failed > 0)
    .map(([name, counts]) => ({
      name,
      passRate: (counts.passed / runs * 100).toFixed(2),
    }));

  console.log('\n=== Flaky Tests Detected ===');
  flakyTests.forEach(test => {
    console.log(`${test.name}: ${test.passRate}% pass rate`);
  });

  return flakyTests;
}

detectFlakyTests();
```

**Run with:**
```bash
node scripts/detect-flaky-tests.js
```

---

### 8.3 Debug Configuration

```typescript
// playwright.config.debug.ts
import { defineConfig } from '@playwright/test';
import baseConfig from './playwright.config';

export default defineConfig({
  ...baseConfig,

  // Debug mode: single worker, headed browser
  workers: 1,
  fullyParallel: false,

  use: {
    ...baseConfig.use,

    // Visual debugging
    headless: false,
    slowMo: 500, // Slow down actions

    // Full tracing
    trace: 'on',
    screenshot: 'on',
    video: 'on',

    // Increased timeouts
    actionTimeout: 30000,
    navigationTimeout: 60000,
  },

  // Verbose logging
  reporter: [
    ['list'],
    ['html'],
    ['json', { outputFile: 'test-results/debug-results.json' }],
  ],
});
```

**Run debug mode:**
```bash
npx playwright test --config=playwright.config.debug.ts --debug
```

---

### 8.4 CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Automated Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18.x, 20.x]

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}

      - name: Install dependencies
        run: npm ci

      - name: Run unit tests
        run: npm run test:unit:fe && npm run test:unit:be
        env:
          CI: true
          TEST_WORKERS: 4

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test_password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      neo4j:
        image: neo4j:5
        env:
          NEO4J_AUTH: neo4j/test_password
        ports:
          - 7687:7687

    steps:
      - uses: actions/checkout@v3

      - name: Setup databases
        run: |
          npm run test:setup-databases
        env:
          DATABASE_URL: postgresql://postgres:test_password@localhost:5432/certigraph_test

      - name: Run integration tests
        run: npm run test:integration
        env:
          CI: true
          TEST_WORKERS: 2

  e2e-tests:
    runs-on: ubuntu-latest
    needs: integration-tests

    steps:
      - uses: actions/checkout@v3

      - name: Install Playwright Browsers
        run: npx playwright install --with-deps

      - name: Run E2E tests
        run: npm run test:e2e
        env:
          CI: true
          TEST_WORKERS: 2

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/

      - name: Upload Playwright report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/

  test-summary:
    runs-on: ubuntu-latest
    needs: [unit-tests, integration-tests, e2e-tests]
    if: always()

    steps:
      - name: Download test results
        uses: actions/download-artifact@v3
        with:
          name: test-results

      - name: Generate summary
        run: node scripts/generate-test-summary.js

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const summary = require('./test-summary.json');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Test Results\n\n✅ Passed: ${summary.passed}\n❌ Failed: ${summary.failed}\n⏭️ Skipped: ${summary.skipped}`
            });
```

---

## 9. Performance Benchmarks

### 9.1 Expected Execution Times

| Test Group | Tests | Serial Time | Parallel Time (8 workers) | Improvement |
|-----------|-------|-------------|--------------------------|-------------|
| FE Unit | 68 | 15 min | 2 min | 87% faster |
| BE Unit | 130 | 25 min | 3 min | 88% faster |
| Integration Read | 24 | 12 min | 2 min | 83% faster |
| Integration Write | 32 | 18 min | 18 min | 0% (sequential) |
| E2E Parallel | 28 | 40 min | 12 min | 70% faster |
| E2E Sequential | 14 | 25 min | 25 min | 0% (sequential) |
| Payment | 12 | 10 min | 10 min | 0% (sequential) |
| **TOTAL** | **312** | **~180 min** | **~35 min** | **81% faster** |

---

### 9.2 Resource Usage Monitoring

```javascript
// scripts/monitor-test-resources.js
const os = require('os');
const { execSync } = require('child_process');

function monitorResources() {
  const interval = setInterval(() => {
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMem = totalMem - freeMem;
    const memPercent = (usedMem / totalMem * 100).toFixed(2);

    const cpus = os.cpus();
    const avgLoad = os.loadavg()[0];

    console.log(`Memory: ${memPercent}% | CPU Load: ${avgLoad.toFixed(2)}`);

    // Alert if resources are high
    if (memPercent > 90) {
      console.warn('⚠️  Memory usage is high! Consider reducing workers.');
    }

    if (avgLoad > cpus.length * 0.8) {
      console.warn('⚠️  CPU load is high! Consider reducing workers.');
    }
  }, 5000);

  // Stop monitoring when tests complete
  process.on('exit', () => clearInterval(interval));
}

monitorResources();
```

---

## 10. Best Practices & Recommendations

### 10.1 Test Writing Guidelines

#### ✅ DO:
- Write isolated, independent tests
- Use unique identifiers for test data (timestamps, UUIDs)
- Clean up resources in afterEach hooks
- Use explicit waits instead of sleeps
- Mock external dependencies in unit tests
- Use test.describe.serial for dependent tests
- Add retry logic for flaky external services

#### ❌ DON'T:
- Share state between tests
- Rely on test execution order (except in serial groups)
- Use hardcoded test data that other tests might modify
- Leave test data in database after tests
- Use arbitrary waits (sleep/setTimeout)
- Run expensive operations in beforeAll that affect parallel tests

---

### 10.2 Troubleshooting Checklist

**If tests are flaky:**
1. Check for race conditions in database writes
2. Verify test isolation (each test should be independent)
3. Add explicit waits for async operations
4. Check for shared test data conflicts
5. Run flaky test 10 times to confirm intermittent failure

**If tests are slow:**
1. Profile test execution with `--reporter=list,html`
2. Check for unnecessary waits or retries
3. Mock external API calls in unit tests
4. Optimize database queries and transactions
5. Consider reducing worker count on resource-constrained systems

**If tests fail in CI but pass locally:**
1. Check CI environment variables
2. Verify database and service availability
3. Increase timeouts for slower CI environments
4. Check for missing dependencies or services
5. Review CI logs for resource constraints

---

## 11. Conclusion

This parallelization strategy optimizes CertiGraph's test suite from ~180 minutes (serial) to ~35 minutes (parallel), achieving an **81% reduction in execution time**. Key success factors:

1. **Strict Isolation**: Each worker has its own database, user pool, and file system space
2. **Smart Grouping**: Tests are grouped by dependency and resource usage patterns
3. **Flexible Configuration**: Easy to scale workers based on system resources
4. **Comprehensive Monitoring**: Built-in metrics and flaky test detection
5. **CI/CD Ready**: Optimized configuration for automated pipelines

**Next Steps:**
1. Implement database-per-worker setup scripts
2. Create user pool fixtures
3. Migrate existing tests to new directory structure
4. Run baseline performance benchmarks
5. Configure CI/CD pipeline with parallel execution
6. Monitor and optimize flaky tests

---

## Appendix A: Quick Reference Commands

```bash
# Setup
npm run test:setup                 # Create test databases and seed data
npm run test:cleanup              # Remove all test databases

# Execution
npm run test:all                  # Run all tests (optimized)
npm run test:parallel             # Run only parallel-safe tests
npm run test:sequential           # Run only sequential tests
npm run test:unit                 # Run all unit tests
npm run test:integration          # Run all integration tests
npm run test:e2e                  # Run all E2E tests

# Debugging
npm run test:debug                # Run in debug mode (headed, slowMo)
npm run test:flaky                # Detect flaky tests (10 runs)
npm run test:watch                # Run in watch mode

# CI
npm run test:ci                   # Run with CI configuration
npm run test:coverage             # Generate coverage report

# Monitoring
node scripts/monitor-test-resources.js  # Monitor CPU/Memory during tests
node scripts/generate-test-summary.js   # Generate test summary report
```

---

## Appendix B: Test Data Fixtures

```typescript
// tests/fixtures/test-data.ts
export const TEST_USERS = {
  parallel_1: {
    email: 'parallel-1@test.certigraph.io',
    password: 'Test1234!',
    role: 'student',
    studySets: [],
  },
  sequential_main: {
    email: 'seq-journey@test.certigraph.io',
    password: 'Test1234!',
    role: 'student',
    studySets: [],
  },
  admin: {
    email: 'admin-test@test.certigraph.io',
    password: 'Admin1234!',
    role: 'admin',
  },
};

export const TEST_STUDY_SETS = {
  sample_set_1: {
    name: '정보처리기사 샘플',
    description: 'Test study set for parallel tests',
    certification: '정보처리기사',
    exam_date: '2025-03-15',
  },
};

export const TEST_PDFS = {
  sample_exam: './tests/fixtures/sample-exam.pdf',
  large_exam: './tests/fixtures/large-exam-50mb.pdf',
  malformed: './tests/fixtures/malformed.pdf',
};
```

---

**Document End**

*For questions or updates, contact: Test Architecture Team*
*Last Updated: 2026-01-05*
