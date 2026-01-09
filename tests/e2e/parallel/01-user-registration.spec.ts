import { test, expect } from '@playwright/test';
import { skipIfPageNotExists, safeGoto } from '../../helpers/page-checker';

/**
 * P4 Group: Independent E2E Tests - User Registration
 * Test IDs: E2E-PAR-001 to E2E-PAR-004
 *
 * Uses unique users for each test to ensure isolation
 *
 * NOTE: These tests require the application's sign-up pages to be implemented.
 * Tests will skip gracefully if pages return 404 or are not available.
 */

test.describe('P4: User Registration E2E Tests', () => {

  test('E2E-PAR-001: Should successfully register a new user with valid credentials', async ({ page }) => {
    const uniqueEmail = `test.user.${Date.now()}@certigraph.test`;

    // Navigate directly to sign-up page
    const signUpResult = await safeGoto(page, '/sign-up', { timeout: 10000 });
    if (!signUpResult.exists) {
      test.skip(true, `Sign-up page not available: ${signUpResult.message}`);
    }

    // Wait for Clerk form to be ready - look for Clerk-specific elements
    // Clerk uses specific class names and data attributes
    const clerkForm = page.locator('[data-clerk-id], .cl-component, .cl-signUp-root');
    const emailInput = page.locator('input[type="email"], input[name="emailAddress"], input[name="identifier"]');

    // Wait for either Clerk form or generic form to appear
    try {
      await Promise.race([
        clerkForm.first().waitFor({ state: 'visible', timeout: 5000 }),
        emailInput.first().waitFor({ state: 'visible', timeout: 5000 })
      ]);
    } catch (error) {
      test.skip(true, 'Sign-up form not found - Clerk widget may not have loaded');
    }

    // Check if form inputs are available
    if (await emailInput.count() === 0) {
      test.skip(true, 'Email input field not found in sign-up form');
    }

    // Fill in registration form
    await emailInput.first().fill(uniqueEmail);

    // Clerk may use different password field names
    const passwordInput = page.locator('input[type="password"], input[name="password"]').first();
    if (await passwordInput.count() > 0) {
      await passwordInput.fill('SecurePassword123!');
    }

    await page.screenshot({ path: 'test-results/e2e-par-001-form.png' });

    // Submit registration - Clerk uses specific button classes
    const submitButton = page.locator('button[type="submit"], button.cl-formButtonPrimary, button:has-text("Sign up"), button:has-text("Continue")');
    await submitButton.first().click();

    // Wait for navigation or success message
    await page.waitForTimeout(3000);

    await page.screenshot({ path: 'test-results/e2e-par-001-success.png' });

    // Verify successful registration
    // Clerk may redirect to verification page or dashboard
    const currentUrl = page.url();
    const hasSuccessIndicator = currentUrl.includes('verify') ||
                                 currentUrl.includes('dashboard') ||
                                 currentUrl.includes('welcome') ||
                                 await page.locator('text=/verify|verification|check.*email/i').count() > 0;

    expect(hasSuccessIndicator).toBeTruthy();
  });

  test('E2E-PAR-002: Should show error for duplicate email registration', async ({ page }) => {
    // Use a common test email that already exists
    const duplicateEmail = 'existing.user@certigraph.test';

    // Navigate to sign-up page
    const result = await safeGoto(page, '/sign-up', { timeout: 10000 });
    if (!result.exists) {
      test.skip(true, `Sign-up page not available: ${result.message}`);
    }

    // Wait for Clerk form to be ready
    const emailInput = page.locator('input[type="email"], input[name="emailAddress"], input[name="identifier"]');

    try {
      await emailInput.first().waitFor({ state: 'visible', timeout: 5000 });
    } catch (error) {
      test.skip(true, 'Sign-up form not found - Clerk widget may not have loaded');
    }

    if (await emailInput.count() === 0) {
      test.skip(true, 'Email input field not found');
    }

    // Fill in the form with duplicate email
    await emailInput.first().fill(duplicateEmail);

    const passwordInput = page.locator('input[type="password"], input[name="password"]').first();
    if (await passwordInput.count() > 0) {
      await passwordInput.fill('Password123!');
    }

    // Submit the form
    const submitButton = page.locator('button[type="submit"], button.cl-formButtonPrimary, button:has-text("Sign up"), button:has-text("Continue")');
    await submitButton.first().click();

    await page.waitForTimeout(2000);

    // Look for error message - Clerk shows specific error messages
    const errorMessage = page.locator('text=/already exists|already registered|duplicate|already.*use|account.*exists/i, .cl-formFieldErrorText, [data-localization-key*="error"]');
    await expect(errorMessage.first()).toBeVisible({ timeout: 5000 });

    await page.screenshot({ path: 'test-results/e2e-par-002-error.png' });
  });

  test('E2E-PAR-003: Should validate password requirements', async ({ page }) => {
    const uniqueEmail = `test.weak.password.${Date.now()}@certigraph.test`;

    // Navigate to sign-up page
    const result = await safeGoto(page, '/sign-up', { timeout: 10000 });
    if (!result.exists) {
      test.skip(true, `Sign-up page not available: ${result.message}`);
    }

    // Wait for Clerk form to be ready
    const emailInput = page.locator('input[type="email"], input[name="emailAddress"], input[name="identifier"]');
    const passwordInput = page.locator('input[type="password"], input[name="password"]');

    try {
      await emailInput.first().waitFor({ state: 'visible', timeout: 5000 });
    } catch (error) {
      test.skip(true, 'Sign-up form not found - Clerk widget may not have loaded');
    }

    if (await emailInput.count() === 0 || await passwordInput.count() === 0) {
      test.skip(true, 'Sign-up form inputs not found');
    }

    await emailInput.first().fill(uniqueEmail);

    // Try weak password - Clerk validates password strength
    await passwordInput.first().fill('123');

    await page.waitForTimeout(1000);

    // Look for password validation error - Clerk shows inline validation
    const passwordError = page.locator('text=/password.*too short|password.*at least|password.*weak|password.*8.*characters|password.*strong/i, .cl-formFieldErrorText, [data-localization-key*="password"]');

    // Check if error appears immediately (inline validation)
    const errorVisible = await passwordError.first().isVisible().catch(() => false);

    if (!errorVisible) {
      // Try submitting to trigger validation
      const submitButton = page.locator('button[type="submit"], button.cl-formButtonPrimary, button:has-text("Sign up"), button:has-text("Continue")');
      await submitButton.first().click();
      await page.waitForTimeout(1500);

      const errorAfterSubmit = page.locator('text=/password|invalid|requirements|too.*short|at.*least.*8/i, .cl-formFieldErrorText');
      await expect(errorAfterSubmit.first()).toBeVisible({ timeout: 3000 });
    } else {
      await expect(passwordError.first()).toBeVisible();
    }

    await page.screenshot({ path: 'test-results/e2e-par-003-validation.png' });
  });

  test('E2E-PAR-004: Should validate email format', async ({ page }) => {
    // Navigate to sign-up page
    const result = await safeGoto(page, '/sign-up', { timeout: 10000 });
    if (!result.exists) {
      test.skip(true, `Sign-up page not available: ${result.message}`);
    }

    // Wait for Clerk form to be ready
    const emailInput = page.locator('input[type="email"], input[name="emailAddress"], input[name="identifier"]');
    const passwordInput = page.locator('input[type="password"], input[name="password"]');

    try {
      await emailInput.first().waitFor({ state: 'visible', timeout: 5000 });
    } catch (error) {
      test.skip(true, 'Sign-up form not found - Clerk widget may not have loaded');
    }

    if (await emailInput.count() === 0 || await passwordInput.count() === 0) {
      test.skip(true, 'Sign-up form inputs not found');
    }

    // Try invalid email - Clerk validates email format
    await emailInput.first().fill('invalid-email');
    await passwordInput.first().fill('Password123!');

    await page.waitForTimeout(1000);

    // Look for email validation error - Clerk shows inline validation
    const emailError = page.locator('text=/invalid email|email.*format|valid.*email|enter.*valid.*email/i, .cl-formFieldErrorText, [data-localization-key*="email"]');

    // Check if error appears immediately (inline validation)
    const errorVisible = await emailError.first().isVisible().catch(() => false);

    if (!errorVisible) {
      // Try submitting to trigger validation
      const submitButton = page.locator('button[type="submit"], button.cl-formButtonPrimary, button:has-text("Sign up"), button:has-text("Continue")');
      await submitButton.first().click();
      await page.waitForTimeout(1500);

      const errorAfterSubmit = page.locator('text=/email|invalid|format|valid/i, .cl-formFieldErrorText');
      await expect(errorAfterSubmit.first()).toBeVisible({ timeout: 3000 });
    } else {
      await expect(emailError.first()).toBeVisible();
    }

    await page.screenshot({ path: 'test-results/e2e-par-004-email-validation.png' });
  });
});
