import { Page } from '@playwright/test';

/**
 * Rails Authentication Helper for Playwright Tests
 *
 * This helper provides authentication functions that work with
 * Rails/Devise authentication system running on localhost:3000
 */

const BASE_URL = 'http://localhost:3000';

/**
 * Register a new user with email and password
 * Uses Rails Devise registration
 */
export async function registerUser(
  page: Page,
  email: string,
  password: string
): Promise<void> {
  await page.goto(`${BASE_URL}/signup`);

  // Fill registration form - Rails/Devise format
  await page.fill('input[name="user[email]"], input[id="user_email"]', email);
  await page.fill('input[name="user[password]"], input[id="user_password"]', password);
  await page.fill('input[name="user[password_confirmation]"], input[id="user_password_confirmation"]', password);

  // Submit form
  await page.click('input[type="submit"], button[type="submit"]');

  // Wait for redirect to dashboard or home
  await page.waitForURL(/dashboard|home|root/i, { timeout: 10000 });
}

/**
 * Login as existing user
 * Uses Rails Devise authentication
 */
export async function loginAsUser(
  page: Page,
  email: string,
  password: string
): Promise<void> {
  await page.goto(`${BASE_URL}/signin`);

  // Fill login form - Rails/Devise format
  await page.fill('input[name="user[email]"], input[id="user_email"]', email);
  await page.fill('input[name="user[password]"], input[id="user_password"]', password);

  // Submit form
  await page.click('input[type="submit"], button[type="submit"]');

  // Wait for redirect to dashboard
  await page.waitForURL(/dashboard|home/i, { timeout: 10000 });
}

/**
 * Logout current user
 */
export async function logout(page: Page): Promise<void> {
  // Look for logout link/button
  const logoutButton = page.locator('a:has-text("로그아웃"), a:has-text("Logout"), button:has-text("로그아웃")');

  if (await logoutButton.isVisible()) {
    await logoutButton.click();
  } else {
    // Direct navigation to logout endpoint
    await page.goto(`${BASE_URL}/signout`);
  }

  // Wait for redirect to home/signin
  await page.waitForURL(/signin|home|^\/$/, { timeout: 5000 });
}

/**
 * Check if user is logged in
 */
export async function isLoggedIn(page: Page): Promise<boolean> {
  await page.goto(`${BASE_URL}/dashboard`);

  // If redirected to signin, not logged in
  const url = page.url();
  return !url.includes('signin');
}

/**
 * Quick login with test user credentials
 * Uses default test credentials: test@example.com / Test1234!
 */
export async function quickLogin(page: Page): Promise<void> {
  await loginAsUser(page, 'test@example.com', 'Test1234!');
}

/**
 * Create and login as unique test user
 * Generates unique email to avoid conflicts
 */
export async function createAndLoginUniqueUser(page: Page): Promise<string> {
  const timestamp = Date.now();
  const email = `test.${timestamp}@certigraph.test`;
  const password = 'Test1234!';

  await registerUser(page, email, password);

  return email;
}
