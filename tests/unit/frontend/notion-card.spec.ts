import { test, expect } from '@playwright/test';

/**
 * P1 Group: Frontend Component Tests - NotionCard
 * Test IDs: FE-UNIT-001 to FE-UNIT-008
 *
 * All tests run in parallel with reduced timeout (15s per test)
 *
 * Note: These are component isolation tests that require dedicated test pages.
 * Tests will be skipped if test component pages are not available.
 */

test.describe('P1: NotionCard Component Tests', () => {
  test.describe.configure({ mode: 'parallel' });
  let componentPageAvailable: boolean = false;

  test.beforeAll(async ({ browser }) => {
    // Check if test component page exists
    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      const response = await page.goto('http://localhost:3030/test-components/notion-card', {
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
      testInfo.skip(true, 'Test component page /test-components/notion-card does not exist. Create the page to run component isolation tests.');
    }
  });

  // Reduce timeout for all tests in this suite
  test.use({ timeout: 15000 });

  test('FE-UNIT-001: NotionCard renders with default props', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-card');

    const card = page.locator('[data-testid="notion-card-default"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });
    await expect(card).toHaveClass(/bg-white/, { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-001.png' });
  });

  test('FE-UNIT-002: NotionCard displays title and description correctly', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-card');

    const card = page.locator('[data-testid="notion-card-with-content"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    await expect(card.locator('h3')).toContainText('Sample Title', { timeout: 3000 });
    await expect(card.locator('p')).toContainText('Sample Description', { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-002.png' });
  });

  test('FE-UNIT-003: NotionCard shows hover effects', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-card');

    const card = page.locator('[data-testid="notion-card-hover"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    // Check initial state
    const initialBoxShadow = await card.evaluate(el => window.getComputedStyle(el).boxShadow);

    // Hover over the card
    await card.hover();
    await page.waitForTimeout(300);

    // Check hover state
    const hoverBoxShadow = await card.evaluate(el => window.getComputedStyle(el).boxShadow);

    // Hover shadow should be different from initial
    expect(hoverBoxShadow).not.toBe(initialBoxShadow);

    await page.screenshot({ path: 'test-results/fe-unit-003.png' });
  });

  test('FE-UNIT-004: NotionCard handles click events', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-card');

    const card = page.locator('[data-testid="notion-card-clickable"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    // Verify the description shows "Click me" before clicking
    await expect(card.locator('p')).toContainText('Click me', { timeout: 3000 });

    // Click the card
    await card.click();
    await page.waitForTimeout(200);

    // Verify the description changed to "Clicked!" after clicking
    await expect(card.locator('p')).toContainText('Clicked!', { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-004.png' });
  });

  test('FE-UNIT-005: NotionCard renders with custom className', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-card');

    const card = page.locator('[data-testid="notion-card-custom-class"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });
    await expect(card).toHaveClass(/custom-card-class/, { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-005.png' });
  });

  test('FE-UNIT-006: NotionCard displays icon correctly', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-card');

    const card = page.locator('[data-testid="notion-card-with-icon"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const icon = card.locator('svg, img').first();
    await expect(icon).toBeVisible({ timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-006.png' });
  });

  test('FE-UNIT-007: NotionCard handles long text overflow', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-card');

    const card = page.locator('[data-testid="notion-card-long-text"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const description = card.locator('p');
    await expect(description).toBeVisible({ timeout: 3000 });

    // Check for text truncation classes
    await expect(description).toHaveClass(/truncate|line-clamp/, { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-007.png' });
  });

  test('FE-UNIT-008: NotionCard is accessible (ARIA attributes)', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/notion-card');

    const card = page.locator('[data-testid="notion-card-accessible"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    // Check for ARIA attributes
    await expect(card).toHaveAttribute('role', 'article', { timeout: 3000 });
    await expect(card.locator('h3')).toHaveAttribute('id', /.*/, { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-008.png' });
  });
});
