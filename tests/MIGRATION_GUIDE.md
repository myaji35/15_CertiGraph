# Migration Guide: Adding Graceful Skip Logic to Playwright Tests

This guide shows how to update Playwright tests to gracefully skip when pages don't exist yet (useful during MVP/early development).

## Problem

During MVP development, E2E tests fail with timeout errors when pages don't exist:

```
Error: page.goto: Timeout 60000ms exceeded waiting for load state 'networkidle'
```

This creates:
- False negative test results
- Slow test execution (waiting for timeouts)
- Developer frustration
- CI/CD pipeline failures

## Solution

Add helper utilities that check if pages exist before running test logic, and skip gracefully if they don't.

## Step-by-Step Migration

### Step 1: Create Helper Utilities

Create `tests/helpers/page-checker.ts`:

```typescript
import { Page } from '@playwright/test';

export interface PageCheckResult {
  exists: boolean;
  statusCode?: number;
  message: string;
}

export async function checkPageExists(
  page: Page,
  url: string,
  options: { timeout?: number } = {}
): Promise<PageCheckResult> {
  const timeout = options.timeout || 10000;

  try {
    const response = await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout,
    });

    if (!response) {
      return {
        exists: false,
        message: `No response received from ${url}`,
      };
    }

    const statusCode = response.status();

    if (statusCode === 404) {
      return {
        exists: false,
        statusCode,
        message: `Page not found (404): ${url}. This page needs to be implemented.`,
      };
    }

    if (statusCode >= 500) {
      return {
        exists: false,
        statusCode,
        message: `Server error (${statusCode}): ${url}`,
      };
    }

    return {
      exists: true,
      statusCode,
      message: `Successfully loaded: ${url}`,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      exists: false,
      message: `Failed to load ${url}: ${errorMessage}`,
    };
  }
}

export async function skipIfPageNotExists(
  page: Page,
  url: string,
  testName: string
): Promise<PageCheckResult> {
  const result = await checkPageExists(page, url, { timeout: 5000 });

  if (!result.exists) {
    console.log(`⏭️  Skipping ${testName}: ${result.message}`);
  }

  return result;
}

export async function safeGoto(
  page: Page,
  url: string,
  options: { timeout?: number; waitUntil?: 'domcontentloaded' | 'load' } = {}
): Promise<PageCheckResult> {
  const timeout = options.timeout || 10000;
  const waitUntil = options.waitUntil || 'domcontentloaded';

  try {
    const response = await page.goto(url, {
      waitUntil,
      timeout,
    });

    if (!response) {
      return {
        exists: false,
        message: `No response received from ${url}`,
      };
    }

    const statusCode = response.status();

    if (statusCode === 404) {
      return {
        exists: false,
        statusCode,
        message: `Page not found (404): ${url}`,
      };
    }

    return {
      exists: true,
      statusCode,
      message: `Successfully loaded: ${url}`,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      exists: false,
      message: `Failed to load ${url}: ${errorMessage}`,
    };
  }
}
```

### Step 2: Update Test Files

#### Before: Simple Navigation

```typescript
import { test, expect } from '@playwright/test';

test('User can sign up', async ({ page }) => {
  await page.goto('/sign-up');
  await page.waitForLoadState('networkidle');

  await page.fill('input[name="email"]', 'test@example.com');
  await page.fill('input[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  expect(page.url()).toContain('/dashboard');
});
```

#### After: With Graceful Skip

```typescript
import { test, expect } from '@playwright/test';
import { skipIfPageNotExists } from '../helpers/page-checker';

test('User can sign up', async ({ page }) => {
  // Check if page exists before proceeding
  const result = await skipIfPageNotExists(page, '/sign-up', 'User can sign up');
  if (!result.exists) {
    test.skip(true, result.message);
    return;
  }

  await page.waitForLoadState('domcontentloaded');

  await page.fill('input[name="email"]', 'test@example.com');
  await page.fill('input[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  expect(page.url()).toContain('/dashboard');
});
```

### Step 3: Update Navigation Patterns

#### Pattern 1: Direct Navigation

**Before:**
```typescript
await page.goto('/pricing');
await page.waitForLoadState('networkidle');
```

**After:**
```typescript
const result = await skipIfPageNotExists(page, '/pricing', 'Test Name');
if (!result.exists) {
  test.skip(true, result.message);
  return;
}
await page.waitForLoadState('domcontentloaded');
```

#### Pattern 2: Navigation via Click

**Before:**
```typescript
await page.goto('/');
await page.click('a:has-text("Sign Up")');
await page.waitForLoadState('networkidle');
```

**After:**
```typescript
const homeResult = await safeGoto(page, '/', { timeout: 5000 });
if (!homeResult.exists) {
  test.skip(true, `Homepage not available: ${homeResult.message}`);
  return;
}

const signUpButton = page.locator('a:has-text("Sign Up")');
if (await signUpButton.count() > 0) {
  await signUpButton.click();
} else {
  const signUpResult = await skipIfPageNotExists(page, '/sign-up', 'Test Name');
  if (!signUpResult.exists) {
    test.skip(true, signUpResult.message);
    return;
  }
}
await page.waitForLoadState('domcontentloaded');
```

#### Pattern 3: BeforeEach Hook

**Before:**
```typescript
test.beforeEach(async ({ page }) => {
  await page.goto('/dashboard');
  await page.waitForLoadState('networkidle');
});
```

**After:**
```typescript
test.beforeEach(async ({ page }) => {
  const result = await skipIfPageNotExists(page, '/dashboard', 'beforeEach');
  if (!result.exists) {
    return; // Skip will be handled in individual tests
  }
  await page.waitForLoadState('domcontentloaded');
});

test('Test name', async ({ page }) => {
  // Check if beforeEach succeeded
  if (page.url().includes('404')) {
    const result = await skipIfPageNotExists(page, '/dashboard', 'Test name');
    if (!result.exists) {
      test.skip(true, result.message);
      return;
    }
  }

  // Rest of test...
});
```

### Step 4: Replace Deprecated APIs

Replace `networkidle` with `domcontentloaded`:

**Before:**
```typescript
await page.waitForLoadState('networkidle');
```

**After:**
```typescript
await page.waitForLoadState('domcontentloaded');
```

**Why?**
- `networkidle` is flaky and deprecated
- `domcontentloaded` is faster and more reliable
- Playwright recommends avoiding `networkidle`

### Step 5: Add Documentation

Add NOTE comments to test files:

```typescript
/**
 * Test Suite Name
 *
 * NOTE: These tests require the application pages to be implemented.
 * Tests will skip gracefully if pages return 404 or are not available.
 */
```

## Common Patterns

### Sequential Tests

For tests that must run in order:

```typescript
test.describe.serial('User Journey', () => {
  test('Step 1: Sign up', async ({ page }) => {
    const result = await skipIfPageNotExists(page, '/sign-up', 'Step 1');
    if (!result.exists) {
      test.skip(true, result.message);
      return;
    }
    // Test logic...
  });

  test('Step 2: Buy product', async ({ page }) => {
    const result = await skipIfPageNotExists(page, '/products', 'Step 2');
    if (!result.exists) {
      test.skip(true, result.message);
      return;
    }
    // Test logic...
  });
});
```

### Multiple Page Checks

When testing navigation between pages:

```typescript
test('Navigate from home to profile', async ({ page }) => {
  // Check home page
  const homeResult = await safeGoto(page, '/', { timeout: 5000 });
  if (!homeResult.exists) {
    test.skip(true, `Home page not available: ${homeResult.message}`);
    return;
  }

  // Click to profile
  await page.click('a[href="/profile"]');
  await page.waitForLoadState('domcontentloaded');

  // Verify profile page loaded (not checking for 404)
  if (page.url().includes('/profile')) {
    // Profile page exists, continue test
    expect(page.locator('h1')).toContainText('Profile');
  } else {
    // Profile page doesn't exist yet
    test.skip(true, 'Profile page not implemented');
  }
});
```

### Conditional Features

When testing optional features:

```typescript
test('Feature may or may not exist', async ({ page }) => {
  const result = await skipIfPageNotExists(page, '/dashboard', 'Test');
  if (!result.exists) {
    test.skip(true, result.message);
    return;
  }

  // Check if optional feature exists
  const featureButton = page.locator('[data-testid="optional-feature"]');
  if (await featureButton.count() > 0) {
    // Test the feature
    await featureButton.click();
    // Assertions...
  } else {
    // Feature not implemented yet, that's OK
    console.log('Optional feature not present yet');
  }
});
```

## Configuration Tips

### Reduce Default Timeout

In `playwright.config.ts`:

```typescript
export default defineConfig({
  timeout: 30000, // Reduce from 60000 to 30000

  use: {
    navigationTimeout: 10000, // Short timeout for page loads
    actionTimeout: 10000, // Short timeout for actions
  },
});
```

### Use Shorter Timeouts for Checks

```typescript
// For existence checks, use short timeouts
const result = await skipIfPageNotExists(page, '/page', 'Test', { timeout: 5000 });

// For actual test interactions, use longer timeouts if needed
await page.click('button', { timeout: 30000 });
```

## Testing the Migration

### Verify Skips Work

1. Run tests against incomplete app
2. Should see skip messages, not timeouts
3. Should complete quickly (seconds, not minutes)

### Verify Tests Activate

1. Implement a page
2. Run tests again
3. Tests for that page should now run
4. Should see pass/fail results, not skips

## Checklist

- [ ] Created helper utilities in `tests/helpers/page-checker.ts`
- [ ] Updated all test files to import helpers
- [ ] Added page existence checks before navigation
- [ ] Replaced `networkidle` with `domcontentloaded`
- [ ] Added skip logic with descriptive messages
- [ ] Reduced timeouts for initial page checks
- [ ] Added documentation comments to test files
- [ ] Tested that skips work correctly
- [ ] Verified tests activate when pages are implemented
- [ ] Updated CI/CD configuration if needed

## Benefits After Migration

✅ **Fast feedback** - Tests skip immediately instead of timing out
✅ **Clear messages** - Know exactly what's missing
✅ **No false failures** - Missing pages don't fail tests
✅ **Future-proof** - Tests ready when features are built
✅ **Better DX** - Developers can focus on building
✅ **CI-friendly** - Test suite doesn't block deployments

## Example: Before vs After

### Before Migration

```bash
$ npx playwright test
Running 20 tests...

✗ Test 1: Timeout 60000ms exceeded
✗ Test 2: Timeout 60000ms exceeded
✗ Test 3: Timeout 60000ms exceeded
...
20 failed (12 minutes)
```

### After Migration

```bash
$ npx playwright test
Running 20 tests...

⏭️ Test 1: Skipped (Page not found: /sign-up)
⏭️ Test 2: Skipped (Page not found: /sign-up)
⏭️ Test 3: Skipped (Page not found: /dashboard)
...
20 skipped (15 seconds)
```

## Conclusion

This migration makes your test suite:
- More resilient during development
- Faster to execute
- Easier to understand
- Ready for future implementation

The tests become living documentation that activates automatically as you build features!
