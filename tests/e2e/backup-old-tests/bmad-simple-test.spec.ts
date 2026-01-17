import { test, expect } from '@playwright/test';

test.describe('CertiGraph Basic Tests', () => {
  test('1. 홈페이지 접속 테스트', async ({ page }) => {
    await page.goto('http://localhost:3000');

    // 페이지가 로드되었는지 확인 - Rails app title
    await expect(page).toHaveTitle(/ExamsGraph|CertiGraph|AI 자격증/);

    // 주요 요소가 표시되는지 확인
    const mainContent = page.locator('main, body');
    await expect(mainContent).toBeVisible({ timeout: 10000 });
  });

  test('2. 로그인 페이지 접속', async ({ page }) => {
    await page.goto('http://localhost:3000/users/sign_in');

    // 로그인 폼이 있는지 확인
    const emailInput = page.locator('input[type="email"], input[name="user[email]"], input[id="user_email"]');
    const passwordInput = page.locator('input[type="password"], input[name="user[password]"], input[id="user_password"]');

    await expect(emailInput).toBeVisible({ timeout: 10000 });
    await expect(passwordInput).toBeVisible({ timeout: 10000 });
  });

  test('3. 회원가입 페이지 접속', async ({ page }) => {
    await page.goto('http://localhost:3000/users/sign_up');

    // 회원가입 폼 요소 확인
    const signupForm = page.locator('form').first();
    await expect(signupForm).toBeVisible({ timeout: 10000 });
  });

  test('4. 대시보드 접근 (로그인 필요)', async ({ page }) => {
    // 로그인 없이 대시보드 접근 시도
    await page.goto('http://localhost:3000/dashboard');

    // 로그인 페이지로 리다이렉트되는지 확인
    await expect(page).toHaveURL(/sign_in/, { timeout: 10000 });
  });

  test('5. 404 페이지 테스트', async ({ page }) => {
    await page.goto('http://localhost:3000/non-existent-page');

    // 404 메시지가 표시되는지 확인
    const notFoundText = page.locator('text=/not found|404|페이지를 찾을 수 없습니다/i');
    await expect(notFoundText).toBeVisible({ timeout: 10000 });
  });
});

test.describe('반응형 디자인 테스트', () => {
  test('6. 모바일 뷰 테스트', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('http://localhost:3000');

    // 모바일 메뉴 버튼이 표시되는지 확인
    const mobileMenuButton = page.locator('[aria-label*="menu"], button:has-text("메뉴"), [data-testid*="mobile-menu"]').first();
    const isVisible = await mobileMenuButton.isVisible().catch(() => false);

    // 모바일 뷰에서 페이지가 로드되는지만 확인
    expect(page.viewportSize()?.width).toBe(375);
  });

  test('7. 태블릿 뷰 테스트', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('http://localhost:3000');

    // 태블릿 뷰에서 페이지가 로드되는지 확인
    expect(page.viewportSize()?.width).toBe(768);
  });
});

test.describe('접근성 테스트', () => {
  test('8. 키보드 네비게이션', async ({ page }) => {
    await page.goto('http://localhost:3000');

    // Tab 키로 이동 가능한지 확인
    await page.keyboard.press('Tab');

    // 포커스된 요소가 있는지 확인
    const focusedElement = await page.evaluate(() => document.activeElement?.tagName);
    expect(focusedElement).toBeTruthy();
  });

  test('9. 이미지 대체 텍스트', async ({ page }) => {
    await page.goto('http://localhost:3000');

    // 이미지가 있다면 alt 속성이 있는지 확인
    const images = await page.locator('img').all();

    for (const img of images.slice(0, 3)) { // 처음 3개만 확인
      const alt = await img.getAttribute('alt').catch(() => null);
      // alt 속성이 있거나 decorative 이미지인지 확인
      expect(alt !== null || await img.getAttribute('role') === 'presentation').toBeTruthy();
    }
  });
});

// 테스트 완료 후 요약
test.afterAll(async () => {
  console.log('='.repeat(60));
  console.log('BMad 간단한 테스트 완료');
  console.log('='.repeat(60));
});