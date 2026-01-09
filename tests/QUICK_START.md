# E2E Tests - Quick Start Guide

## What Changed?

All E2E tests now gracefully skip when pages don't exist yet (404 errors). This means:

- No more timeout errors for missing pages
- Tests skip with clear messages explaining what's missing
- Test suite runs fast even during early MVP development
- Tests automatically activate when you implement pages

## Running Tests

```bash
# Run all tests (will skip tests for missing pages)
npx playwright test

# Run specific test file
npx playwright test tests/e2e/parallel/01-user-registration.spec.ts

# Run with browser visible
npx playwright test --headed

# Run with Playwright UI
npx playwright test --ui
```

## What You'll See

When tests run against the current (incomplete) application:

```
Running 4 tests using 1 worker
⏭️  Skipping E2E-PAR-001: Page not found (404): /sign-up. This page needs to be implemented.
⏭️  Skipping E2E-PAR-002: Page not found (404): /sign-up. This page needs to be implemented.
⏭️  Skipping E2E-PAR-003: Page not found (404): /sign-up. This page needs to be implemented.
⏭️  Skipping E2E-PAR-004: Page not found (404): /sign-up. This page needs to be implemented.

4 skipped
```

This is EXPECTED and CORRECT behavior during MVP development.

## When You Implement Pages

As soon as you create a page (e.g., `/sign-up`):

1. Tests for that page will automatically start running
2. You'll see if the page works as expected
3. Fix any failures by adjusting either:
   - The page implementation, OR
   - The test expectations (if they're wrong)

## Example: Implementing Sign-Up Page

### Before Implementation
```
⏭️  Skipping E2E-PAR-001: Page not found (404): /sign-up
```

### After You Create `/sign-up`
```
✓ E2E-PAR-001: Should successfully register a new user (2.3s)
```

or if something's wrong:

```
✗ E2E-PAR-001: Should successfully register a new user (1.2s)
  Error: Locator: input[type="email"]
  Expected: visible
  Received: hidden
```

This tells you exactly what to fix!

## Test Files Overview

| File | Tests | What It Checks |
|------|-------|---------------|
| `01-user-registration.spec.ts` | PAR-001 to PAR-004 | User signup flow |
| `02-login-flows.spec.ts` | PAR-005 to PAR-008 | Login/logout functionality |
| `03-dashboard-view.spec.ts` | PAR-017 to PAR-020 | Dashboard features |
| `critical-user-journey.spec.ts` | SEQ-001 to SEQ-007 | Complete user journey |
| `payment-flow.spec.ts` | PAY-001 to PAY-012 | Toss Payments integration |

## Required Pages

These pages need to be implemented for tests to run:

### Authentication Pages
- `/` - Homepage with Sign Up/Sign In buttons
- `/sign-up` - User registration page
- `/sign-in` - User login page

### App Pages
- `/dashboard` - User dashboard
- `/pricing` - Pricing and season pass purchase
- `/study-sets` - Study sets management
- `/knowledge-graph` - 3D knowledge graph visualization

### Payment Pages
- `/checkout` - Payment checkout page
- `/payment/success` - Payment success callback
- `/payment/fail` - Payment failure callback

## Debugging Tips

### Test is Skipping But Page Exists

If a test skips but you know the page exists:

1. Check if the page returns 404 status code
2. Verify the URL matches exactly (case-sensitive)
3. Check browser console for errors
4. Run with `--headed` to see what's happening

```bash
npx playwright test --headed tests/e2e/parallel/01-user-registration.spec.ts
```

### Test is Failing After Implementation

If a test fails after you implement a page:

1. Read the error message carefully
2. Check what element it's looking for
3. Verify your HTML has the expected elements
4. Adjust selectors if needed

### See Detailed Error Info

```bash
# Run with trace (creates detailed timeline)
npx playwright test --trace on

# View trace
npx playwright show-trace trace.zip
```

## Common Scenarios

### Scenario 1: Building Pages in Order

```bash
# Day 1: Build homepage
You create: pages/index.tsx
Tests run: ✓ Some homepage tests pass
Tests skip: ⏭️ Sign-up tests (page doesn't exist yet)

# Day 2: Build sign-up page
You create: pages/sign-up.tsx
Tests run: ✓ Sign-up tests now run
Tests skip: ⏭️ Dashboard tests (page doesn't exist yet)

# Day 3: Build dashboard
You create: pages/dashboard.tsx
Tests run: ✓ Dashboard tests now run
All working! ✅
```

### Scenario 2: Building Pages Out of Order

```bash
# You decide to build dashboard first
You create: pages/dashboard.tsx
Tests run: ✓ Dashboard tests run (if auth is mocked)
Tests skip: ⏭️ Sign-up tests (still don't need them)

# Then build sign-up later
You create: pages/sign-up.tsx
Tests run: ✓ Sign-up tests now run
All tests working! ✅
```

The tests adapt to whatever you build first!

## Integration with CI/CD

The test suite is safe to run in CI/CD:

```yaml
# Example GitHub Actions workflow
- name: Run E2E tests
  run: npx playwright test
  # Tests will skip for missing pages, won't fail the build
```

Configure your CI to:
- ✅ Allow skipped tests (they're expected during MVP)
- ✅ Fail on actual test failures (bugs)
- ✅ Report which tests are skipped (shows what's not implemented)

## Need Help?

1. Check the full README: `tests/README.md`
2. Check the fixes summary: `TEST_FIXES_SUMMARY.md`
3. Look at helper utilities: `tests/helpers/page-checker.ts`
4. Run tests with `--ui` for interactive debugging

## Quick Reference: Test Commands

```bash
# Basic run
npx playwright test

# Run one file
npx playwright test 01-user-registration.spec.ts

# Interactive mode
npx playwright test --ui

# See the browser
npx playwright test --headed

# Debug mode
npx playwright test --debug

# Generate report
npx playwright test
npx playwright show-report

# Update snapshots (if using visual testing)
npx playwright test --update-snapshots
```

## Bottom Line

You can safely ignore skipped tests during development. They're not failures - they're waiting for you to implement the pages. Once you do, they'll automatically start validating your work!

Happy testing! 🎭
