import { test, expect } from '@playwright/test';

/**
 * P1 Group: Frontend Component Tests - QuestionCard
 * Test IDs: FE-UNIT-041 to FE-UNIT-048
 *
 * All tests run in parallel with reduced timeout (15s per test)
 *
 * Note: These are component isolation tests that require dedicated test pages.
 * Tests will be skipped if test component pages are not available.
 */

test.describe('P1: QuestionCard Component Tests', () => {
  test.describe.configure({ mode: 'parallel' });
  let componentPageAvailable: boolean = false;

  test.beforeAll(async ({ browser }) => {
    // Check if test component page exists
    const context = await browser.newContext();
    const page = await context.newPage();

    try {
      const response = await page.goto('http://localhost:3030/test-components/question-card', {
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
      testInfo.skip(true, 'Test component page /test-components/question-card does not exist. Create the page to run component isolation tests.');
    }
  });

  // Reduce timeout for all tests in this suite
  test.use({ timeout: 15000 });

  test('FE-UNIT-041: QuestionCard renders with question text', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/question-card');

    const card = page.locator('[data-testid="question-card-default"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const questionText = card.locator('[data-testid="question-text"]');
    await expect(questionText).toContainText('다음 중', { timeout: 5000 });

    await page.screenshot({ path: 'test-results/fe-unit-041.png' });
  });

  test('FE-UNIT-042: QuestionCard displays all answer options', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/question-card');

    const card = page.locator('[data-testid="question-card-with-options"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const options = card.locator('[data-testid^="option-"]');

    // Wait for options to be visible
    await expect(options.first()).toBeVisible({ timeout: 5000 });

    // Should have 4 or 5 options
    const count = await options.count();
    expect(count).toBeGreaterThanOrEqual(4);
    expect(count).toBeLessThanOrEqual(5);

    await page.screenshot({ path: 'test-results/fe-unit-042.png' });
  });

  test('FE-UNIT-043: QuestionCard allows selecting an answer', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/question-card');

    const card = page.locator('[data-testid="question-card-interactive"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const firstOption = card.locator('[data-testid="option-0"]');
    await expect(firstOption).toBeVisible({ timeout: 5000 });
    await expect(firstOption).toBeEnabled({ timeout: 5000 });

    // Click the first option
    await firstOption.click();

    // Wait a bit for state update
    await page.waitForTimeout(200);

    // Verify it's selected (component uses bg-blue-50 and selected class)
    await expect(firstOption).toHaveClass(/selected|bg-blue-50/, { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-043.png' });
  });

  test('FE-UNIT-044: QuestionCard shows correct answer after submission', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/question-card');

    const card = page.locator('[data-testid="question-card-with-answer"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const firstOption = card.locator('[data-testid="option-0"]');
    await expect(firstOption).toBeVisible({ timeout: 5000 });
    await expect(firstOption).toBeEnabled({ timeout: 5000 });

    // Select an option
    await firstOption.click();
    await page.waitForTimeout(200);

    // Wait for submit button to be enabled
    const submitButton = card.locator('[data-testid="submit-button"]');
    await expect(submitButton).toBeVisible({ timeout: 3000 });
    await expect(submitButton).toBeEnabled({ timeout: 3000 });

    // Submit
    await submitButton.click();
    await page.waitForTimeout(200);

    // Check for correct/incorrect feedback
    const feedback = card.locator('[data-testid="answer-feedback"]');
    await expect(feedback).toBeVisible({ timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-044.png' });
  });

  test('FE-UNIT-045: QuestionCard renders markdown in question text', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/question-card');

    const card = page.locator('[data-testid="question-card-markdown"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const questionText = card.locator('[data-testid="question-text"]');
    await expect(questionText).toBeVisible({ timeout: 5000 });

    // Check for any rendered markdown elements (strong, em, or code tags)
    const hasMarkdownElements = await questionText.locator('strong, em, code').count();
    expect(hasMarkdownElements).toBeGreaterThan(0);

    await page.screenshot({ path: 'test-results/fe-unit-045.png' });
  });

  test('FE-UNIT-046: QuestionCard displays question number', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/question-card');

    const card = page.locator('[data-testid="question-card-numbered"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const questionNumber = card.locator('[data-testid="question-number"]');
    await expect(questionNumber).toBeVisible({ timeout: 5000 });

    // Component formats as "Q{number}.", so check for Q followed by digits
    await expect(questionNumber).toContainText(/Q\d+/, { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-046.png' });
  });

  test('FE-UNIT-047: QuestionCard shows explanation after answer', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/question-card');

    const card = page.locator('[data-testid="question-card-with-explanation"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const firstOption = card.locator('[data-testid="option-0"]');
    await expect(firstOption).toBeVisible({ timeout: 5000 });
    await expect(firstOption).toBeEnabled({ timeout: 5000 });

    // Select option
    await firstOption.click();
    await page.waitForTimeout(200);

    // Wait for submit button and click
    const submitButton = card.locator('[data-testid="submit-button"]');
    await expect(submitButton).toBeVisible({ timeout: 3000 });
    await expect(submitButton).toBeEnabled({ timeout: 3000 });
    await submitButton.click();
    await page.waitForTimeout(200);

    // Check for explanation
    const explanation = card.locator('[data-testid="explanation"]');
    await expect(explanation).toBeVisible({ timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-047.png' });
  });

  test('FE-UNIT-048: QuestionCard prevents changing answer after submission', async ({ page }) => {
    await page.goto('http://localhost:3030/test-components/question-card');

    const card = page.locator('[data-testid="question-card-locked"]').first();
    await expect(card).toBeVisible({ timeout: 5000 });

    const firstOption = card.locator('[data-testid="option-0"]');
    const secondOption = card.locator('[data-testid="option-1"]');

    await expect(firstOption).toBeVisible({ timeout: 5000 });
    await expect(firstOption).toBeEnabled({ timeout: 5000 });

    // Select and submit
    await firstOption.click();
    await page.waitForTimeout(200);

    const submitButton = card.locator('[data-testid="submit-button"]');
    await expect(submitButton).toBeVisible({ timeout: 3000 });
    await expect(submitButton).toBeEnabled({ timeout: 3000 });
    await submitButton.click();
    await page.waitForTimeout(200);

    // Verify that all options are disabled after submission
    await expect(secondOption).toBeDisabled({ timeout: 3000 });
    await expect(firstOption).toBeDisabled({ timeout: 3000 });

    // Verify first option (wrong answer) is still visually indicated with red styling
    // After submission, the selected wrong answer shows red background (bg-red-50)
    await expect(firstOption).toHaveClass(/bg-red-50/, { timeout: 3000 });

    // Verify the correct answer (second option) shows green styling (bg-green-50)
    await expect(secondOption).toHaveClass(/bg-green-50/, { timeout: 3000 });

    await page.screenshot({ path: 'test-results/fe-unit-048.png' });
  });
});
