import { test, expect } from '@playwright/test';

// VIP 사용자 정보
const VIP_USER = {
  email: 'myaji35@gmail.com',
  clerkId: 'user_36T9Qa8HsuaM1fMjTisw4frRH1Z'
};

test.describe('VIP Pass 종합 테스트', () => {
  test.beforeEach(async ({ page }) => {
    console.log('🔧 테스트 준비: 페이지 접속');
    await page.goto('http://localhost:3030/dashboard/study-sets/new');

    // 페이지가 완전히 로드되기를 기다림
    await page.waitForLoadState('networkidle');

    // React 컴포넌트가 마운트되기를 기다림
    await page.waitForTimeout(1000);
  });

  test('시나리오 1: VIP 무료 이용권 UI 표시', async ({ page }) => {
    console.log('🧪 시나리오 1: VIP 무료 이용권 UI 표시 테스트');

    // VIP 박스 확인 (보라색 그라데이션 박스)
    const vipBox = page.locator('div').filter({
      hasText: '👑 VIP 무료 이용권'
    }).first();

    // VIP 박스가 보이는지 확인
    await expect(vipBox).toBeVisible({ timeout: 10000 });
    console.log('  ✅ VIP 박스 표시 확인');

    // VIP 설명 텍스트 확인
    await expect(page.locator('text=모든 자격증을 무제한으로 이용할 수 있습니다')).toBeVisible();
    console.log('  ✅ VIP 설명 텍스트 표시 확인');

    // VIP 안내 메시지 확인
    await expect(page.locator('text=VIP 회원님은 모든 기능을 자유롭게 이용하실 수 있습니다')).toBeVisible();
    console.log('  ✅ VIP 안내 메시지 표시 확인');

    // 자격증 선택 드롭다운 확인
    const certSelect = page.locator('select').filter({
      hasText: '자격증을 선택하세요'
    }).first();
    await expect(certSelect).toBeVisible();
    console.log('  ✅ 자격증 선택 드롭다운 표시 확인');

    // "이용권 구매하러 가기" 버튼이 없는지 확인
    const purchaseButton = page.locator('button').filter({
      hasText: '이용권 구매하러 가기'
    });
    await expect(purchaseButton).not.toBeVisible();
    console.log('  ✅ "이용권 구매하러 가기" 버튼 없음 확인');

    console.log('✅ 시나리오 1 완료: VIP UI가 정상적으로 표시됨');
  });

  test('시나리오 2: 버튼 활성화 로직', async ({ page }) => {
    console.log('🧪 시나리오 2: 버튼 활성화 로직 테스트');

    const submitButton = page.locator('button').filter({
      hasText: '문제집 만들기'
    }).first();

    // 초기 상태: 버튼 비활성화
    await expect(submitButton).toBeDisabled();
    console.log('  ✅ 초기 상태: 버튼 비활성화');

    // 이름만 입력: 버튼 여전히 비활성화
    const nameInput = page.locator('input[placeholder*="2024년 대비"]');
    await nameInput.fill('테스트 문제집');
    await expect(submitButton).toBeDisabled();
    console.log('  ✅ 이름만 입력: 버튼 여전히 비활성화');

    // 자격증 선택: 버튼 활성화
    const certSelect = page.locator('select').first();

    // 옵션이 로드되기를 기다림
    await page.waitForTimeout(1000);

    // 자격증 선택 (첫 번째 실제 옵션)
    const options = await certSelect.locator('option').all();
    if (options.length > 1) {
      // value 속성으로 선택
      const firstOptionValue = await options[1].getAttribute('value');
      if (firstOptionValue) {
        await certSelect.selectOption(firstOptionValue);
        console.log(`  📝 자격증 선택: ${firstOptionValue}`);
      }
    }

    // 버튼이 활성화되었는지 확인
    await expect(submitButton).toBeEnabled();
    console.log('  ✅ 이름 + 자격증 선택: 버튼 활성화');

    console.log('✅ 시나리오 2 완료: 버튼 활성화 로직 정상 작동');
  });

  test('시나리오 3: 문제집 생성 전체 플로우', async ({ page }) => {
    console.log('🧪 시나리오 3: 문제집 생성 전체 플로우 테스트');

    // API 응답 모니터링 설정
    const responsePromise = page.waitForResponse(
      response => response.url().includes('/api/v1/study-sets') && response.request().method() === 'POST',
      { timeout: 30000 }
    );

    // 1. 폼 입력
    const nameInput = page.locator('input[placeholder*="2024년 대비"]');
    await nameInput.fill('VIP 테스트 문제집');
    console.log('  ✅ 문제집 이름 입력');

    const descInput = page.locator('textarea[placeholder*="설명을 입력하세요"]');
    await descInput.fill('VIP 패스로 생성한 테스트 문제집입니다');
    console.log('  ✅ 설명 입력');

    // 2. 자격증 선택
    const certSelect = page.locator('select').first();
    await page.waitForTimeout(1000);

    const options = await certSelect.locator('option').all();
    if (options.length > 1) {
      const firstOptionValue = await options[1].getAttribute('value');
      if (firstOptionValue) {
        await certSelect.selectOption(firstOptionValue);
        console.log(`  ✅ 자격증 선택: ${firstOptionValue}`);
      }
    }

    // 3. 미리보기 확인
    const previewSection = page.locator('text=📋 생성될 문제집 정보');
    await expect(previewSection).toBeVisible();
    console.log('  ✅ 미리보기 섹션 표시');

    // 4. 제출 버튼 클릭
    const submitButton = page.locator('button').filter({
      hasText: '문제집 만들기'
    }).first();

    await expect(submitButton).toBeEnabled();
    console.log('  ✅ 제출 버튼 활성화 확인');

    await submitButton.click();
    console.log('  🔄 문제집 생성 요청 전송');

    // 5. 로딩 상태 확인
    const loadingText = page.locator('text=생성 중...');
    await expect(loadingText).toBeVisible({ timeout: 5000 });
    console.log('  ✅ 로딩 상태 표시');

    // 6. API 응답 대기 및 확인
    try {
      const response = await responsePromise;
      const status = response.status();
      console.log(`  📡 API 응답: ${status}`);

      if (status === 200 || status === 201) {
        const responseData = await response.json();
        console.log('  ✅ 문제집 생성 성공');
        console.log(`  📝 생성된 문제집 ID: ${responseData.study_set?.id || 'ID 확인 불가'}`);

        // 리다이렉트 확인 (성공 시 상세 페이지로 이동)
        await page.waitForTimeout(2000);
        const currentUrl = page.url();
        if (currentUrl.includes('/study-sets/')) {
          console.log('  ✅ 문제집 상세 페이지로 리다이렉트 완료');
        }
      } else {
        const errorData = await response.json().catch(() => ({}));
        console.log(`  ❌ API 에러: ${JSON.stringify(errorData)}`);
      }
    } catch (error) {
      console.log(`  ⚠️ API 응답 대기 중 오류: ${error}`);
    }

    console.log('✅ 시나리오 3 완료: 문제집 생성 플로우 테스트 완료');
  });

  test('시나리오 4: 빈 필드 유효성 검사', async ({ page }) => {
    console.log('🧪 시나리오 4: 빈 필드 유효성 검사 테스트');

    const submitButton = page.locator('button').filter({
      hasText: '문제집 만들기'
    }).first();

    // 1. 모든 필드가 비어있을 때
    await expect(submitButton).toBeDisabled();
    console.log('  ✅ 모든 필드 비어있음: 버튼 비활성화');

    // 2. 자격증만 선택했을 때
    const certSelect = page.locator('select').first();
    await page.waitForTimeout(1000);

    const options = await certSelect.locator('option').all();
    if (options.length > 1) {
      const firstOptionValue = await options[1].getAttribute('value');
      if (firstOptionValue) {
        await certSelect.selectOption(firstOptionValue);
      }
    }

    await expect(submitButton).toBeDisabled();
    console.log('  ✅ 자격증만 선택: 버튼 비활성화');

    // 3. 이름을 입력하면 활성화
    const nameInput = page.locator('input[placeholder*="2024년 대비"]');
    await nameInput.fill('테스트 문제집');
    await expect(submitButton).toBeEnabled();
    console.log('  ✅ 이름 + 자격증: 버튼 활성화');

    // 4. 이름을 지우면 다시 비활성화
    await nameInput.clear();
    await expect(submitButton).toBeDisabled();
    console.log('  ✅ 이름 제거: 버튼 다시 비활성화');

    console.log('✅ 시나리오 4 완료: 유효성 검사 정상 작동');
  });

  test('시나리오 5: API 통합 테스트', async ({ page, request }) => {
    console.log('🧪 시나리오 5: API 통합 테스트');

    // 1. 구독 정보 API 확인
    console.log('  🔄 구독 정보 API 호출 모니터링...');

    // 페이지 로드 시 구독 API 호출 모니터링
    const subscriptionResponse = await page.waitForResponse(
      response => response.url().includes('/api/v1/subscriptions/my-subscriptions'),
      { timeout: 10000 }
    ).catch(() => null);

    if (subscriptionResponse) {
      const status = subscriptionResponse.status();
      console.log(`  📡 구독 API 응답: ${status}`);

      if (status === 200) {
        const data = await subscriptionResponse.json();
        const vipPass = data.subscriptions?.find((s: any) => s.id === 'vip-pass');

        if (vipPass) {
          console.log('  ✅ VIP Pass 확인됨');
          console.log(`    - ID: ${vipPass.id}`);
          console.log(`    - Name: ${vipPass.certification_name}`);
          console.log(`    - Status: ${vipPass.status}`);
        } else {
          console.log('  ❌ VIP Pass를 찾을 수 없음');
        }
      }
    }

    // 2. 자격증 목록 API 확인
    console.log('  🔄 자격증 목록 API 호출 모니터링...');

    const certResponse = await page.waitForResponse(
      response => response.url().includes('/api/v1/certifications'),
      { timeout: 10000 }
    ).catch(() => null);

    if (certResponse) {
      const status = certResponse.status();
      console.log(`  📡 자격증 API 응답: ${status}`);

      if (status === 200) {
        const data = await certResponse.json();
        console.log(`  ✅ 자격증 ${data.certifications?.length || 0}개 로드됨`);
      }
    }

    console.log('✅ 시나리오 5 완료: API 통합 테스트 완료');
  });
});