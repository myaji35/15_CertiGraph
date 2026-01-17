import { Page, expect } from '@playwright/test';

/**
 * Register a new user with email and password
 */
export async function registerUser(
  page: Page,
  email: string,
  password: string
): Promise<void> {
  await page.goto('/signup');
  await page.fill('input[name="user[email]"], input[name="email"]', email);
  await page.fill('input[name="user[password]"], input[name="password"]', password);
  await page.fill(
    'input[name="user[password_confirmation]"], input[name="password_confirmation"]',
    password
  );
  await page.click('button[type="submit"], input[type="submit"]');
  
  // Wait for redirect to dashboard or welcome
  await page.waitForURL(/\/(dashboard|welcome|study_sets)/, { timeout: 15000 });
}

/**
 * Log in as an existing user
 */
export async function loginAsUser(
  page: Page,
  email: string,
  password: string
): Promise<void> {
  await page.goto('/signin');
  await page.fill('input[name="user[email]"], input[name="email"]', email);
  await page.fill('input[name="user[password]"], input[name="password"]', password);
  await page.click('button[type="submit"], input[type="submit"]');
  
  // Wait for successful login redirect
  await page.waitForURL(/\/(dashboard|study_sets)/, { timeout: 15000 });
}

/**
 * Log out the current user
 */
export async function logoutUser(page: Page): Promise<void> {
  // Try multiple logout patterns
  const logoutSelectors = [
    'a[href="/signout"]',
    'a[href="/logout"]',
    'button:has-text("Logout")',
    'button:has-text("로그아웃")',
    'text=Logout',
    'text=로그아웃',
  ];
  
  for (const selector of logoutSelectors) {
    try {
      await page.click(selector, { timeout: 2000 });
      await page.waitForURL(/\/(signin|home|$)/, { timeout: 5000 });
      return;
    } catch (e) {
      // Try next selector
    }
  }
  
  // If no logout button found, manually clear session
  await page.context().clearCookies();
  await page.goto('/signin');
}

/**
 * Check if user is logged in
 */
export async function isLoggedIn(page: Page): Promise<boolean> {
  try {
    await page.goto('/dashboard', { timeout: 10000 });
    const url = page.url();
    return !url.includes('/signin') && !url.includes('/signup');
  } catch (e) {
    return false;
  }
}
