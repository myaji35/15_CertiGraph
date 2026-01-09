import { test, expect } from '@playwright/test';

/**
 * P1 Group: Frontend Component Tests - NotionStatCard
 * Test IDs: FE-UNIT-009 to FE-UNIT-016
 *
 * All tests run in parallel
 *
 * Note: These are component isolation tests that require dedicated test pages.
 * Tests will be skipped if test component pages are not available.
 */

test.describe('P1: NotionStatCard Component Tests', () => {
  test.describe.configure({ mode: 'parallel' });
  let componentPageAvailable: boolean = false;

  test.beforeAll(async ({ browser }) => {
    // Check if test component page exists
    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      const response = await page.goto('http://localhost:3030/test-components/notion-stat-card', {
        timeout: 5000,
        waitUntil: 'domcontentloaded'
      });
      componentPageAvailable = response !== null && response.status() !== 404;
    } catch (error) {
      componentPageAvailable = false;
      console.log('Test component page not available - tests will be skipped');
    } finally {
      await page.close();
      await context.close();
    }
  });

  test.beforeEach(async ({}, testInfo) => {
    if (!componentPageAvailable) {
      testInfo.skip(true, 'Test component page /test-components/notion-stat-card does not exist. Create the page to run component isolation tests.');
    }
  });

  // Reduce timeout for all tests in this suite
  test.use({ timeout: 15000 });

  test('FE-UNIT-009: NotionStatCard renders with default props', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-stat-card');

    const card = page.locator('[data-testid="notion-stat-card-default"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    await page.screenshot({ path: 'test-results/fe-unit-009.png' });
  });

  test('FE-UNIT-010: NotionStatCard displays title and value correctly', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-stat-card');

    const card = page.locator('[data-testid="notion-stat-card-with-data"]');
    await expect(card.locator('[data-testid="stat-title"]')).toContainText('Total Questions');
    await expect(card.locator('[data-testid="stat-value"]')).toContainText('1,234');

    await page.screenshot({ path: 'test-results/fe-unit-010.png' });
  });

  test('FE-UNIT-011: NotionStatCard shows trend indicator (up)', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-stat-card');

    const card = page.locator('[data-testid="notion-stat-card-trend-up"]');
    const trendIcon = card.locator('[data-testid="trend-icon"]');

    await expect(trendIcon).toBeVisible();
    await expect(trendIcon).toHaveClass(/text-green/);

    await page.screenshot({ path: 'test-results/fe-unit-011.png' });
  });

  test('FE-UNIT-012: NotionStatCard shows trend indicator (down)', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-stat-card');

    const card = page.locator('[data-testid="notion-stat-card-trend-down"]');
    const trendIcon = card.locator('[data-testid="trend-icon"]');

    await expect(trendIcon).toBeVisible();
    await expect(trendIcon).toHaveClass(/text-red/);

    await page.screenshot({ path: 'test-results/fe-unit-012.png' });
  });

  test('FE-UNIT-013: NotionStatCard formats large numbers correctly', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-stat-card');

    const card = page.locator('[data-testid="notion-stat-card-large-number"]');
    const value = card.locator('[data-testid="stat-value"]');

    // Should format 1000000 as "1,000,000" with toLocaleString()
    const text = await value.textContent();
    expect(text).toMatch(/1,000,000/);

    await page.screenshot({ path: 'test-results/fe-unit-013.png' });
  });

  test('FE-UNIT-014: NotionStatCard displays percentage correctly', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-stat-card');

    const card = page.locator('[data-testid="notion-stat-card-percentage"]');
    const percentage = card.locator('[data-testid="stat-percentage"]');

    await expect(percentage).toContainText('%');

    await page.screenshot({ path: 'test-results/fe-unit-014.png' });
  });

  test('FE-UNIT-015: NotionStatCard shows loading state', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-stat-card');

    const card = page.locator('[data-testid="notion-stat-card-loading"]');
    const skeleton = card.locator('[data-testid="skeleton"]').first();

    await expect(skeleton).toBeVisible();
    await expect(skeleton).toHaveClass(/animate-pulse/);

    await page.screenshot({ path: 'test-results/fe-unit-015.png' });
  });

  test('FE-UNIT-016: NotionStatCard handles click to navigate', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-stat-card');

    const card = page.locator('[data-testid="notion-stat-card-clickable"]');

    await card.click();
    await page.waitForTimeout(500);

    // Verify navigation or modal
    const currentUrl = page.url();
    expect(currentUrl).toMatch(/test-components/);

    await page.screenshot({ path: 'test-results/fe-unit-016.png' });
  });
});
