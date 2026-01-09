import { test, expect } from '@playwright/test';

/**
 * Demo Test - 브라우저 동작 확인용
 *
 * 실행 방법:
 * npx playwright test tests/demo/simple-test.spec.ts --headed
 */

test.describe('CertiGraph Demo Test', () => {

  test('데모: 홈페이지 접속 및 기본 요소 확인', async ({ page }) => {
    // 1. 홈페이지 접속
    await page.goto('http://localhost:3030');

    // 페이지 로드 대기
    await page.waitForLoadState('networkidle');

    // 스크린샷 촬영
    await page.screenshot({ path: 'test-results/demo-homepage.png' });

    console.log('✓ 홈페이지 접속 완료');

    // 2. 페이지 제목 확인
    await expect(page).toHaveTitle(/CertiGraph|자격증|Exam/i, { timeout: 10000 });
    console.log('✓ 페이지 제목 확인');

    // 3. 주요 요소 확인 (있으면)
    await page.waitForTimeout(2000);

    // 네비게이션 메뉴 확인
    const nav = page.locator('nav, [role="navigation"]');
    if (await nav.count() > 0) {
      console.log('✓ 네비게이션 메뉴 발견');
    }

    // 로그인/회원가입 버튼 확인
    const signInButton = page.locator('a, button').filter({ hasText: /Sign In|로그인|Login/i });
    if (await signInButton.count() > 0) {
      await signInButton.first().highlight();
      console.log('✓ 로그인 버튼 발견');
      await page.waitForTimeout(1000);
    }

    const signUpButton = page.locator('a, button').filter({ hasText: /Sign Up|회원가입|Register/i });
    if (await signUpButton.count() > 0) {
      await signUpButton.first().highlight();
      console.log('✓ 회원가입 버튼 발견');
      await page.waitForTimeout(1000);
    }

    console.log('✅ 데모 테스트 완료!');
  });

  test('데모: 페이지 네비게이션', async ({ page }) => {
    await page.goto('http://localhost:3030');
    await page.waitForLoadState('networkidle');

    console.log('현재 URL:', page.url());

    // 대시보드 링크 찾기
    const dashboardLink = page.locator('a[href*="dashboard"], a:has-text("Dashboard"), a:has-text("대시보드")');
    if (await dashboardLink.count() > 0) {
      console.log('✓ 대시보드 링크 발견');
      await dashboardLink.first().highlight();
      await page.waitForTimeout(2000);
    }

    // 가격 페이지 링크 찾기
    const pricingLink = page.locator('a[href*="pricing"], a:has-text("Pricing"), a:has-text("가격")');
    if (await pricingLink.count() > 0) {
      console.log('✓ 가격 페이지 링크 발견');
      await pricingLink.first().highlight();
      await page.waitForTimeout(2000);
    }

    await page.screenshot({ path: 'test-results/demo-navigation.png' });
    console.log('✅ 네비게이션 테스트 완료!');
  });

});
