import { test, expect } from '@playwright/test';

test.describe('P0 - 핵심 기능 테스트', () => {

  // 홈페이지 테스트
  test('P0-011: 홈페이지 로드 및 기본 요소', async ({ page }) => {
    await page.goto('/');

    // 타이틀 확인
    await expect(page).toHaveTitle(/ExamsGraph/);

    // 메인 헤딩 확인
    await expect(page.locator('text=기출문제 PDF를 업로드하면')).toBeVisible();
    await expect(page.locator('text=자동으로 분리합니다')).toBeVisible();

    // 네비게이션 바 확인
    await expect(page.locator('nav')).toBeVisible();
    await expect(page.locator('text=ExamsGraph').first()).toBeVisible();
  });

  test('P0-012: 메인 아이콘 표시 확인', async ({ page }) => {
    await page.goto('/');

    // 🧠 아이콘이 포함된 요소 확인
    const iconElement = page.locator('.bg-blue-600.rounded-full').first();
    await expect(iconElement).toBeVisible();

    // 아이콘 내용 확인
    const iconText = await iconElement.textContent();
    expect(iconText).toContain('🧠');
  });

  test('P0-013: 주요 기능 섹션 표시', async ({ page }) => {
    await page.goto('/');

    // 3가지 주요 기능 확인
    await expect(page.locator('text=PDF 자동 파싱')).toBeVisible();
    await expect(page.locator('text=CBT 모의고사')).toBeVisible();
    await expect(page.locator('text=AI 취약점 분석')).toBeVisible();
  });

  test('P0-014: CTA 버튼 확인', async ({ page }) => {
    await page.goto('/');

    // 무료 시작하기 버튼
    const ctaButton = page.locator('text=무료 시작하기').first();
    await expect(ctaButton).toBeVisible();

    // 버튼 클릭 가능 확인
    await expect(ctaButton).toBeEnabled();

    // 클릭 시 회원가입 페이지로 이동
    await ctaButton.click();
    await expect(page).toHaveURL(/signup/);
  });

  test('P0-015: 인기 문제집 섹션 표시', async ({ page }) => {
    await page.goto('/');

    await expect(page.locator('text=인기 문제집')).toBeVisible();

    // 문제집 카드 확인 (최소 1개 이상)
    const examCards = page.locator('text=문제').locator('..');
    await expect(examCards).toHaveCount(3); // 시드 데이터로 3개 생성됨
  });

  test('P0-016: 네비게이션 링크 작동', async ({ page }) => {
    await page.goto('/');

    // 로그인 링크 테스트
    await page.click('text=로그인');
    await expect(page).toHaveURL(/signin/);

    // 홈으로 돌아가기
    await page.goto('/');

    // 무료 시작하기 링크 테스트
    await page.click('nav >> text=무료 시작하기');
    await expect(page).toHaveURL(/signup/);
  });

  test('P0-017: 푸터 정보 표시', async ({ page }) => {
    await page.goto('/');

    // 푸터 섹션 확인
    await expect(page.locator('footer')).toBeVisible();
    await expect(page.locator('text=© 2024 ExamsGraph')).toBeVisible();

    // 푸터 링크들 확인
    await expect(page.locator('footer >> text=서비스')).toBeVisible();
    await expect(page.locator('footer >> text=회사')).toBeVisible();
    await expect(page.locator('footer >> text=법적고지')).toBeVisible();
  });

  test('P0-018: 반응형 디자인 - 모바일 뷰', async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 375, height: 667 }, // iPhone SE
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)'
    });

    const page = await context.newPage();
    await page.goto('/');

    // 모바일 뷰에서 주요 요소 확인
    await expect(page.locator('text=ExamsGraph').first()).toBeVisible();
    await expect(page.locator('text=기출문제 PDF를 업로드하면')).toBeVisible();

    await context.close();
  });

  test('P0-019: 페이지 로딩 성능', async ({ page }) => {
    const startTime = Date.now();
    await page.goto('/');
    const loadTime = Date.now() - startTime;

    // 3초 이내 로딩 확인
    expect(loadTime).toBeLessThan(3000);
  });

  test('P0-020: 404 페이지 처리', async ({ page }) => {
    const response = await page.goto('/nonexistent-page-12345');

    // 404 응답 확인
    expect(response.status()).toBe(404);
  });

  // 데이터베이스 연결 확인
  test('P0-021: 시드 데이터 표시 확인', async ({ page }) => {
    await page.goto('/');

    // 시드 데이터의 문제집이 표시되는지 확인
    await expect(page.locator('text=2024 사회복지사 1급 기출')).toBeVisible();
    await expect(page.locator('text=정신건강론')).toBeVisible();
    await expect(page.locator('text=사회복지정책론')).toBeVisible();
  });

  test('P0-022: 통계 정보 표시', async ({ page }) => {
    await page.goto('/signin');

    // 통계 정보 확인
    await expect(page.locator('text=1,000+')).toBeVisible();
    await expect(page.locator('text=50,000+')).toBeVisible();
    await expect(page.locator('text=95%')).toBeVisible();
  });
});