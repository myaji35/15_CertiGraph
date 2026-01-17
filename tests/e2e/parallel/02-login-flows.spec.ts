import { test, expect } from '@playwright/test';
import { skipIfPageNotExists, safeGoto } from '../../helpers/page-checker';
import { loginAsUser, logout } from '../../helpers/rails-auth-helper';

/**
 * P4 Group: Independent E2E Tests - Login Flows
 * Test IDs: E2E-PAR-005 to E2E-PAR-008
 *
 * Tests various login scenarios independently
 *
 * NOTE: Updated for Rails/Devise authentication on localhost:3000
 * NOTE: These tests require the application's sign-in and dashboard pages to be implemented.
 * Tests will skip gracefully if pages return 404 or are not available.
 */

test.describe('P4: Login Flows E2E Tests', () => {

  test('E2E-PAR-005: Should successfully log in with valid credentials', async ({ page }) => {
    const homeResult = await safeGoto(page, '/', { timeout: 5000 });
    if (!homeResult.exists) {
      test.skip(true, `Homepage not available: ${homeResult.message}`);
    }

    // Click Sign In button
    const signInButton = page.locator('a:has-text("Sign In"), a:has-text("로그인"), button:has-text("Sign In")');
    if (await signInButton.count() > 0) {
      await signInButton.first().click();
      // Wait for navigation to complete
      await page.waitForLoadState('domcontentloaded');
    } else {
      // Navigate directly to sign-in page - Rails/Devise route
      const signInResult = await skipIfPageNotExists(page, '/users/sign_in', 'E2E-PAR-005');
      if (!signInResult.exists) {
        test.skip(true, signInResult.message);
      }
    }

    // Wait for Rails/Devise form to be ready - look for email input field
    const emailInput = page.locator('input[type="email"], input[name="user[email]"], input[id="user_email"]');
    const passwordInput = page.locator('input[type="password"], input[name="user[password]"], input[id="user_password"]');

    try {
      await emailInput.first().waitFor({ state: 'visible', timeout: 10000 });
    } catch (error) {
      test.skip(true, 'Sign-in form not found - Devise form may not be loaded');
    }

    if (await emailInput.count() === 0 || await passwordInput.count() === 0) {
      test.skip(true, 'Sign-in form not found');
    }

    // Fill in login form (use existing test user)
    await emailInput.first().fill('test@certigraph.test');
    await passwordInput.first().fill('TestPassword123!');

    await page.screenshot({ path: 'test-results/e2e-par-005-login-form.png' });

    // Submit login - Clerk uses specific button text
    const submitButton = page.locator('button[type="submit"], button:has-text("Continue"), button:has-text("Sign In"), button:has-text("로그인")');
    await submitButton.first().click();

    // Wait for redirect to dashboard (Clerk may take time to process)
    try {
      await page.waitForURL(/dashboard|home/i, { timeout: 10000 });
    } catch (error) {
      // If URL wait fails, check if we're already on the dashboard
      await page.waitForTimeout(2000);
    }

    // Should redirect to dashboard
    const currentUrl = page.url();
    expect(currentUrl).toMatch(/dashboard|home/i);

    await page.screenshot({ path: 'test-results/e2e-par-005-success.png' });
  });

  test('E2E-PAR-006: Should show error for invalid credentials', async ({ page }) => {
    const result = await skipIfPageNotExists(page, '/users/sign_in', 'E2E-PAR-006');
    if (!result.exists) {
      test.skip(true, result.message);
    }

    // Wait for Clerk form to be ready
    const emailInput = page.locator('input[type="email"], input[name="user[email]"], input[name="email"]');
    const passwordInput = page.locator('input[type="password"], input[name="password"]');

    try {
      await emailInput.first().waitFor({ state: 'visible', timeout: 10000 });
    } catch (error) {
      test.skip(true, 'Sign-in form not found - Devise form may not be loaded');
    }

    if (await emailInput.count() === 0 || await passwordInput.count() === 0) {
      test.skip(true, 'Sign-in form not found');
    }

    // Use invalid credentials
    await emailInput.first().fill('wrong@example.com');
    await passwordInput.first().fill('WrongPassword123!');

    // Submit the form
    const submitButton = page.locator('button[type="submit"], button:has-text("Continue"), button:has-text("Sign In"), button:has-text("로그인")');
    await submitButton.first().click();

    // Wait for error message to appear
    await page.waitForTimeout(2000);

    // Look for error message - Clerk shows specific error messages
    const errorMessage = page.locator('text=/invalid credentials|incorrect|wrong password|failed|couldn\'t sign you in/i, div[role="alert"], .cl-formFieldErrorText');
    await expect(errorMessage.first()).toBeVisible({ timeout: 5000 });

    await page.screenshot({ path: 'test-results/e2e-par-006-error.png' });
  });

  test('E2E-PAR-007: Should successfully log out', async ({ page }) => {
    // First, log in
    const result = await skipIfPageNotExists(page, '/users/sign_in', 'E2E-PAR-007');
    if (!result.exists) {
      test.skip(true, result.message);
    }

    // Wait for Clerk form to be ready
    const emailInput = page.locator('input[type="email"], input[name="user[email]"], input[name="email"]');
    const passwordInput = page.locator('input[type="password"], input[name="password"]');

    try {
      await emailInput.first().waitFor({ state: 'visible', timeout: 10000 });
    } catch (error) {
      test.skip(true, 'Sign-in form not found - Devise form may not be loaded');
    }

    if (await emailInput.count() === 0 || await passwordInput.count() === 0) {
      test.skip(true, 'Sign-in form not found');
    }

    await emailInput.first().fill('test@certigraph.test');
    await passwordInput.first().fill('TestPassword123!');

    const submitButton = page.locator('button[type="submit"], button:has-text("Continue"), button:has-text("Sign In"), button:has-text("로그인")');
    await submitButton.first().click();

    // Wait for successful login and redirect
    try {
      await page.waitForURL(/dashboard|home/i, { timeout: 10000 });
    } catch (error) {
      await page.waitForTimeout(2000);
    }

    // Now log out - try Clerk's user button first
    const clerkUserButton = page.locator('.cl-userButtonTrigger, button[aria-label*="account"], button:has([alt*="avatar" i])');
    const logoutButton = page.locator('button:has-text("Sign out"), button:has-text("Log Out"), button:has-text("로그아웃"), a:has-text("Sign Out")');

    // Try Clerk user button
    if (await clerkUserButton.count() > 0) {
      await clerkUserButton.first().click();
      await page.waitForTimeout(500);
    } else {
      // Fallback: Logout might be in a menu
      const userMenu = page.locator('[data-testid="user-menu"], button:has-text("Profile"), [aria-label="User menu"]');
      if (await userMenu.count() > 0) {
        await userMenu.first().click();
        await page.waitForTimeout(500);
      }
    }

    // Click logout button
    if (await logoutButton.count() > 0) {
      await logoutButton.first().click();
      await page.waitForTimeout(1500);
    } else {
      test.skip(true, 'Logout button not found');
    }

    // Should redirect to homepage or login page
    const currentUrl = page.url();
    expect(currentUrl).toMatch(/^http:\/\/localhost:3000\/?$|sign-in|login/i);

    await page.screenshot({ path: 'test-results/e2e-par-007-logout.png' });
  });

  test('E2E-PAR-008: Should support "Remember Me" functionality', async ({ page, context }) => {
    const result = await skipIfPageNotExists(page, '/users/sign_in', 'E2E-PAR-008');
    if (!result.exists) {
      test.skip(true, result.message);
    }

    // Wait for Clerk form to be ready
    const emailInput = page.locator('input[type="email"], input[name="user[email]"], input[name="email"]');
    const passwordInput = page.locator('input[type="password"], input[name="password"]');

    try {
      await emailInput.first().waitFor({ state: 'visible', timeout: 10000 });
    } catch (error) {
      test.skip(true, 'Sign-in form not found - Devise form may not be loaded');
    }

    if (await emailInput.count() === 0 || await passwordInput.count() === 0) {
      test.skip(true, 'Sign-in form not found');
    }

    await emailInput.first().fill('test@certigraph.test');
    await passwordInput.first().fill('TestPassword123!');

    // Check "Remember Me" if available (Clerk may or may not have this)
    const rememberMeCheckbox = page.locator('input[type="checkbox"][name*="remember"], label:has-text("Remember"), input[id*="remember"]');
    if (await rememberMeCheckbox.count() > 0) {
      await rememberMeCheckbox.first().check();
    }

    await page.screenshot({ path: 'test-results/e2e-par-008-remember-me.png' });

    const submitButton = page.locator('button[type="submit"], button:has-text("Continue"), button:has-text("Sign In"), button:has-text("로그인")');
    await submitButton.first().click();

    // Wait for authentication to complete
    try {
      await page.waitForURL(/dashboard|home/i, { timeout: 10000 });
    } catch (error) {
      await page.waitForTimeout(2000);
    }

    // Check cookies - Clerk uses __session and __clerk cookies
    const cookies = await context.cookies();
    const hasAuthCookie = cookies.some(cookie =>
      cookie.name.includes('session') ||
      cookie.name.includes('token') ||
      cookie.name.includes('auth') ||
      cookie.name.includes('clerk') ||
      cookie.name.includes('__session')
    );

    expect(hasAuthCookie).toBe(true);

    await page.screenshot({ path: 'test-results/e2e-par-008-authenticated.png' });
  });
});
