const { chromium } = require('playwright');

async function runTest(testName, testFn) {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });

  console.log(`\n==== ${testName} 시작 ====`);

  try {
    await testFn(page);
    console.log(`✅ ${testName} 성공`);
    return { testName, status: 'passed', error: null };
  } catch (error) {
    console.log(`❌ ${testName} 실패: ${error.message}`);
    return { testName, status: 'failed', error: error.message };
  } finally {
    await browser.close();
  }
}

async function test1_홈페이지(page) {
  await page.goto('http://localhost:3000');

  // 타이틀 확인
  const title = await page.title();
  if (!title.includes('ExamsGraph')) {
    throw new Error(`타이틀에 'ExamsGraph'가 없음: ${title}`);
  }
  console.log(`  ✓ 타이틀 확인: ${title}`);

  // ExamsGraph 로고 확인
  const logo = await page.locator('text=ExamsGraph').first();
  const isVisible = await logo.isVisible();
  if (!isVisible) {
    throw new Error('ExamsGraph 로고가 보이지 않음');
  }
  console.log('  ✓ ExamsGraph 로고 확인');

  // 스크린샷
  await page.screenshot({ path: 'test-results/parallel-home.png', fullPage: true });
  console.log('  ✓ 스크린샷 저장');
}

async function test2_로그인페이지(page) {
  await page.goto('http://localhost:3000/users/sign_in');

  // 타이틀 확인
  const title = await page.title();
  if (!title.includes('ExamsGraph')) {
    throw new Error(`타이틀에 'ExamsGraph'가 없음: ${title}`);
  }
  console.log(`  ✓ 타이틀 확인: ${title}`);

  // 로그인 텍스트 확인
  const loginText = await page.locator('text=로그인').isVisible();
  if (!loginText) {
    throw new Error('로그인 텍스트가 보이지 않음');
  }
  console.log('  ✓ 로그인 텍스트 확인');

  // 이메일 필드 확인
  const emailInput = await page.locator('input[type="email"]').isVisible();
  if (!emailInput) {
    throw new Error('이메일 입력 필드가 보이지 않음');
  }
  console.log('  ✓ 이메일 입력 필드 확인');

  // 비밀번호 필드 확인
  const passwordInput = await page.locator('input[type="password"]').isVisible();
  if (!passwordInput) {
    throw new Error('비밀번호 입력 필드가 보이지 않음');
  }
  console.log('  ✓ 비밀번호 입력 필드 확인');

  // Google OAuth 버튼 확인
  const googleButton = await page.locator('text=Google로 계속하기').isVisible();
  if (!googleButton) {
    throw new Error('Google OAuth 버튼이 보이지 않음');
  }
  console.log('  ✓ Google OAuth 버튼 확인');

  // Kakao OAuth 버튼이 없는지 확인
  const kakaoCount = await page.locator('text=Kakao').count();
  if (kakaoCount > 0) {
    throw new Error('Kakao OAuth 버튼이 여전히 존재함 (제거되어야 함)');
  }
  console.log('  ✓ Kakao OAuth 버튼 제거 확인');

  // 스크린샷
  await page.screenshot({ path: 'test-results/parallel-login.png', fullPage: true });
  console.log('  ✓ 스크린샷 저장');
}

async function test3_회원가입페이지(page) {
  await page.goto('http://localhost:3000/users/sign_up');

  // 타이틀 확인
  const title = await page.title();
  if (!title.includes('ExamsGraph')) {
    throw new Error(`타이틀에 'ExamsGraph'가 없음: ${title}`);
  }
  console.log(`  ✓ 타이틀 확인: ${title}`);

  // 회원가입 텍스트 확인
  const signupText = await page.locator('text=회원가입').isVisible();
  if (!signupText) {
    throw new Error('회원가입 텍스트가 보이지 않음');
  }
  console.log('  ✓ 회원가입 텍스트 확인');

  // 이메일 필드 확인
  const emailInput = await page.locator('input[type="email"]').isVisible();
  if (!emailInput) {
    throw new Error('이메일 입력 필드가 보이지 않음');
  }
  console.log('  ✓ 이메일 입력 필드 확인');

  // 비밀번호 필드 확인 (2개 이상이어야 함)
  const passwordCount = await page.locator('input[type="password"]').count();
  if (passwordCount < 2) {
    throw new Error(`비밀번호 필드가 ${passwordCount}개만 있음 (최소 2개 필요)`);
  }
  console.log(`  ✓ 비밀번호 입력 필드 확인 (${passwordCount}개)`);

  // Google OAuth 버튼 확인
  const googleButton = await page.locator('text=Google로 계속하기').isVisible();
  if (!googleButton) {
    throw new Error('Google OAuth 버튼이 보이지 않음');
  }
  console.log('  ✓ Google OAuth 버튼 확인');

  // 스크린샷
  await page.screenshot({ path: 'test-results/parallel-signup.png', fullPage: true });
  console.log('  ✓ 스크린샷 저장');
}

async function test4_대시보드리다이렉트(page) {
  await page.goto('http://localhost:3000/dashboard');

  // 로그인 페이지로 리다이렉트되어야 함
  await page.waitForURL(/sign_in/, { timeout: 5000 });

  const url = page.url();
  if (!url.includes('sign_in')) {
    throw new Error(`로그인 페이지로 리다이렉트되지 않음: ${url}`);
  }
  console.log(`  ✓ 로그인 페이지로 리다이렉트: ${url}`);

  // 스크린샷
  await page.screenshot({ path: 'test-results/parallel-dashboard-redirect.png', fullPage: true });
  console.log('  ✓ 스크린샷 저장');
}

async function main() {
  console.log('\n🚀 Playwright 병렬 테스트 시작\n');
  console.log('테스트 대상: http://localhost:3000 (Rails App)');
  console.log('병렬 실행: 4개 테스트 동시 실행\n');

  const tests = [
    ['테스트 1: 홈페이지', test1_홈페이지],
    ['테스트 2: 로그인 페이지', test2_로그인페이지],
    ['테스트 3: 회원가입 페이지', test3_회원가입페이지],
    ['테스트 4: 대시보드 리다이렉트', test4_대시보드리다이렉트],
  ];

  // 병렬 실행
  const results = await Promise.all(
    tests.map(([name, fn]) => runTest(name, fn))
  );

  // 결과 요약
  console.log('\n\n📊 테스트 결과 요약\n');
  console.log('='.repeat(60));

  const passed = results.filter(r => r.status === 'passed');
  const failed = results.filter(r => r.status === 'failed');

  results.forEach(result => {
    const icon = result.status === 'passed' ? '✅' : '❌';
    console.log(`${icon} ${result.testName}: ${result.status.toUpperCase()}`);
    if (result.error) {
      console.log(`   에러: ${result.error}`);
    }
  });

  console.log('='.repeat(60));
  console.log(`총 ${results.length}개 테스트`);
  console.log(`성공: ${passed.length}개`);
  console.log(`실패: ${failed.length}개`);
  console.log('='.repeat(60));

  if (failed.length > 0) {
    console.log('\n❌ 일부 테스트가 실패했습니다. 버그를 수정해야 합니다.');
    process.exit(1);
  } else {
    console.log('\n✅ 모든 테스트가 성공했습니다!');
    process.exit(0);
  }
}

main();
