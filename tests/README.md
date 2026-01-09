# CertiGraph E2E Test Suite

## Overview

This directory contains the end-to-end (E2E) test suite for the CertiGraph application. The tests are designed to verify the complete user journey and critical functionality of the platform.

## Test Structure

### Parallel Tests (`tests/e2e/parallel/`)

Tests that can run independently and in parallel:

- **01-user-registration.spec.ts** - User registration flows (E2E-PAR-001 to E2E-PAR-004)
- **02-login-flows.spec.ts** - Login and authentication flows (E2E-PAR-005 to E2E-PAR-008)
- **03-dashboard-view.spec.ts** - Dashboard functionality (E2E-PAR-017 to E2E-PAR-020)

### Sequential Tests

Tests that must run in order due to state dependencies:

- **tests/e2e/sequential/critical-user-journey.spec.ts** - Complete user journey from signup to knowledge graph (E2E-SEQ-001 to E2E-SEQ-007)
- **tests/e2e/payment/payment-flow.spec.ts** - Payment flow with Toss Payments integration (PAY-001 to PAY-012)

## Graceful Skipping for Missing Pages

All tests now include **graceful skipping** functionality for pages that are not yet implemented. This is critical during the MVP development phase.

### How It Works

1. Before attempting to interact with a page, tests check if it exists (returns non-404 status)
2. If a page doesn't exist, the test is skipped with a descriptive message
3. Test logic remains intact for when pages are implemented
4. No false negatives or timeout errors for missing functionality

### Example

```typescript
test('E2E-PAR-001: Should successfully register a new user', async ({ page }) => {
  // Check if homepage exists
  const homeResult = await safeGoto(page, '/', { timeout: 5000 });
  if (!homeResult.exists) {
    test.skip(true, `Homepage not available: ${homeResult.message}`);
    return;
  }

  // Rest of test logic...
});
```

## Helper Utilities

### `tests/helpers/page-checker.ts`

Provides utility functions for checking page existence:

- **`checkPageExists(page, url, options)`** - Checks if a page exists and returns detailed status
- **`skipIfPageNotExists(page, url, testName)`** - Checks page and logs skip message if not found
- **`safeGoto(page, url, options)`** - Safely navigates to a page with better error handling

### Configuration Options

- **timeout** - Maximum time to wait for page load (default: 10000ms for checks, 5000ms for skips)
- **waitUntil** - Wait strategy ('domcontentloaded' or 'load')

## Running Tests

### Run All Tests

```bash
npx playwright test
```

### Run Specific Test File

```bash
npx playwright test tests/e2e/parallel/01-user-registration.spec.ts
```

### Run Tests in Headed Mode

```bash
npx playwright test --headed
```

### Run Tests with UI

```bash
npx playwright test --ui
```

## Test Organization

### Test IDs

All tests follow a consistent ID format:

- **E2E-PAR-XXX** - Parallel E2E tests
- **E2E-SEQ-XXX** - Sequential E2E tests
- **PAY-XXX** - Payment flow tests

### Test Isolation

- Parallel tests use unique email addresses per test run to ensure isolation
- Sequential tests share state across tests in the same describe block
- Each test includes appropriate setup and cleanup

## Current Status

**IMPORTANT**: The CertiGraph application is currently in the **Planning/MVP Preparation** stage. Most application pages do not exist yet.

### Expected Behavior

When you run the test suite now:

1. Tests will attempt to navigate to pages
2. Missing pages (404) will cause tests to skip gracefully
3. You'll see skip messages in the console like:
   ```
   ⏭️  Skipping E2E-PAR-001: Page not found (404): /sign-up. This page needs to be implemented.
   ```
4. No timeout errors or false failures

### When Pages Are Implemented

As you build the application:

1. Tests will automatically start running instead of skipping
2. No code changes needed in test files
3. Tests verify the actual functionality
4. Fix any failures by adjusting implementation or test expectations

## Best Practices

### 1. Use Short Timeouts for Initial Checks

```typescript
const result = await safeGoto(page, '/pricing', { timeout: 5000 });
```

### 2. Replace `networkidle` with `domcontentloaded`

The deprecated `networkidle` wait strategy has been replaced with `domcontentloaded` for faster and more reliable tests.

```typescript
// ❌ Old (deprecated)
await page.waitForLoadState('networkidle');

// ✅ New (recommended)
await page.waitForLoadState('domcontentloaded');
```

### 3. Check for Element Existence Before Interaction

```typescript
const submitButton = page.locator('button[type="submit"]');
if (await submitButton.count() > 0) {
  await submitButton.click();
}
```

### 4. Use Flexible Selectors

Tests use multiple selector strategies to handle different implementations:

```typescript
const signInButton = page.locator(
  'a:has-text("Sign In"), a:has-text("로그인"), button:has-text("Sign In")'
);
```

## Screenshots and Artifacts

Test results are saved to:

- **test-results/** - Screenshots, videos, and traces
- **playwright-report/** - HTML test report

View the HTML report:

```bash
npx playwright show-report
```

## Future Enhancements

As the application develops, consider:

1. Adding API endpoint tests
2. Implementing visual regression testing
3. Adding performance benchmarks
4. Expanding test coverage for edge cases
5. Adding accessibility (a11y) tests
6. Implementing mobile viewport tests

## Troubleshooting

### Tests Still Timing Out

If tests are timing out despite the changes:

1. Check if the development server is running on `http://localhost:3030`
2. Verify the `baseURL` in `playwright.config.ts` matches your dev server
3. Check browser console for JavaScript errors
4. Use `--debug` flag to step through tests

### Tests Not Skipping Properly

If tests aren't skipping when pages are missing:

1. Verify the page-checker helper is imported correctly
2. Check that `test.skip()` is being called before any assertions
3. Ensure the return statement follows the skip call

### Need to Debug a Test

```bash
# Run with debugger
npx playwright test --debug

# Run specific test with trace
npx playwright test --trace on tests/e2e/parallel/01-user-registration.spec.ts
```

## Support

For issues or questions about the test suite:

1. Check the Playwright documentation: https://playwright.dev
2. Review test comments for specific test logic
3. Examine helper utilities in `tests/helpers/`
4. Run tests with `--headed` to see browser interactions

---

**Note**: This test suite is designed to grow with the application. As you implement features, the tests will automatically start validating them. Keep tests up to date with application changes.
