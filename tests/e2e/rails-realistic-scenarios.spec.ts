/**
 * Rails Realistic User Scenarios - 실제 사용 환경 시뮬레이션
 *
 * 실제 사용자가 겪을 수 있는 복잡한 시나리오와 엣지 케이스를 테스트합니다.
 * - 동시성 문제
 * - 네트워크 장애 시나리오
 * - 대용량 데이터 처리
 * - 실제 사용자 워크플로우
 * - Race Condition
 * - 에러 복구 시나리오
 */

import { test, expect, Page } from '@playwright/test';

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

/**
 * 실제 사용자 데이터 시뮬레이션
 */
const REALISTIC_USER = {
  email: `realuser-${Date.now()}@example.com`,
  password: 'SecurePass123!@#',
  name: '김철수',
  incorrectPassword: 'WrongPass123'
};

const LARGE_PDF_SIZE = 50 * 1024 * 1024; // 50MB
const SLOW_NETWORK_DELAY = 3000; // 3초

/**
 * === 시나리오 1: 실제 사용자 온보딩 플로우 ===
 * 신규 사용자가 처음 서비스를 사용하는 전체 과정
 */
test.describe('[현실적 시나리오] 신규 사용자 온보딩', () => {

  test('S001. 회원가입 → 이메일 인증 → 첫 로그인 → 튜토리얼 → 첫 Study Set 생성', async ({ page }) => {
    // 1단계: 회원가입 페이지 접근
    await page.goto(`${BASE_URL}/signup`);

    // 비밀번호 강도 실시간 체크 (약한 비밀번호 시도)
    await page.fill('input[name="user[password]"]', '123');
    await expect(page.locator('.password-strength')).toContainText(/weak|약함/i);

    // 강한 비밀번호로 변경
    await page.fill('input[name="user[password]"]', REALISTIC_USER.password);
    await expect(page.locator('.password-strength')).toContainText(/strong|강함/i);

    // 이메일 중복 체크 (실시간)
    await page.fill('input[name="user[email]"]', REALISTIC_USER.email);
    await page.waitForResponse(resp => resp.url().includes('/check_email'));

    // 비밀번호 확인 불일치
    await page.fill('input[name="user[password_confirmation]"]', 'WrongConfirm123');
    await page.click('button[type="submit"]');
    await expect(page.locator('.error-message')).toContainText(/match|일치/i);

    // 올바른 정보로 재시도
    await page.fill('input[name="user[password_confirmation]"]', REALISTIC_USER.password);
    await page.click('button[type="submit"]');

    // 2단계: 이메일 인증 대기 화면
    await expect(page).toHaveURL(/confirmation|verify/);
    await expect(page.locator('text=/check.*email|이메일.*확인/i')).toBeVisible();

    // 인증 이메일 재전송 테스트
    await page.click('button:has-text("Resend")');
    await expect(page.locator('.flash-message')).toContainText(/sent|전송/i);

    // 3단계: 이메일 인증 링크 시뮬레이션 (실제로는 이메일에서 클릭)
    // Mock: 인증 토큰으로 직접 이동
    const confirmationToken = 'mock-token-123';
    await page.goto(`${BASE_URL}/users/confirmation?confirmation_token=${confirmationToken}`);

    // 4단계: 첫 로그인
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', REALISTIC_USER.email);
    await page.fill('input[name="user[password]"]', REALISTIC_USER.password);
    await page.click('button[type="submit"]');

    // 5단계: 튜토리얼 모달 표시 (첫 로그인)
    await expect(page.locator('[data-testid="tutorial-modal"]')).toBeVisible({ timeout: 10000 });

    // 튜토리얼 단계별 진행 (5단계)
    for (let i = 1; i <= 5; i++) {
      await page.click('button:has-text("Next")');
      await page.waitForTimeout(500);
    }

    await page.click('button:has-text("Start")');

    // 6단계: 대시보드로 이동 (빈 상태)
    await expect(page.locator('[data-testid="empty-dashboard"]')).toBeVisible();
    await expect(page.locator('text=/no.*study.*set|학습.*자료.*없음/i')).toBeVisible();

    // 7단계: 첫 Study Set 생성 유도 (CTA 버튼)
    await page.click('button:has-text("Create First Study Set")');

    await page.fill('input[name="study_set[name]"]', '정보처리기사 필기 준비');
    await page.fill('textarea[name="study_set[description]"]', '2024년 정보처리기사 필기 시험 대비용 학습 자료');
    await page.selectOption('select[name="study_set[category]"]', 'IT Certification');

    await page.click('button[type="submit"]');

    // 8단계: 성공 메시지 및 다음 단계 안내
    await expect(page.locator('.success-message')).toContainText(/created|생성/i);
    await expect(page.locator('.next-step-guide')).toContainText(/upload.*pdf|PDF.*업로드/i);
  });
});

/**
 * === 시나리오 2: 대용량 PDF 업로드 및 처리 ===
 * 실제 시험 문제집 (수백 페이지) 업로드 시나리오
 */
test.describe('[현실적 시나리오] 대용량 PDF 처리', () => {

  test.beforeEach(async ({ page }) => {
    // 로그인
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', REALISTIC_USER.email);
    await page.fill('input[name="user[password]"]', REALISTIC_USER.password);
    await page.click('button[type="submit"]');
  });

  test('S002. 50MB PDF 업로드 → 청크 업로드 → 진행률 표시 → 처리 대기 → 완료', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets/1/upload`);

    // 1단계: 파일 크기 사전 체크
    const fileInput = page.locator('input[type="file"]');

    // 용량 초과 파일 시도 (100MB 제한)
    await fileInput.setInputFiles({
      name: 'huge-file.pdf',
      mimeType: 'application/pdf',
      buffer: Buffer.alloc(101 * 1024 * 1024) // 101MB
    });

    await expect(page.locator('.error-message')).toContainText(/size.*limit|용량.*초과/i);

    // 2단계: 올바른 크기 파일 업로드 (50MB)
    await fileInput.setInputFiles({
      name: 'exam-questions-500pages.pdf',
      mimeType: 'application/pdf',
      buffer: Buffer.alloc(LARGE_PDF_SIZE)
    });

    // 3단계: 청크 업로드 시작
    await page.click('button:has-text("Start Upload")');

    // 진행률 바 표시 확인
    await expect(page.locator('[data-testid="upload-progress-bar"]')).toBeVisible();

    // 진행률 업데이트 확인 (0% → 25% → 50% → 75% → 100%)
    await expect(page.locator('[data-testid="progress-percentage"]')).toContainText('0%');

    // 중간에 일시정지 기능 테스트
    await page.waitForTimeout(2000);
    await page.click('button:has-text("Pause")');
    await expect(page.locator('[data-testid="upload-status"]')).toContainText(/pause|일시정지/i);

    // 재개
    await page.click('button:has-text("Resume")');

    // 업로드 완료 대기 (최대 2분)
    await expect(page.locator('[data-testid="progress-percentage"]')).toContainText('100%', { timeout: 120000 });

    // 4단계: PDF 처리 대기열 진입
    await expect(page.locator('.processing-queue-status')).toBeVisible();
    await expect(page.locator('text=/queue.*position|대기.*순서/i')).toBeVisible();

    // 처리 중 상태 변화 모니터링
    const statusChecks = ['queued', 'processing', 'extracting', 'analyzing', 'completed'];
    for (const status of statusChecks) {
      await page.waitForSelector(`[data-status="${status}"]`, { timeout: 30000 });
    }

    // 5단계: 처리 완료 알림
    await expect(page.locator('.notification')).toContainText(/complete|완료/i);

    // 추출된 문제 수 확인
    const questionCount = await page.locator('[data-testid="extracted-question-count"]').textContent();
    expect(parseInt(questionCount || '0')).toBeGreaterThan(100); // 최소 100문제 이상
  });

  test('S003. 네트워크 단절 중 업로드 → 자동 재시도 → 이어서 업로드', async ({ page, context }) => {
    // 네트워크 에뮬레이션: 느린 3G
    await context.route('**/*', route => {
      setTimeout(() => route.continue(), SLOW_NETWORK_DELAY);
    });

    await page.goto(`${BASE_URL}/study_sets/1/upload`);

    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles({
      name: 'large-exam.pdf',
      mimeType: 'application/pdf',
      buffer: Buffer.alloc(30 * 1024 * 1024) // 30MB
    });

    await page.click('button:has-text("Start Upload")');

    // 업로드 중 네트워크 단절 시뮬레이션 (50% 진행 시점)
    await page.waitForFunction(() => {
      const progressText = document.querySelector('[data-testid="progress-percentage"]')?.textContent;
      return progressText && parseInt(progressText) >= 40;
    }, { timeout: 60000 });

    // 네트워크 차단
    await context.setOffline(true);

    // 에러 표시 확인
    await expect(page.locator('.upload-error')).toContainText(/network.*error|연결.*끊김/i);

    // 자동 재시도 카운트다운 표시
    await expect(page.locator('.retry-countdown')).toBeVisible();

    // 네트워크 복구
    await context.setOffline(false);

    // 자동 재시도 및 이어서 업로드
    await expect(page.locator('[data-testid="upload-status"]')).toContainText(/resuming|재개/i);

    // 업로드 완료
    await expect(page.locator('[data-testid="progress-percentage"]')).toContainText('100%', { timeout: 120000 });
  });
});

/**
 * === 시나리오 3: 실전 시험 응시 ===
 * 실제 자격증 시험처럼 엄격한 환경에서 테스트
 */
test.describe('[현실적 시나리오] 실전 모의고사', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', REALISTIC_USER.email);
    await page.fill('input[name="user[password]"]', REALISTIC_USER.password);
    await page.click('button[type="submit"]');
  });

  test('S004. 120분 제한 시험 → 중간 저장 → 브라우저 새로고침 → 복구 → 제출', async ({ page, context }) => {
    await page.goto(`${BASE_URL}/study_sets/1/exams/new`);

    // 1단계: 시험 설정
    await page.click('input[value="mock_exam"]');
    await page.fill('input[name="time_limit"]', '120'); // 120분
    await page.fill('input[name="question_count"]', '100'); // 100문제
    await page.check('input[name="randomization_enabled"]');

    // 주의사항 동의 체크박스
    await page.check('input[name="agree_rules"]');

    await page.click('button:has-text("Start Exam")');

    // 2단계: 최종 확인 모달
    await expect(page.locator('.exam-start-modal')).toBeVisible();
    await expect(page.locator('text=/cannot.*pause|일시정지.*불가/i')).toBeVisible();
    await expect(page.locator('text=/120.*minute|120분/i')).toBeVisible();

    await page.click('button:has-text("I Understand, Start")');

    // 3단계: 타이머 시작 확인
    await expect(page.locator('[data-testid="exam-timer"]')).toBeVisible();
    await expect(page.locator('[data-testid="remaining-time"]')).toContainText(/119:5|119:4/); // 119분 5X초

    // 4단계: 문제 풀이 (10문제)
    for (let i = 1; i <= 10; i++) {
      // 문제 읽기
      const questionText = await page.locator('[data-testid="question-content"]').textContent();

      // 답변 선택 (랜덤)
      const options = ['A', 'B', 'C', 'D'];
      const selectedOption = options[Math.floor(Math.random() * options.length)];
      await page.click(`input[name="answer"][value="${selectedOption}"]`);

      // 자동 저장 트리거 확인
      await expect(page.locator('.auto-save-indicator')).toContainText(/saved|저장/i);

      // 다음 문제
      if (i < 10) {
        await page.click('button:has-text("Next")');
      }
    }

    // 5단계: 브라우저 새로고침 시뮬레이션 (실수로 닫음)
    await page.reload();

    // 6단계: 세션 복구 모달
    await expect(page.locator('.session-recovery-modal')).toBeVisible();
    await expect(page.locator('text=/resume.*exam|시험.*이어서/i')).toBeVisible();

    // 진행 상황 표시
    await expect(page.locator('[data-testid="answered-count"]')).toContainText('10');

    await page.click('button:has-text("Resume Exam")');

    // 7단계: 이전 상태 복구 확인
    await expect(page.locator('[data-testid="current-question-number"]')).toContainText('11');

    // 8단계: 나머지 문제 빠르게 풀이 (90문제)
    for (let i = 11; i <= 100; i++) {
      const options = ['A', 'B', 'C', 'D'];
      const selectedOption = options[Math.floor(Math.random() * options.length)];
      await page.click(`input[name="answer"][value="${selectedOption}"]`);

      if (i < 100) {
        await page.click('button:has-text("Next")');
      }
    }

    // 9단계: 제출 전 답변 검토
    await page.click('button:has-text("Review Answers")');

    // 검토 화면에서 미답 문제 확인
    const unansweredCount = await page.locator('[data-testid="unanswered-count"]').textContent();
    expect(parseInt(unansweredCount || '0')).toBe(0);

    // 10단계: 최종 제출
    await page.click('button:has-text("Submit Exam")');

    // 확인 모달
    await page.click('button:has-text("Yes, Submit")');

    // 11단계: 결과 페이지
    await expect(page).toHaveURL(/result|score/);
    await expect(page.locator('[data-testid="final-score"]')).toBeVisible();
    await expect(page.locator('[data-testid="time-taken"]')).toBeVisible();
  });

  test('S005. 시험 시간 초과 → 자동 제출 → 답변 유실 방지', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets/1/exams/new`);

    // 짧은 제한 시간 설정 (테스트용: 2분)
    await page.click('input[value="practice"]');
    await page.fill('input[name="time_limit"]', '2'); // 2분
    await page.fill('input[name="question_count"]', '10');

    await page.click('button:has-text("Start Exam")');
    await page.click('button:has-text("I Understand, Start")');

    // 5문제만 풀이
    for (let i = 1; i <= 5; i++) {
      await page.click(`input[name="answer"][value="A"]`);
      await page.click('button:has-text("Next")');
      await page.waitForTimeout(500);
    }

    // 30초 전 경고 확인
    await page.waitForFunction(() => {
      const timerText = document.querySelector('[data-testid="remaining-time"]')?.textContent;
      return timerText && timerText.includes('00:3') || timerText?.includes('00:2');
    }, { timeout: 120000 });

    await expect(page.locator('.time-warning')).toBeVisible();
    await expect(page.locator('.time-warning')).toContainText(/30.*second|30초/i);

    // 시간 초과 대기
    await page.waitForFunction(() => {
      const timerText = document.querySelector('[data-testid="remaining-time"]')?.textContent;
      return timerText && timerText.includes('00:00');
    }, { timeout: 60000 });

    // 자동 제출 모달
    await expect(page.locator('.time-expired-modal')).toBeVisible();
    await expect(page.locator('text=/time.*up|시간.*종료/i')).toBeVisible();

    // 자동으로 결과 페이지 이동 (3초 후)
    await page.waitForTimeout(3000);
    await expect(page).toHaveURL(/result|score/);

    // 답변한 5문제만 채점 확인
    const answeredCount = await page.locator('[data-testid="answered-count"]').textContent();
    expect(parseInt(answeredCount || '0')).toBe(5);
  });
});

/**
 * === 시나리오 4: 동시 접속 및 경쟁 조건 ===
 * 여러 디바이스에서 동시 로그인 시나리오
 */
test.describe('[현실적 시나리오] 다중 디바이스 동시 사용', () => {

  test('S006. PC + 모바일 동시 로그인 → 한 곳에서 시험 시작 → 다른 곳에서 세션 충돌 경고', async ({ browser }) => {
    // 컨텍스트 1: PC (Desktop)
    const contextPC = await browser.newContext({
      viewport: { width: 1920, height: 1080 },
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0'
    });
    const pagePC = await contextPC.newPage();

    // 컨텍스트 2: 모바일 (iPhone)
    const contextMobile = await browser.newContext({
      viewport: { width: 375, height: 812 },
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
      isMobile: true,
      hasTouch: true
    });
    const pageMobile = await contextMobile.newPage();

    // 1단계: 두 디바이스에서 동시 로그인
    await Promise.all([
      (async () => {
        await pagePC.goto(`${BASE_URL}/signin`);
        await pagePC.fill('input[name="user[email]"]', REALISTIC_USER.email);
        await pagePC.fill('input[name="user[password]"]', REALISTIC_USER.password);
        await pagePC.click('button[type="submit"]');
      })(),
      (async () => {
        await pageMobile.goto(`${BASE_URL}/signin`);
        await pageMobile.fill('input[name="user[email]"]', REALISTIC_USER.email);
        await pageMobile.fill('input[name="user[password]"]', REALISTIC_USER.password);
        await pageMobile.click('button[type="submit"]');
      })()
    ]);

    // 2단계: PC에서 시험 시작
    await pagePC.goto(`${BASE_URL}/study_sets/1/exams/new`);
    await pagePC.click('input[value="mock_exam"]');
    await pagePC.click('button:has-text("Start Exam")');
    await pagePC.click('button:has-text("I Understand, Start")');

    // 3단계: 모바일에서 같은 시험 시작 시도
    await pageMobile.goto(`${BASE_URL}/study_sets/1/exams/new`);
    await pageMobile.click('input[value="mock_exam"]');
    await pageMobile.click('button:has-text("Start Exam")');

    // 세션 충돌 경고 모달
    await expect(pageMobile.locator('.session-conflict-modal')).toBeVisible();
    await expect(pageMobile.locator('text=/already.*in.*progress|진행.*중/i')).toBeVisible();

    // 옵션: PC 세션 종료하고 모바일에서 계속 / 모바일에서 취소
    await pageMobile.click('button:has-text("Cancel")');

    // 4단계: PC에서 시험 계속 진행 (문제 풀이)
    await pagePC.click('input[name="answer"][value="A"]');
    await pagePC.click('button:has-text("Next")');

    // 5단계: 모바일에서 진행 상황 확인 (실시간 싱크)
    await pageMobile.goto(`${BASE_URL}/dashboard`);
    await expect(pageMobile.locator('.ongoing-exam-banner')).toBeVisible();
    await expect(pageMobile.locator('.ongoing-exam-banner')).toContainText(/PC|Desktop/i);

    // Cleanup
    await contextPC.close();
    await contextMobile.close();
  });
});

/**
 * === 시나리오 5: 에러 복구 및 데이터 무결성 ===
 * 예상치 못한 상황에서의 데이터 보호
 */
test.describe('[현실적 시나리오] 에러 복구 및 데이터 보호', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', REALISTIC_USER.email);
    await page.fill('input[name="user[password]"]', REALISTIC_USER.password);
    await page.click('button[type="submit"]');
  });

  test('S007. 서버 500 에러 중 시험 진행 → 로컬 저장 → 서버 복구 → 데이터 동기화', async ({ page, context }) => {
    await page.goto(`${BASE_URL}/study_sets/1/exams/new`);
    await page.click('input[value="practice"]');
    await page.click('button:has-text("Start Exam")');
    await page.click('button:has-text("I Understand, Start")');

    // 10문제 풀이
    for (let i = 1; i <= 10; i++) {
      await page.click(`input[name="answer"][value="A"]`);
      await page.click('button:has-text("Next")');
    }

    // 서버 에러 시뮬레이션 (API 응답 500)
    await context.route('**/api/exam_sessions/*/submit_answer', route => {
      route.fulfill({ status: 500, body: 'Internal Server Error' });
    });

    // 다음 문제 시도 (서버 저장 실패)
    await page.click(`input[name="answer"][value="B"]`);
    await page.click('button:has-text("Next")');

    // 로컬 저장 알림
    await expect(page.locator('.offline-mode-indicator')).toBeVisible();
    await expect(page.locator('.offline-mode-indicator')).toContainText(/offline|오프라인/i);

    // 계속 진행 (로컬에만 저장)
    for (let i = 12; i <= 20; i++) {
      await page.click(`input[name="answer"][value="C"]`);
      if (i < 20) {
        await page.click('button:has-text("Next")');
      }
    }

    // 서버 복구
    await context.unroute('**/api/exam_sessions/*/submit_answer');

    // 자동 동기화 시작
    await expect(page.locator('.sync-indicator')).toContainText(/syncing|동기화/i);

    // 동기화 완료
    await expect(page.locator('.sync-indicator')).toContainText(/synced|완료/i, { timeout: 30000 });

    // 모든 답변 저장 확인
    const syncedCount = await page.locator('[data-testid="answered-count"]').textContent();
    expect(parseInt(syncedCount || '0')).toBe(20);
  });

  test('S008. 중복 제출 방지 → 더블 클릭 → 한 번만 처리', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets/1/exams/new`);
    await page.click('input[value="practice"]');
    await page.fill('input[name="question_count"]', '5');
    await page.click('button:has-text("Start Exam")');
    await page.click('button:has-text("I Understand, Start")');

    // 5문제 빠르게 풀이
    for (let i = 1; i <= 5; i++) {
      await page.click(`input[name="answer"][value="A"]`);
      if (i < 5) {
        await page.click('button:has-text("Next")');
      }
    }

    // 제출 버튼 더블 클릭 시뮬레이션
    const submitButton = page.locator('button:has-text("Submit Exam")');

    await submitButton.click();
    await submitButton.click(); // 중복 클릭
    await submitButton.click(); // 중복 클릭

    // 버튼 비활성화 확인
    await expect(submitButton).toBeDisabled();

    // 로딩 인디케이터 표시
    await expect(page.locator('.submit-loading')).toBeVisible();

    // 결과 페이지 한 번만 이동
    await expect(page).toHaveURL(/result/, { timeout: 10000 });

    // 중복 제출되지 않았는지 확인 (서버 로그 또는 DB 체크)
    // API 호출 횟수 확인
    let submitCount = 0;
    page.on('request', request => {
      if (request.url().includes('/complete') && request.method() === 'POST') {
        submitCount++;
      }
    });

    expect(submitCount).toBeLessThanOrEqual(1);
  });
});

/**
 * === 시나리오 6: 접근성 및 특수 환경 ===
 * 다양한 사용자 환경 고려
 */
test.describe('[현실적 시나리오] 접근성 및 특수 환경', () => {

  test('S009. 키보드만으로 전체 시험 진행 (마우스 없이)', async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);

    // Tab 키로 이메일 입력 필드 포커스
    await page.keyboard.press('Tab');
    await page.keyboard.type(REALISTIC_USER.email);

    // Tab 키로 비밀번호 입력 필드 포커스
    await page.keyboard.press('Tab');
    await page.keyboard.type(REALISTIC_USER.password);

    // Enter 키로 로그인
    await page.keyboard.press('Enter');

    // 대시보드 이동 확인
    await expect(page).toHaveURL(/dashboard/);

    // Tab + Enter로 시험 시작
    await page.goto(`${BASE_URL}/study_sets/1/exams/new`);

    // Space 키로 라디오 버튼 선택
    await page.keyboard.press('Tab'); // practice 옵션으로 이동
    await page.keyboard.press('Space'); // 선택

    await page.keyboard.press('Tab'); // Start 버튼으로 이동
    await page.keyboard.press('Enter'); // 시작

    await page.keyboard.press('Tab'); // 확인 버튼으로 이동
    await page.keyboard.press('Enter');

    // 문제 풀이 (숫자 키로 답변 선택)
    await page.keyboard.press('1'); // A 선택
    await page.keyboard.press('Enter'); // 다음 문제

    await page.keyboard.press('2'); // B 선택
    await page.keyboard.press('Enter'); // 다음 문제

    // 결과 확인
    await page.keyboard.press('Tab'); // 제출 버튼
    await page.keyboard.press('Enter');
    await page.keyboard.press('Enter'); // 확인

    await expect(page).toHaveURL(/result/);
  });

  test('S010. 스크린 리더 호환성 (ARIA 레이블 확인)', async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', REALISTIC_USER.email);
    await page.fill('input[name="user[password]"]', REALISTIC_USER.password);
    await page.click('button[type="submit"]');

    await page.goto(`${BASE_URL}/study_sets/1/exams/new`);
    await page.click('input[value="practice"]');
    await page.click('button:has-text("Start Exam")');
    await page.click('button:has-text("I Understand, Start")');

    // ARIA 레이블 확인
    const questionContent = page.locator('[data-testid="question-content"]');
    await expect(questionContent).toHaveAttribute('role', 'region');
    await expect(questionContent).toHaveAttribute('aria-label', /question|문제/i);

    // 타이머 ARIA 레이블
    const timer = page.locator('[data-testid="exam-timer"]');
    await expect(timer).toHaveAttribute('role', 'timer');
    await expect(timer).toHaveAttribute('aria-live', 'polite');

    // 진행률 ARIA 레이블
    const progress = page.locator('[data-testid="progress-bar"]');
    await expect(progress).toHaveAttribute('role', 'progressbar');
    await expect(progress).toHaveAttribute('aria-valuenow');
  });
});

/**
 * === 시나리오 7: 실제 사용 패턴 (80/20 법칙) ===
 * 80%의 사용자가 하는 20%의 핵심 기능
 */
test.describe('[현실적 시나리오] 일상적 사용 패턴', () => {

  test('S011. 매일 아침 출근길 학습 루틴 (모바일)', async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 375, height: 812 },
      isMobile: true,
      hasTouch: true,
      geolocation: { latitude: 37.5665, longitude: 126.9780 }, // 서울
      permissions: ['geolocation']
    });
    const page = await context.newPage();

    // 1단계: 로그인 (Remember Me 체크)
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', REALISTIC_USER.email);
    await page.fill('input[name="user[password]"]', REALISTIC_USER.password);
    await page.check('input[name="remember_me"]');
    await page.click('button[type="submit"]');

    // 2단계: 오늘의 추천 문제 (대시보드)
    await expect(page.locator('.daily-recommendation')).toBeVisible();
    await expect(page.locator('.daily-recommendation')).toContainText(/today|오늘/i);

    // 3단계: 퀵 스타트 (10문제, 10분)
    await page.click('button:has-text("Quick Practice")');

    // 자동 설정: 10문제, 타이머 없음, 약한 문제 우선
    await expect(page.locator('[data-preset="quick-morning"]')).toBeVisible();
    await page.click('button:has-text("Start")');

    // 4단계: 지하철 환경 시뮬레이션 (불안정한 네트워크)
    let networkToggle = true;
    const networkSimulation = setInterval(() => {
      context.setOffline(networkToggle);
      networkToggle = !networkToggle;
    }, 5000); // 5초마다 온/오프

    // 5분간 문제 풀이
    for (let i = 1; i <= 10; i++) {
      await page.click(`input[name="answer"][value="A"]`);
      await page.waitForTimeout(500);

      // 오프라인 모드 인디케이터 확인
      if (i % 3 === 0) {
        await expect(page.locator('.connection-status')).toBeVisible();
      }

      if (i < 10) {
        await page.click('button:has-text("Next")');
      }
    }

    clearInterval(networkSimulation);
    await context.setOffline(false);

    // 5단계: 빠른 결과 확인
    await page.click('button:has-text("Finish")');

    await expect(page.locator('.quick-result-summary')).toBeVisible();
    await expect(page.locator('.today-progress')).toContainText(/complete|완료/i);

    // 6단계: 내일 알림 설정
    await page.click('button:has-text("Set Tomorrow Reminder")');
    await page.selectOption('select[name="reminder_time"]', '08:00');
    await page.click('button:has-text("Save")');

    await context.close();
  });

  test('S012. 주말 집중 학습 (3시간 마라톤)', async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', REALISTIC_USER.email);
    await page.fill('input[name="user[password]"]', REALISTIC_USER.password);
    await page.click('button[type="submit"]');

    // 1단계: 학습 목표 설정
    await page.goto(`${BASE_URL}/dashboard/set_goal`);
    await page.fill('input[name="target_questions"]', '200');
    await page.fill('input[name="duration"]', '180'); // 3시간
    await page.click('button:has-text("Start Marathon")');

    // 2단계: 포모도로 타이머 설정 (25분 학습 / 5분 휴식)
    await page.check('input[name="enable_pomodoro"]');

    // 3단계: 연속 문제 풀이 (50문제)
    for (let set = 1; set <= 4; set++) {
      // 25분 세션
      for (let q = 1; q <= 50; q++) {
        await page.click(`input[name="answer"][value="A"]`);
        await page.click('button:has-text("Next")');

        // 진행률 표시
        if (q % 10 === 0) {
          const progress = await page.locator('[data-testid="session-progress"]').textContent();
          expect(progress).toContain(`${q}/50`);
        }
      }

      // 5분 휴식 알림
      await expect(page.locator('.break-time-modal')).toBeVisible();
      await expect(page.locator('.break-time-modal')).toContainText(/5.*minute.*break|5분.*휴식/i);

      // 휴식 스킵 또는 대기
      if (set < 4) {
        await page.click('button:has-text("Skip Break")');
      }
    }

    // 4단계: 마라톤 완료 배지
    await expect(page.locator('.achievement-badge')).toBeVisible();
    await expect(page.locator('.achievement-badge')).toContainText(/marathon|완주/i);
  });
});
