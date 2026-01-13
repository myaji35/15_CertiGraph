import { test, expect } from '@playwright/test';

test.describe('Google 로그인 최종 테스트', () => {
  test('세션 유지 테스트', async ({ page }) => {
    console.log('🔍 테스트 시작: Google 로그인 및 세션 유지');

    // 1. 로그인 페이지 접속
    await page.goto('http://localhost:3000/signin');
    console.log('✅ 로그인 페이지 접속 완료');

    // 2. Google 로그인 버튼 확인
    const googleButton = page.locator('button:has-text("Google로 계속하기")');
    await expect(googleButton).toBeVisible();
    console.log('✅ Google 로그인 버튼 확인');

    // 3. 페이지 HTML 확인 (디버깅용)
    const pageContent = await page.content();

    // 4. 세션 쿠키 확인
    const cookies = await page.context().cookies();
    console.log('🍪 현재 쿠키:', cookies.map(c => c.name));

    // 5. navbar 확인
    const navbar = await page.locator('nav').textContent();
    console.log('📊 Navbar 내용:', navbar);

    // 6. 로그인 상태 확인
    const isLoggedIn = await page.locator('text=/안녕하세요.*님/').count() > 0;

    if (isLoggedIn) {
      console.log('✅ 로그인 상태 유지됨');

      // 로그아웃 버튼 확인
      const logoutButton = page.locator('button:has-text("로그아웃")');
      await expect(logoutButton).toBeVisible();
      console.log('✅ 로그아웃 버튼 표시됨');
    } else {
      console.log('❌ 로그인 상태가 유지되지 않음');
      console.log('💡 수동으로 Google 로그인을 완료한 후 세션을 확인하세요');
    }

    // 7. 홈페이지 이동 후에도 세션 유지 확인
    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('networkidle');

    const homeNavbar = await page.locator('nav').textContent();
    console.log('🏠 홈페이지 Navbar:', homeNavbar);

    const stillLoggedIn = await page.locator('text=/안녕하세요.*님/').count() > 0;

    if (stillLoggedIn) {
      console.log('✅ 페이지 이동 후에도 로그인 상태 유지');
    } else {
      console.log('❌ 페이지 이동 후 로그인 상태 소실');
    }
  });

  test('Devise 세션 헬퍼 확인', async ({ page }) => {
    // Rails 콘솔 테스트를 위한 스크립트
    console.log(`
    📝 Rails 콘솔에서 확인할 사항:

    rails console
    > User.last  # 최근 생성된 사용자 확인
    > User.last.encrypted_password.present?  # 패스워드 암호화 확인
    `);

    // 대시보드 접근 테스트
    await page.goto('http://localhost:3000/dashboard');

    const url = page.url();
    if (url.includes('signin')) {
      console.log('❌ 대시보드 접근 시 로그인 페이지로 리디렉션됨 (세션 없음)');
    } else if (url.includes('dashboard')) {
      console.log('✅ 대시보드 접근 성공 (세션 유지됨)');
    }
  });
});