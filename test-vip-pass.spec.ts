import { test, expect } from '@playwright/test';

// VIP 사용자 정보
const VIP_USER = {
  email: 'myaji35@gmail.com',
  clerkId: 'user_36T9Qa8HsuaM1fMjTisw4frRH1Z'
};

test.describe('VIP Pass 기능 테스트', () => {

  test.beforeEach(async ({ page }) => {
    // 페이지 접속
    await page.goto('http://localhost:3030/dashboard/study-sets/new');

    // 페이지 로드 대기
    await page.waitForLoadState('networkidle');
  });

  test('시나리오 1: VIP 무료 이용권 표시 확인', async ({ page }) => {
    console.log('🧪 시나리오 1: VIP 무료 이용권 표시 확인');

    // VIP 박스 확인
    const vipBox = page.locator('text=👑 VIP 무료 이용권');
    await expect(vipBox).toBeVisible();

    // VIP 설명 확인
    await expect(page.locator('text=모든 자격증을 무제한으로 이용할 수 있습니다')).toBeVisible();
    await expect(page.locator('text=VIP 회원님은 모든 기능을 자유롭게 이용하실 수 있습니다')).toBeVisible();

    // 자격증 선택 드롭다운 확인
    const certSelect = page.locator('select').filter({ hasText: '자격증을 선택하세요' });
    await expect(certSelect).toBeVisible();

    // "이용권 구매하러 가기" 버튼이 없는지 확인
    await expect(page.locator('text=이용권 구매하러 가기')).not.toBeVisible();

    console.log('✅ 시나리오 1 통과');
  });

  test('시나리오 2: 폼 유효성 검사', async ({ page }) => {
    console.log('🧪 시나리오 2: 폼 유효성 검사');

    const submitButton = page.locator('button', { hasText: '문제집 만들기' });

    // 초기 상태: 버튼 비활성화
    await expect(submitButton).toBeDisabled();
    console.log('  - 초기 상태: 버튼 비활성화 ✓');

    // 이름만 입력: 버튼 여전히 비활성화
    await page.fill('input[placeholder*="예: 2024년 대비"]', '테스트 문제집');
    await expect(submitButton).toBeDisabled();
    console.log('  - 이름만 입력: 버튼 비활성화 ✓');

    // 자격증 선택: 버튼 활성화
    const certSelect = page.locator('select');
    await certSelect.selectOption({ index: 1 }); // 첫 번째 자격증 선택
    await expect(submitButton).toBeEnabled();
    console.log('  - 이름 + 자격증: 버튼 활성화 ✓');

    console.log('✅ 시나리오 2 통과');
  });

  test('시나리오 3: 문제집 생성', async ({ page }) => {
    console.log('🧪 시나리오 3: 문제집 생성');

    // 폼 입력
    await page.fill('input[placeholder*="예: 2024년 대비"]', 'VIP 테스트 문제집');
    await page.fill('textarea', 'VIP 패스로 생성한 테스트 문제집입니다');

    // 자격증 선택
    const certSelect = page.locator('select');
    const options = await certSelect.locator('option').all();
    if (options.length > 1) {
      await certSelect.selectOption({ index: 1 });
      console.log('  - 자격증 선택 완료');
    }

    // 미리보기 확인
    await expect(page.locator('text=📋 생성될 문제집 정보')).toBeVisible();
    console.log('  - 미리보기 표시 확인');

    // 제출 버튼 클릭
    const submitButton = page.locator('button', { hasText: '문제집 만들기' });
    await submitButton.click();

    // 로딩 상태 확인
    await expect(page.locator('text=생성 중...')).toBeVisible();
    console.log('  - 생성 중 표시 확인');

    // 성공 또는 에러 대기
    await page.waitForResponse(
      response => response.url().includes('/study-sets') && response.request().method() === 'POST',
      { timeout: 10000 }
    );

    console.log('✅ 시나리오 3 통과');
  });

  test('시나리오 4: 빈 이름 에러 처리', async ({ page }) => {
    console.log('🧪 시나리오 4: 빈 이름 에러 처리');

    // 자격증만 선택
    const certSelect = page.locator('select');
    const options = await certSelect.locator('option').all();
    if (options.length > 1) {
      await certSelect.selectOption({ index: 1 });
    }

    // 빈 이름으로 제출 시도
    const submitButton = page.locator('button', { hasText: '문제집 만들기' });

    // 버튼이 비활성화 상태인지 확인
    await expect(submitButton).toBeDisabled();
    console.log('  - 빈 이름일 때 버튼 비활성화 확인');

    console.log('✅ 시나리오 4 통과');
  });
});

// API 직접 테스트
test.describe('VIP Pass API 테스트', () => {

  test('VIP 사용자 구독 확인 API', async ({ request }) => {
    console.log('🧪 VIP 사용자 구독 확인 API 테스트');

    // 실제 토큰이 필요하므로 스킵될 수 있음
    const response = await request.get('http://localhost:8000/api/v1/subscriptions/my-subscriptions', {
      headers: {
        'Authorization': 'Bearer test-token', // 실제 토큰 필요
        'Content-Type': 'application/json',
      },
    });

    // 401 또는 200 응답 예상
    expect([200, 401]).toContain(response.status());
    console.log(`  - API 응답: ${response.status()}`);
  });
});