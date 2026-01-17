# Port Update Progress - Playwright Tests

**Date:** 2026-01-15
**Task:** Update all tests from localhost:3030 (Next.js) to localhost:3000 (Rails)

---

## Files Updated

### Phase 1: Configuration & Helpers ✅

1. ✅ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/playwright.config.ts`
   - Updated webServer command to use Rails
   - Changed port from 3030 to 3000
   - baseURL already set to localhost:3000

2. ✅ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/helpers/rails-auth-helper.ts`
   - Created new helper for Rails/Devise authentication
   - Provides loginAsUser, registerUser, logout functions
   - Uses correct Rails form field names

### Phase 2: Critical E2E Tests ✅

3. ✅ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-simple-test.spec.ts`
   - All 9 tests updated to use localhost:3000
   - Updated routes: /login → /users/sign_in, /signup → /users/sign_up
   - Updated selectors for Rails forms

4. ✅ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-knowledge-graph.spec.ts`
   - All 30+ tests updated to use localhost:3000
   - Imported and using rails-auth-helper
   - All FRONTEND_URL references replaced with BASE_URL

### Phase 3: Remaining E2E Tests (In Progress)

Files needing update (localhost:3030 → localhost:3000):

5. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-study-materials.spec.ts`
6. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-security.spec.ts`
7. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-performance.spec.ts`
8. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-payment.spec.ts`
9. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-mock-exam.spec.ts`
10. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-integration.spec.ts`
11. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-full-test.spec.ts`
12. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-auth-comprehensive.spec.ts`
13. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/bmad-auth-social-password.spec.ts`
14. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/e2e/parallel/02-login-flows.spec.ts`

### Phase 4: Frontend Unit Tests (To Review)

15. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/unit/frontend/question-card.spec.ts`
16. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/unit/frontend/notion-card.spec.ts`
17. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/tests/unit/frontend/notion-stat-card.spec.ts`

Note: Frontend unit tests may need to be skipped if testing React components that don't exist in Rails

### Phase 5: Root-Level Tests

18. ✅ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-quick-test.spec.ts` (already correct)
19. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/test-calendar.spec.ts`
20. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/debug-calendar.spec.ts`
21. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/seed.spec.ts`
22. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/test_vip_subscription.spec.ts`
23. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/test-vip-pass.spec.ts`
24. ⏳ `/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/test-vip-pass-comprehensive.spec.ts`

---

## Required Changes Per File

### Standard Replacements

1. **Port Update:**
   ```typescript
   // OLD
   const FRONTEND_URL = 'http://localhost:3030';
   const API_BASE = 'http://localhost:8015/api/v1';

   // NEW
   const BASE_URL = 'http://localhost:3000';
   ```

2. **Import Auth Helper:**
   ```typescript
   import { loginAsUser } from '../helpers/rails-auth-helper';
   // Or appropriate relative path
   ```

3. **Update Routes:**
   - `/login` → `/users/sign_in`
   - `/signup` → `/users/sign_up`
   - `/logout` → `/users/sign_out`

4. **Update Selectors:**
   ```typescript
   // OLD (Next.js/Clerk)
   await page.fill('[name="email"]', 'test@example.com');

   // NEW (Rails/Devise)
   await page.fill('input[name="user[email]"]', 'test@example.com');
   ```

5. **Update loginAsUser Calls:**
   ```typescript
   // OLD
   await loginAsUser(page);

   // NEW
   await loginAsUser(page, 'test@example.com', 'Test1234!');
   ```

---

## Test Execution Status

### Ready to Test

Files that can be tested now:
- ✅ `playwright.config.ts` - Configuration valid
- ✅ `rails-quick-test.spec.ts` - Should pass
- ✅ `bmad-simple-test.spec.ts` - Ready for testing
- ✅ `bmad-knowledge-graph.spec.ts` - Ready for testing

### Next Steps

1. **Immediate (15 min):**
   - Test updated files to verify port fix worked
   - Run: `npx playwright test rails-quick-test.spec.ts --reporter=list`
   - Run: `npx playwright test tests/e2e/bmad-simple-test.spec.ts --reporter=list`

2. **Short-term (2 hours):**
   - Update remaining bmad-*.spec.ts files (9 files)
   - Update parallel/02-login-flows.spec.ts
   - Test each file after update

3. **Medium-term (1 hour):**
   - Review and update or skip frontend unit tests
   - Update root-level test files
   - Run full test suite

---

## Commands for Testing

```bash
# Test single updated file
npx playwright test rails-quick-test.spec.ts --reporter=list

# Test simple tests
npx playwright test tests/e2e/bmad-simple-test.spec.ts --reporter=list

# Test knowledge graph (will likely have selector issues to fix)
npx playwright test tests/e2e/bmad-knowledge-graph.spec.ts --reporter=list --headed

# Run all updated tests (after completing updates)
npx playwright test tests/e2e/bmad-simple-test.spec.ts tests/e2e/bmad-knowledge-graph.spec.ts
```

---

## Expected Results

### After Port Fix (Immediate)

- ❌ **Before:** Error: net::ERR_CONNECTION_REFUSED at http://localhost:3030/
- ✅ **After:** Tests connect to Rails server successfully

### After Selector Fix (Short-term)

- Tests run but may fail on element not found
- Need to inspect actual Rails HTML and update selectors
- Use browser DevTools or `await page.content()` to debug

### Full Success (Medium-term)

- 60-70% of tests passing
- Remaining failures due to:
  - Missing features (not yet implemented)
  - Timing issues (need waits)
  - Data issues (need fixtures/seeds)

---

## Risk Mitigation

### Known Issues

1. **Knowledge Graph Pages:** May not exist yet in Rails
   - Solution: Mark as `.skip()` or `.fixme()` if not implemented

2. **Frontend Unit Tests:** Testing React components that don't exist
   - Solution: Skip entire test files for now

3. **API Endpoints:** Some tests expect API responses
   - Solution: Update to use Rails routes or skip

### Fallback Strategy

If too many features don't exist yet:
- Mark unimplemented features as `.fixme()` with comments
- Focus on testing implemented features
- Document what needs to be implemented

---

## Progress Summary

- **Completed:** 4 files (config + 3 test files)
- **Remaining:** ~20 test files
- **Estimated Time:** 3-4 hours total
- **Blocking Issues Resolved:** ✅ Port mismatch fixed

**Next Action:** Test the updated files to verify the fix works before proceeding with bulk updates.
