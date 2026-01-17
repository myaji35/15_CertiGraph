import { test, expect } from '@playwright/test';

test.describe('Epic 1.1: Email Registration @P0', () => {

  test('E01-TC001: Register with valid email and strong password', async ({ page }) => {
    const uniqueEmail = `test.${Date.now()}@certigraph.test`;

    await page.goto('/signup');

    await page.fill('input[name="user[email]"], input[name="email"]', uniqueEmail);
    await page.fill('input[name="user[password]"], input[name="password"]', 'Test123!@#');
    await page.fill(
      'input[name="user[password_confirmation]"], input[name="password_confirmation"]',
      'Test123!@#'
    );

    await page.click('button[type="submit"], input[type="submit"]');

    await page.waitForURL(/\/(dashboard|welcome|study_sets)/, { timeout: 15000 });

    const bodyText = await page.textContent('body');
    const isLoggedIn = bodyText?.includes('환영') ||
                       bodyText?.includes('Welcome') ||
                       bodyText?.includes('Dashboard') ||
                       bodyText?.includes('대시보드');

    expect(isLoggedIn).toBeTruthy();
  });

  test('E01-TC003: Empty email shows validation error', async ({ page }) => {
    await page.goto('/signup');

    await page.fill('input[name="user[password]"], input[name="password"]', 'Test123!');
    await page.fill(
      'input[name="user[password_confirmation]"], input[name="password_confirmation"]',
      'Test123!'
    );

    await page.click('button[type="submit"], input[type="submit"]');

    await page.waitForTimeout(1000);

    const bodyText = await page.textContent('body');
    const hasError = bodyText?.includes('blank') ||
                     bodyText?.includes('required') ||
                     bodyText?.includes('필수');

    expect(hasError).toBeTruthy();
  });
});

test.describe('Epic 1.2: User Login @P0', () => {

  test('E01-TC020: Login with valid credentials', async ({ page }) => {
    await page.goto('/signin');

    await page.fill('input[name="user[email]"], input[name="email"]', 'test@example.com');
    await page.fill('input[name="user[password]"], input[name="password"]', 'Password123!');

    await page.click('button[type="submit"], input[type="submit"]');

    await page.waitForURL(/\/(dashboard|study_sets)/, { timeout: 15000 });

    const url = page.url();
    expect(url).not.toContain('/signin');
  });

  test('E01-TC021: Login with wrong password shows error', async ({ page }) => {
    await page.goto('/signin');

    await page.fill('input[name="user[email]"], input[name="email"]', 'test@example.com');
    await page.fill('input[name="user[password]"], input[name="password"]', 'WrongPassword123!');

    await page.click('button[type="submit"], input[type="submit"]');

    await page.waitForTimeout(2000);

    const bodyText = await page.textContent('body');
    const hasError = bodyText?.includes('Invalid') ||
                     bodyText?.includes('invalid') ||
                     bodyText?.includes('incorrect') ||
                     bodyText?.includes('틀렸') ||
                     bodyText?.includes('잘못');

    expect(hasError || page.url().includes('/signin')).toBeTruthy();
  });
});
