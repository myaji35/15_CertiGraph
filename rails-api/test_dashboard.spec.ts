import { test, expect } from '@playwright/test';

test.describe('Dashboard 접근 및 인증 테스트', () => {
  test('비로그인 사용자 대시보드 접근 차단', async ({ page }) => {
    console.log('🔍 비로그인 상태에서 대시보드 접근 테스트');

    // 대시보드 직접 접근 시도
    await page.goto('http://localhost:3000/dashboard');

    // 로그인 페이지로 리다이렉트 확인
    await expect(page).toHaveURL(/.*signin/);
    console.log('✅ 비로그인 사용자는 로그인 페이지로 리다이렉트됨');

    // 로그인 페이지에 Google 로그인 버튼 확인
    const googleButton = page.locator('button:has-text("Google로 계속하기")');
    await expect(googleButton).toBeVisible();
    console.log('✅ 로그인 페이지에 Google 로그인 버튼 표시됨');
  });

  test('메인 페이지 네비게이션 바 확인', async ({ page }) => {
    console.log('🔍 메인 페이지 네비게이션 바 테스트');

    await page.goto('http://localhost:3000/');
    await page.waitForLoadState('networkidle');

    // 네비게이션 바 확인
    const navbar = page.locator('nav');
    await expect(navbar).toBeVisible();

    // ExamsGraph 로고 확인
    const logo = page.locator('h1:has-text("ExamsGraph")');
    await expect(logo).toBeVisible();
    console.log('✅ ExamsGraph 로고 표시됨');

    // 뇌 아이콘 확인
    const brainIcon = page.locator('nav span:has-text("🧠")');
    await expect(brainIcon).toBeVisible();
    console.log('✅ 뇌 아이콘 표시됨');

    // 네비게이션 링크들 확인
    const publicSets = page.locator('a:has-text("공개 문제집")');
    await expect(publicSets).toBeVisible();
    console.log('✅ 공개 문제집 링크 표시됨');

    const guide = page.locator('a:has-text("사용설명")');
    await expect(guide).toBeVisible();
    console.log('✅ 사용설명 링크 표시됨');

    const pricing = page.locator('nav a:has-text("요금제")');
    await expect(pricing).toBeVisible();
    console.log('✅ 요금제 링크 표시됨');

    // 로그인 상태 확인
    const loginButton = page.locator('a:has-text("로그인")');
    const logoutButton = page.locator('button:has-text("로그아웃")');

    if (await loginButton.isVisible({ timeout: 1000 }).catch(() => false)) {
      console.log('📊 현재 상태: 비로그인');

      const signupButton = page.locator('a:has-text("무료 시작하기")');
      await expect(signupButton).toBeVisible();
      console.log('✅ 무료 시작하기 버튼 표시됨');
    } else if (await logoutButton.isVisible({ timeout: 1000 }).catch(() => false)) {
      console.log('📊 현재 상태: 로그인됨');

      const dashboardLink = page.locator('a:has-text("대시보드")');
      await expect(dashboardLink).toBeVisible();
      console.log('✅ 대시보드 링크 표시됨');

      // 사용자 인사말 확인
      const greeting = page.locator('span:has-text("안녕하세요")');
      if (await greeting.isVisible({ timeout: 1000 }).catch(() => false)) {
        const greetingText = await greeting.textContent();
        console.log(`✅ 사용자 인사: ${greetingText}`);
      }
    }
  });

  test('세션 상태 및 쿠키 확인', async ({ page }) => {
    console.log('🔍 세션 및 쿠키 상태 확인');

    await page.goto('http://localhost:3000/');

    // 쿠키 확인
    const cookies = await page.context().cookies();
    console.log('🍪 현재 쿠키 목록:');
    cookies.forEach(cookie => {
      if (cookie.name.includes('session') || cookie.name.includes('remember')) {
        console.log(`  - ${cookie.name}: ${cookie.value ? '존재함' : '없음'}`);
      }
    });

    // localStorage 확인
    const localStorageData = await page.evaluate(() => {
      const data = {};
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key) {
          data[key] = localStorage.getItem(key);
        }
      }
      return data;
    });

    if (Object.keys(localStorageData).length > 0) {
      console.log('📦 localStorage 데이터:', Object.keys(localStorageData));
    } else {
      console.log('📦 localStorage: 비어있음');
    }
  });

  test('로그인 후 대시보드 접근 시뮬레이션', async ({ page }) => {
    console.log('🔍 로그인 플로우 시뮬레이션 (수동 로그인 필요)');
    console.log('\n📝 수동 테스트 절차:');
    console.log('1. http://localhost:3000/signin 접속');
    console.log('2. "Google로 계속하기" 클릭');
    console.log('3. Google 계정으로 로그인');
    console.log('4. 로그인 완료 후 대시보드 확인');
    console.log('\n💡 로그인 성공 시 확인 사항:');
    console.log('- 메인 페이지로 리다이렉트');
    console.log('- 네비게이션 바에 사용자 이름 표시');
    console.log('- 로그아웃 버튼 표시');
    console.log('- 대시보드 링크 표시');
    console.log('- /dashboard 접근 가능');
  });
});