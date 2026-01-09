import { test, expect, Page } from '@playwright/test';

// Test configuration
const BASE_URL = 'http://localhost:3030';
const TEST_USER = {
  email: `test_${Date.now()}@example.com`,
  password: 'TestPassword123!',
  firstName: 'Test',
  lastName: 'User'
};

const VIP_USER = {
  email: 'myaji35@gmail.com',
  password: 'YourVipPassword' // VIP 사용자의 실제 비밀번호로 변경 필요
};

test.describe('Clerk Authentication Tests', () => {
  test.describe.configure({ mode: 'serial' }); // 순차 실행

  // Helper function to check if page exists
  async function checkPageExists(page: Page, url: string): Promise<boolean> {
    try {
      const response = await page.goto(url, {
        waitUntil: 'domcontentloaded',
        timeout: 5000
      });
      return response?.status() !== 404;
    } catch (error) {
      return false;
    }
  }

  test.beforeEach(async ({ page }) => {
    // Clear cookies only (localStorage might be restricted)
    await page.context().clearCookies();
  });

  test('AUTH-001: Sign-up page loads correctly', async ({ page }) => {
    await page.goto(`${BASE_URL}/sign-up`);

    // Check page elements
    await expect(page.locator('h1')).toContainText('회원가입');
    await expect(page.locator('text=AI 자격증 마스터와 함께')).toBeVisible();

    // Check Clerk sign-up component is loaded
    await expect(page.locator('[data-clerk-sign-up-form]')).toBeVisible({ timeout: 10000 });

    // Check features section
    await expect(page.locator('text=PDF 자동 분석')).toBeVisible();
    await expect(page.locator('text=지식 그래프')).toBeVisible();
    await expect(page.locator('text=맞춤형 학습')).toBeVisible();
  });

  test('AUTH-002: Sign-in page loads correctly', async ({ page }) => {
    await page.goto(`${BASE_URL}/sign-in`);

    // Check page elements
    await expect(page.locator('h1')).toContainText('로그인');
    await expect(page.locator('text=다시 만나서 반가워요!')).toBeVisible();

    // Check Clerk sign-in component is loaded
    await expect(page.locator('[data-clerk-sign-in-form]')).toBeVisible({ timeout: 10000 });

    // Check stats section
    await expect(page.locator('text=1,000+')).toBeVisible();
    await expect(page.locator('text=50,000+')).toBeVisible();
    await expect(page.locator('text=95%')).toBeVisible();
  });

  test('AUTH-003: Protected routes redirect to sign-in', async ({ page }) => {
    const protectedRoutes = [
      '/dashboard',
      '/study-sets',
      '/certifications',
      '/knowledge-graph',
      '/admin'
    ];

    for (const route of protectedRoutes) {
      await page.goto(`${BASE_URL}${route}`);

      // Should redirect to sign-in
      await expect(page).toHaveURL(new RegExp('/sign-in'));

      // Check redirect_url parameter
      const url = new URL(page.url());
      expect(url.searchParams.get('redirect_url')).toContain(route);
    }
  });

  test('AUTH-004: Public routes are accessible without auth', async ({ page }) => {
    const publicRoutes = [
      '/',
      '/pricing',
      '/sign-up',
      '/sign-in'
    ];

    for (const route of publicRoutes) {
      const response = await page.goto(`${BASE_URL}${route}`);

      // Should not redirect
      expect(page.url()).toContain(route);

      // Should load successfully
      expect(response?.status()).toBeLessThan(400);
    }
  });

  test('AUTH-005: Sign-up flow with email', async ({ page }) => {
    test.skip(true, 'Skipping actual sign-up to avoid creating test accounts in Clerk');

    await page.goto(`${BASE_URL}/sign-up`);

    // Wait for Clerk component to load
    await page.waitForSelector('[data-clerk-sign-up-form]', { timeout: 10000 });

    // Fill in email
    await page.fill('input[name="emailAddress"]', TEST_USER.email);
    await page.click('button[type="submit"]');

    // Fill in password
    await page.fill('input[name="password"]', TEST_USER.password);
    await page.click('button[type="submit"]');

    // Fill in name (if required)
    await page.fill('input[name="firstName"]', TEST_USER.firstName);
    await page.fill('input[name="lastName"]', TEST_USER.lastName);
    await page.click('button[type="submit"]');

    // Should redirect to dashboard after successful sign-up
    await expect(page).toHaveURL(`${BASE_URL}/dashboard`, { timeout: 15000 });
  });

  test('AUTH-006: Sign-in with valid credentials', async ({ page }) => {
    test.skip(true, 'Skipping actual sign-in - requires real Clerk account');

    await page.goto(`${BASE_URL}/sign-in`);

    // Wait for Clerk component to load
    await page.waitForSelector('[data-clerk-sign-in-form]', { timeout: 10000 });

    // Fill in credentials
    await page.fill('input[name="identifier"]', TEST_USER.email);
    await page.click('button[type="submit"]');

    await page.fill('input[name="password"]', TEST_USER.password);
    await page.click('button[type="submit"]');

    // Should redirect to dashboard after successful sign-in
    await expect(page).toHaveURL(`${BASE_URL}/dashboard`, { timeout: 15000 });
  });

  test('AUTH-007: VIP user access test', async ({ page }) => {
    test.skip(true, 'Skipping VIP test - requires real VIP account credentials');

    // Sign in as VIP user
    await page.goto(`${BASE_URL}/sign-in`);
    await page.waitForSelector('[data-clerk-sign-in-form]', { timeout: 10000 });

    await page.fill('input[name="identifier"]', VIP_USER.email);
    await page.click('button[type="submit"]');

    await page.fill('input[name="password"]', VIP_USER.password);
    await page.click('button[type="submit"]');

    // Wait for redirect to dashboard
    await expect(page).toHaveURL(`${BASE_URL}/dashboard`, { timeout: 15000 });

    // Navigate to study-sets creation page
    await page.goto(`${BASE_URL}/dashboard/study-sets/new`);

    // Check for VIP pass indicator
    await expect(page.locator('text=VIP 무료 이용권')).toBeVisible();
    await expect(page.locator('text=👑')).toBeVisible();

    // Check certification selection dropdown (VIP only feature)
    await expect(page.locator('select[id*="certification"]')).toBeVisible();
  });

  test('AUTH-008: Sign-out functionality', async ({ page }) => {
    test.skip(true, 'Skipping sign-out test - requires authenticated session');

    // First sign in
    await page.goto(`${BASE_URL}/sign-in`);
    // ... sign in steps ...

    // Find and click sign-out button
    await page.click('[data-clerk-sign-out-button]');

    // Should redirect to home or sign-in page
    await expect(page).toHaveURL(new RegExp('/(sign-in|$)'));

    // Try accessing protected route - should redirect to sign-in
    await page.goto(`${BASE_URL}/dashboard`);
    await expect(page).toHaveURL(new RegExp('/sign-in'));
  });

  test('AUTH-009: Middleware protects API routes', async ({ request }) => {
    // Test API without auth token
    const response = await request.get(`http://localhost:8000/api/v1/study-sets`);

    // Should return 401 or 403
    expect([401, 403]).toContain(response.status());
  });

  test('AUTH-010: Backend health check is public', async ({ request }) => {
    // Health endpoint should be accessible without auth
    const response = await request.get(`http://localhost:8000/health`);

    expect(response.status()).toBe(200);

    const data = await response.json();
    expect(data).toHaveProperty('status', 'healthy');
    expect(data).toHaveProperty('version');
  });
});

test.describe('Clerk UI Component Tests', () => {
  test('UI-001: Sign-up form validation', async ({ page }) => {
    await page.goto(`${BASE_URL}/sign-up`);
    await page.waitForSelector('[data-clerk-sign-up-form]', { timeout: 10000 });

    // Try to submit empty form
    const submitButton = page.locator('button[type="submit"]').first();
    await submitButton.click();

    // Should show validation errors
    await expect(page.locator('text=/email.*required/i')).toBeVisible();
  });

  test('UI-002: Password strength indicator', async ({ page }) => {
    await page.goto(`${BASE_URL}/sign-up`);
    await page.waitForSelector('[data-clerk-sign-up-form]', { timeout: 10000 });

    // Enter email first
    await page.fill('input[name="emailAddress"]', 'test@example.com');
    await page.click('button[type="submit"]');

    // Type weak password
    const passwordInput = page.locator('input[name="password"]');
    await passwordInput.fill('weak');

    // Should show password strength feedback
    await expect(page.locator('text=/password.*weak|strong|medium/i')).toBeVisible();
  });

  test('UI-003: Social login buttons', async ({ page }) => {
    await page.goto(`${BASE_URL}/sign-in`);
    await page.waitForSelector('[data-clerk-sign-in-form]', { timeout: 10000 });

    // Check for social login buttons
    const socialButtons = page.locator('[data-clerk-social-button]');

    // Should have at least one social login option
    await expect(socialButtons).toHaveCount(1, { timeout: 5000 });
  });

  test('UI-004: Language localization (Korean)', async ({ page }) => {
    await page.goto(`${BASE_URL}/sign-up`);

    // Check Korean text is displayed
    await expect(page.locator('text=회원가입')).toBeVisible();
    await expect(page.locator('text=/이미 계정이 있으신가요?/')).toBeVisible();

    await page.goto(`${BASE_URL}/sign-in`);

    // Check Korean text on sign-in page
    await expect(page.locator('text=로그인')).toBeVisible();
    await expect(page.locator('text=/아직 계정이 없으신가요?/')).toBeVisible();
  });
});

// Performance tests
test.describe('Performance Tests', () => {
  test('PERF-001: Sign-in page loads within 3 seconds', async ({ page }) => {
    const startTime = Date.now();
    await page.goto(`${BASE_URL}/sign-in`);
    await page.waitForSelector('[data-clerk-sign-in-form]');
    const loadTime = Date.now() - startTime;

    expect(loadTime).toBeLessThan(3000);
  });

  test('PERF-002: Sign-up page loads within 3 seconds', async ({ page }) => {
    const startTime = Date.now();
    await page.goto(`${BASE_URL}/sign-up`);
    await page.waitForSelector('[data-clerk-sign-up-form]');
    const loadTime = Date.now() - startTime;

    expect(loadTime).toBeLessThan(3000);
  });
});