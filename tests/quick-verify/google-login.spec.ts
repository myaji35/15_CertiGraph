import { test, expect } from '@playwright/test';

test.describe('Google Login Button', () => {
  test('Google login button should be functional on signin page', async ({ page }) => {
    // Navigate to signin page
    await page.goto('http://localhost:3000/signin');

    // Check if Google login button is present
    const googleButton = page.locator('button:has-text("Google로 계속하기")');
    await expect(googleButton).toBeVisible();

    // Click the Google login button
    await googleButton.click();

    // The button should initiate OAuth flow
    // Note: In test environment, it will redirect to Google OAuth or show an error
    // We're checking if the button is clickable and triggers an action

    // Wait for navigation or error (either is expected without real OAuth credentials)
    await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {
      // It's OK if this times out - we're just checking the button works
    });

    // Check if we navigated away from signin page or got an OAuth error
    const currentUrl = page.url();

    // The URL should have changed (either to Google OAuth or an error page)
    expect(currentUrl).not.toBe('http://localhost:3000/signin');

    console.log('✅ Google login button is functional - redirected to:', currentUrl);
  });

  test('Google login button should be functional on signup page', async ({ page }) => {
    // Navigate to signup page
    await page.goto('http://localhost:3000/signup');

    // Check if Google login button is present
    const googleButton = page.locator('button:has-text("Google로 계속하기")');
    await expect(googleButton).toBeVisible();

    // Click the Google login button
    await googleButton.click();

    // Wait for navigation or error
    await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {
      // It's OK if this times out - we're just checking the button works
    });

    // Check if we navigated away from signup page
    const currentUrl = page.url();

    // The URL should have changed
    expect(currentUrl).not.toBe('http://localhost:3000/signup');

    console.log('✅ Google login button is functional on signup page - redirected to:', currentUrl);
  });

  test('Google OAuth path should be configured in routes', async ({ page }) => {
    // Try to access the OAuth authorize path directly
    const response = await page.goto('http://localhost:3000/users/auth/google_oauth2', {
      waitUntil: 'networkidle'
    });

    // Check if the route exists (should redirect to Google or show CSRF error)
    // Status 302 (redirect) or 422 (CSRF) are both acceptable
    const status = response?.status() || 0;

    expect([302, 303, 422]).toContain(status);

    console.log(`✅ OAuth route is configured - status: ${status}`);
  });
});