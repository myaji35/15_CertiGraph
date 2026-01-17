import { test, expect } from '@playwright/test';

test.describe('Rails App 빠른 테스트', () => {

  test('홈페이지 로드 테스트', async ({ page }) => {
    console.log('테스트 시작: 홈페이지 로드');
    await page.goto('http://localhost:3000');

    // 페이지 제목 확인
    await expect(page).toHaveTitle(/ExamsGraph/);
    console.log('✓ 페이지 제목 확인 완료');

    // ExamsGraph 로고 확인
    const logo = page.locator('text=ExamsGraph').first();
    await expect(logo).toBeVisible();
    console.log('✓ ExamsGraph 로고 확인 완료');

    // 스크린샷 저장
    await page.screenshot({ path: 'test-results/homepage.png', fullPage: true });
    console.log('✓ 스크린샷 저장 완료');
  });

  test('로그인 페이지 테스트', async ({ page }) => {
    console.log('테스트 시작: 로그인 페이지');
    await page.goto('http://localhost:3000/users/sign_in');

    // 페이지 제목 확인
    await expect(page).toHaveTitle(/ExamsGraph/);
    console.log('✓ 페이지 제목 확인 완료');

    // 로그인 텍스트 확인
    await expect(page.locator('text=로그인')).toBeVisible();
    console.log('✓ 로그인 텍스트 확인 완료');

    // 이메일 입력 필드 확인
    const emailInput = page.locator('input[type="email"]');
    await expect(emailInput).toBeVisible();
    console.log('✓ 이메일 입력 필드 확인 완료');

    // 비밀번호 입력 필드 확인
    const passwordInput = page.locator('input[type="password"]');
    await expect(passwordInput).toBeVisible();
    console.log('✓ 비밀번호 입력 필드 확인 완료');

    // Google OAuth 버튼 확인
    const googleButton = page.locator('text=Google로 계속하기');
    await expect(googleButton).toBeVisible();
    console.log('✓ Google OAuth 버튼 확인 완료');

    // Kakao OAuth 버튼이 없는지 확인 (제거됨)
    const kakaoButton = page.locator('text=Kakao');
    await expect(kakaoButton).not.toBeVisible();
    console.log('✓ Kakao OAuth 버튼 제거 확인 완료');

    // 스크린샷 저장
    await page.screenshot({ path: 'test-results/login-page.png', fullPage: true });
    console.log('✓ 스크린샷 저장 완료');
  });

  test('회원가입 페이지 테스트', async ({ page }) => {
    console.log('테스트 시작: 회원가입 페이지');
    await page.goto('http://localhost:3000/users/sign_up');

    // 페이지 제목 확인
    await expect(page).toHaveTitle(/ExamsGraph/);
    console.log('✓ 페이지 제목 확인 완료');

    // 회원가입 텍스트 확인
    await expect(page.locator('text=회원가입')).toBeVisible();
    console.log('✓ 회원가입 텍스트 확인 완료');

    // 이메일 입력 필드 확인
    const emailInput = page.locator('input[type="email"]');
    await expect(emailInput).toBeVisible();
    console.log('✓ 이메일 입력 필드 확인 완료');

    // 비밀번호 입력 필드 확인 (2개여야 함: password, password_confirmation)
    const passwordInputs = page.locator('input[type="password"]');
    const count = await passwordInputs.count();
    expect(count).toBeGreaterThanOrEqual(2);
    console.log(`✓ 비밀번호 입력 필드 확인 완료 (${count}개)`);

    // Google OAuth 버튼 확인
    const googleButton = page.locator('text=Google로 계속하기');
    await expect(googleButton).toBeVisible();
    console.log('✓ Google OAuth 버튼 확인 완료');

    // 스크린샷 저장
    await page.screenshot({ path: 'test-results/signup-page.png', fullPage: true });
    console.log('✓ 스크린샷 저장 완료');
  });

  test('대시보드 접근 (인증 필요) 테스트', async ({ page }) => {
    console.log('테스트 시작: 대시보드 접근');
    await page.goto('http://localhost:3000/dashboard');

    // 로그인 페이지로 리다이렉트되어야 함
    await page.waitForURL(/sign_in/, { timeout: 5000 });
    console.log('✓ 로그인 페이지로 리다이렉트 확인 완료');

    // 스크린샷 저장
    await page.screenshot({ path: 'test-results/dashboard-redirect.png', fullPage: true });
    console.log('✓ 스크린샷 저장 완료');
  });
});
