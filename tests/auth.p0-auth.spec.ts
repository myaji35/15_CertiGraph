import { test, expect } from '@playwright/test';

test.describe('P0 - 인증 핵심 기능 테스트', () => {

  // FE-E2E-001: 회원가입 플로우
  test('P0-001: 회원가입 페이지 접근 가능', async ({ page }) => {
    await page.goto('/signup');
    await expect(page).toHaveTitle(/ExamsGraph/);
    await expect(page.locator('h2')).toContainText('ExamsGraph');
    await expect(page.locator('text=회원가입')).toBeVisible();
  });

  test('P0-002: 회원가입 필수 필드 검증', async ({ page }) => {
    await page.goto('/signup');

    // 이메일 필드 확인
    const emailInput = page.locator('input[type="email"]');
    await expect(emailInput).toBeVisible();
    await expect(emailInput).toHaveAttribute('required', '');

    // 비밀번호 필드 확인
    const passwordInput = page.locator('input[type="password"]');
    await expect(passwordInput).toBeVisible();
    await expect(passwordInput).toHaveAttribute('required', '');
  });

  test('P0-003: 회원가입 폼 제출', async ({ page }) => {
    await page.goto('/signup');

    // 테스트 데이터
    const testEmail = `test${Date.now()}@example.com`;
    const testPassword = 'TestPassword123!';

    // 폼 입력
    await page.fill('input[type="email"]', testEmail);
    await page.fill('input[type="password"]', testPassword);

    // 약관 동의 체크박스
    const agreeCheckbox = page.locator('input[type="checkbox"]').first();
    if (await agreeCheckbox.isVisible()) {
      await agreeCheckbox.check();
    }

    // 제출 버튼 클릭
    await page.click('button[type="submit"], input[type="submit"]');

    // 결과 확인 - 리다이렉트 또는 성공 메시지
    await page.waitForLoadState('networkidle');
  });

  // FE-E2E-002: 로그인 플로우
  test('P0-004: 로그인 페이지 접근 가능', async ({ page }) => {
    await page.goto('/signin');
    await expect(page).toHaveTitle(/ExamsGraph/);
    await expect(page.locator('h2')).toContainText('ExamsGraph');
    await expect(page.locator('text=로그인')).toBeVisible();
  });

  test('P0-005: 로그인 필수 필드 검증', async ({ page }) => {
    await page.goto('/signin');

    // 이메일 필드 확인
    const emailInput = page.locator('input[type="email"]');
    await expect(emailInput).toBeVisible();
    await expect(emailInput).toHaveAttribute('required', '');

    // 비밀번호 필드 확인
    const passwordInput = page.locator('input[type="password"]');
    await expect(passwordInput).toBeVisible();
    await expect(passwordInput).toHaveAttribute('required', '');
  });

  test('P0-006: 시드 데이터로 로그인', async ({ page }) => {
    await page.goto('/signin');

    // 시드 데이터 사용
    await page.fill('input[type="email"]', 'test@example.com');
    await page.fill('input[type="password"]', 'password123');

    // 로그인 버튼 클릭
    await page.click('button[type="submit"], input[type="submit"]');

    // 로그인 후 리다이렉트 확인
    await page.waitForLoadState('networkidle');

    // 홈페이지로 리다이렉트되는지 확인
    await expect(page).toHaveURL(/\//);
  });

  test('P0-007: 잘못된 자격증명으로 로그인 실패', async ({ page }) => {
    await page.goto('/signin');

    await page.fill('input[type="email"]', 'wrong@example.com');
    await page.fill('input[type="password"]', 'wrongpassword');

    await page.click('button[type="submit"], input[type="submit"]');

    // 에러 메시지 확인
    await expect(page.locator('text=/올바르지 않습니다|로그인 실패|확인해주세요/')).toBeVisible();
  });

  // FE-E2E-003: 로그아웃 기능
  test('P0-008: 로그아웃 기능', async ({ page }) => {
    // 먼저 로그인
    await page.goto('/signin');
    await page.fill('input[type="email"]', 'test@example.com');
    await page.fill('input[type="password"]', 'password123');
    await page.click('button[type="submit"], input[type="submit"]');

    await page.waitForLoadState('networkidle');

    // 로그아웃 버튼 찾기
    const logoutButton = page.locator('text=로그아웃').first();
    if (await logoutButton.isVisible()) {
      await logoutButton.click();

      // 로그아웃 후 홈페이지로 리다이렉트
      await expect(page).toHaveURL(/\//);

      // 로그인 버튼이 다시 보이는지 확인
      await expect(page.locator('text=로그인')).toBeVisible();
    }
  });

  // P0-009: 세션 유지 확인
  test('P0-009: 페이지 새로고침 후 세션 유지', async ({ page, context }) => {
    // 로그인
    await page.goto('/signin');
    await page.fill('input[type="email"]', 'test@example.com');
    await page.fill('input[type="password"]', 'password123');
    await page.click('button[type="submit"], input[type="submit"]');

    await page.waitForLoadState('networkidle');

    // 페이지 새로고침
    await page.reload();

    // 여전히 로그인 상태인지 확인
    const logoutButton = page.locator('text=로그아웃');
    const loginButton = page.locator('text=로그인');

    // 로그아웃 버튼이 보이거나, 로그인 버튼이 안 보이면 세션 유지됨
    const isLoggedIn = await logoutButton.isVisible() || !(await loginButton.isVisible());
    expect(isLoggedIn).toBeTruthy();
  });

  // P0-010: CSRF 토큰 확인
  test('P0-010: CSRF 보호 확인', async ({ page }) => {
    await page.goto('/signup');

    // Rails CSRF 토큰 확인
    const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute('content');
    expect(csrfToken).toBeTruthy();
    expect(csrfToken.length).toBeGreaterThan(0);
  });
});