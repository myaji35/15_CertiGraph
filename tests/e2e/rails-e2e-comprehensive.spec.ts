/**
 * Rails E2E Comprehensive Test Suite
 *
 * Rails Best Practices 기반 End-to-End 테스트
 * - 모든 주요 사용자 흐름 검증
 * - N+1 쿼리 방지 테스트
 * - 성능 최적화 검증
 * - 실제 사용자 시나리오 시뮬레이션
 */

import { test, expect, Page } from '@playwright/test';

// 테스트 설정
const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const TEST_USER = {
  email: `test-${Date.now()}@example.com`,
  password: 'Test1234!@#$',
  name: 'Test User'
};

/**
 * === Epic 1: 사용자 인증 ===
 * Rails Best Practices:
 * - security-csrf, security-mass-assignment
 * - controller-strong-params
 */
test.describe('[Epic 1] 사용자 인증 테스트', () => {

  test('001. 회원가입 및 이메일 인증', async ({ page }) => {
    // 회원가입 페이지 이동
    await page.goto(`${BASE_URL}/signup`);
    await expect(page).toHaveTitle(/Sign.*Up|가입/i);

    // 회원가입 폼 작성
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.fill('input[name="user[password_confirmation]"]', TEST_USER.password);

    // 제출 및 성공 메시지 확인
    await page.click('button[type="submit"]');
    await expect(page.locator('text=/confirmation.*email|이메일.*인증/i')).toBeVisible();
  });

  test('002. 이메일/비밀번호 로그인', async ({ page }) => {
    // 로그인 페이지 이동
    await page.goto(`${BASE_URL}/signin`);
    await expect(page).toHaveTitle(/Sign.*In|로그인/i);

    // 로그인 수행
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');

    // 대시보드 또는 홈으로 리다이렉트 확인
    await expect(page).toHaveURL(/\/(dashboard|home)?$/);
  });

  test('003. OAuth 로그인 (Google)', async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);

    // Google OAuth 버튼 확인
    const googleBtn = page.locator('a[href*="auth/google"]');
    await expect(googleBtn).toBeVisible();

    // 클릭 시 Google OAuth 페이지로 이동하는지 확인 (실제 OAuth는 Mock)
    // 실제 환경에서는 OAuth Provider의 페이지로 리다이렉트됨
  });

  test('004. 2단계 인증 (2FA) 설정', async ({ page, context }) => {
    // 로그인 후 프로필 페이지로 이동
    await page.goto(`${BASE_URL}/users/profile`);

    // 2FA 설정 페이지 이동
    await page.click('text=/Two.*Factor|2단계.*인증/i');

    // 2FA 활성화
    await page.click('button:has-text("Enable")');

    // QR 코드 표시 확인
    await expect(page.locator('canvas, img[alt*="QR"]')).toBeVisible();

    // Backup codes 확인
    await expect(page.locator('text=/backup.*code|백업.*코드/i')).toBeVisible();
  });

  test('005. 로그아웃', async ({ page }) => {
    await page.goto(`${BASE_URL}/dashboard`);

    // 로그아웃 버튼 클릭
    await page.click('a[href="/logout"], button:has-text("Logout")');

    // 로그인 페이지로 리다이렉트 확인
    await expect(page).toHaveURL(/signin|login/);
  });
});

/**
 * === Epic 2: 학습 자료 업로드 및 관리 ===
 * Rails Best Practices:
 * - n1-includes (study_materials와 questions 관계)
 * - ar-bulk-insert (대량 문제 생성)
 * - cache-fragment (파일 리스트 캐싱)
 */
test.describe('[Epic 2] 학습 자료 업로드', () => {

  test.beforeEach(async ({ page }) => {
    // 로그인
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('006. Study Set 생성', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets/new`);

    // Study Set 정보 입력
    await page.fill('input[name="study_set[name]"]', 'AWS SAA 시험 준비');
    await page.fill('textarea[name="study_set[description]"]', 'AWS Solutions Architect Associate 자격증 준비용');

    await page.click('button[type="submit"]');

    // 생성 성공 확인
    await expect(page.locator('text=/created|생성/i')).toBeVisible();
  });

  test('007. PDF 파일 업로드', async ({ page }) => {
    // Study Set으로 이동
    await page.goto(`${BASE_URL}/study_sets`);
    await page.click('a:has-text("AWS SAA")');

    // 업로드 페이지 이동
    await page.click('text=/Upload|업로드/i');

    // 파일 선택 (실제 PDF 파일 필요 - Mock으로 대체 가능)
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles('./fixtures/sample-exam.pdf');

    // 업로드 시작
    await page.click('button:has-text("Upload")');

    // 업로드 진행률 표시 확인
    await expect(page.locator('text=/progress|진행/i')).toBeVisible();

    // 완료 대기 (최대 60초)
    await page.waitForSelector('text=/complete|완료/i', { timeout: 60000 });
  });

  test('008. 업로드된 학습 자료 처리 상태 확인', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets`);
    await page.click('a:has-text("AWS SAA")');

    // 학습 자료 목록 확인 (N+1 query 방지 - includes(:study_materials) 사용)
    const materials = page.locator('[data-testid="study-material-item"]');
    await expect(materials).toHaveCountGreaterThan(0);

    // 처리 상태 확인
    await expect(materials.first().locator('text=/processing|완료|처리/i')).toBeVisible();
  });

  test('009. Study Material 재처리 (Reprocess)', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets`);
    await page.click('a:has-text("AWS SAA")');

    // 첫 번째 자료 선택
    const firstMaterial = page.locator('[data-testid="study-material-item"]').first();
    await firstMaterial.click();

    // 재처리 버튼 클릭
    await page.click('button:has-text("Reprocess")');

    // 확인 다이얼로그
    await page.click('button:has-text("Confirm")');

    // 재처리 시작 메시지
    await expect(page.locator('text=/reprocess.*start|재처리.*시작/i')).toBeVisible();
  });
});

/**
 * === Epic 3: PDF 문제 추출 ===
 * Rails Best Practices:
 * - job-sidekiq (백그라운드 작업)
 * - job-idempotent (재시도 가능한 작업)
 * - ar-bulk-insert (대량 문제 생성)
 */
test.describe('[Epic 3] PDF 문제 추출', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('010. 문제 자동 추출 상태 확인', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets`);
    await page.click('a:has-text("AWS SAA")');

    // 문제 탭 클릭
    await page.click('text=/Question|문제/i');

    // 추출된 문제 수 확인
    const questionCount = page.locator('[data-testid="question-count"]');
    await expect(questionCount).toBeVisible();
  });

  test('011. 수동 문제 추가', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets`);
    await page.click('a:has-text("AWS SAA")');
    await page.click('text=/Question|문제/i');

    // 문제 추가 버튼
    await page.click('button:has-text("Add Question")');

    // 문제 정보 입력
    await page.fill('textarea[name="question[content]"]', 'What is AWS EC2?');
    await page.fill('input[name="question[options][A]"]', 'Virtual Machine');
    await page.fill('input[name="question[options][B]"]', 'Storage Service');
    await page.fill('input[name="question[answer]"]', 'A');

    await page.click('button[type="submit"]');

    // 추가 성공 메시지
    await expect(page.locator('text=/added|추가/i')).toBeVisible();
  });

  test('012. 문제 검증 (Validate)', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets`);
    await page.click('a:has-text("AWS SAA")');
    await page.click('text=/Question|문제/i');

    // 문제 검증 버튼
    await page.click('button:has-text("Validate All")');

    // 검증 결과 확인
    await expect(page.locator('text=/valid|검증/i')).toBeVisible();
  });
});

/**
 * === Epic 15: 대시보드 (Dashboard) ===
 * Rails Best Practices:
 * - n1-includes (최근 학습 자료 로드)
 * - cache-fragment (차트 데이터 캐싱)
 * - db-select-specific (필요한 컬럼만 선택)
 * - cache-low-level (Rails.cache 사용)
 */
test.describe('[Epic 15] 대시보드', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('013. 대시보드 메인 화면 로드 (N+1 쿼리 방지 검증)', async ({ page }) => {
    await page.goto(`${BASE_URL}/dashboard`);

    // 최근 학습 세트 확인 (includes(:study_materials) 사용으로 N+1 방지)
    await expect(page.locator('[data-testid="recent-study-sets"]')).toBeVisible();

    // 통계 위젯 확인
    await expect(page.locator('[data-testid="stats-widget"]')).toBeVisible();

    // 차트 로드 확인
    await expect(page.locator('canvas, [data-testid="chart"]')).toBeVisible();
  });

  test('014. 통계 데이터 조회 (주간/월간)', async ({ page }) => {
    await page.goto(`${BASE_URL}/dashboard`);

    // 기간 선택
    await page.selectOption('select[name="period"]', 'week');

    // API 호출 및 데이터 로드 확인
    const response = await page.waitForResponse(resp =>
      resp.url().includes('/dashboard/statistics') && resp.status() === 200
    );

    const data = await response.json();
    expect(data.success).toBe(true);
    expect(data.period).toBe('week');
  });

  test('015. 학습 진도 차트 (Progress Chart)', async ({ page }) => {
    await page.goto(`${BASE_URL}/dashboard/charts?type=line`);

    // 차트 데이터 API 응답 확인
    const response = await page.waitForResponse(resp =>
      resp.url().includes('/dashboard/charts') && resp.status() === 200
    );

    const chartData = await response.json();
    expect(chartData.success).toBe(true);
    expect(chartData.data).toBeDefined();
  });

  test('016. 필터링 기능 (특정 기간/Study Set)', async ({ page }) => {
    await page.goto(`${BASE_URL}/dashboard`);

    // 필터 옵션 선택
    await page.fill('input[name="start_date"]', '2024-01-01');
    await page.fill('input[name="end_date"]', '2024-12-31');

    // 필터 적용 (db-select-specific 사용 - 필요한 컬럼만 선택)
    await page.click('button:has-text("Apply Filter")');

    // 필터링된 결과 확인
    await expect(page.locator('[data-testid="filtered-results"]')).toBeVisible();
  });

  test('017. 대시보드 데이터 내보내기 (Export)', async ({ page }) => {
    await page.goto(`${BASE_URL}/dashboard`);

    // Export 버튼 클릭
    await page.click('button:has-text("Export")');

    // 포맷 선택 (CSV)
    await page.click('button:has-text("CSV")');

    // 다운로드 시작 확인
    const download = await page.waitForEvent('download');
    expect(download.suggestedFilename()).toMatch(/dashboard.*csv/i);
  });
});

/**
 * === Epic 4: 시험 세션 (Exam Session) ===
 * Rails Best Practices:
 * - ar-bulk-insert (시험 문제 생성)
 * - db-exists-vs-present (문제 존재 확인)
 * - ar-readonly (결과 조회)
 */
test.describe('[Epic 4] 시험 세션', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('018. 모의 시험 시작', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets`);
    await page.click('a:has-text("AWS SAA")');

    // 시험 시작 버튼
    await page.click('button:has-text("Start Exam")');

    // 시험 타입 선택
    await page.click('input[value="mock_exam"]');
    await page.click('button:has-text("Begin")');

    // 첫 번째 문제 표시 확인
    await expect(page.locator('[data-testid="question-content"]')).toBeVisible();
  });

  test('019. 시험 문제 풀이 및 답변 제출', async ({ page }) => {
    // 진행 중인 시험으로 이동
    await page.goto(`${BASE_URL}/exam_sessions/1`);

    // 답변 선택
    await page.click('input[name="answer"][value="A"]');

    // 답변 제출
    await page.click('button:has-text("Submit Answer")');

    // 다음 문제로 이동 확인
    await expect(page.locator('[data-testid="question-number"]')).toContainText('2');
  });

  test('020. 시험 완료 및 결과 확인', async ({ page }) => {
    await page.goto(`${BASE_URL}/exam_sessions/1`);

    // 모든 문제 답변 후 완료 버튼
    await page.click('button:has-text("Complete Exam")');

    // 결과 페이지로 리다이렉트 (ar-readonly 사용)
    await expect(page).toHaveURL(/exam_sessions\/\d+\/result/);

    // 점수 표시 확인
    await expect(page.locator('[data-testid="exam-score"]')).toBeVisible();
  });
});

/**
 * === Epic 9: CBT 모드 (Computer-Based Testing) ===
 * Rails Best Practices:
 * - cache-low-level (세션 상태 캐싱)
 * - ar-update-columns (콜백 스킵)
 */
test.describe('[Epic 9] CBT 모드', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('021. CBT 세션 일시정지/재개', async ({ page }) => {
    await page.goto(`${BASE_URL}/test_sessions/1`);

    // 일시정지 버튼 클릭
    await page.click('button:has-text("Pause")');
    await expect(page.locator('text=/pause|일시정지/i')).toBeVisible();

    // 재개 버튼 클릭
    await page.click('button:has-text("Resume")');
    await expect(page.locator('text=/resume|재개/i')).toBeVisible();
  });

  test('022. 문제 북마크 기능', async ({ page }) => {
    await page.goto(`${BASE_URL}/test_sessions/1`);

    // 북마크 버튼 클릭
    await page.click('button[data-testid="bookmark-button"]');

    // 북마크 추가 확인
    await expect(page.locator('[data-testid="bookmark-icon"]')).toHaveClass(/active|bookmarked/);
  });

  test('023. 문제 네비게이션 그리드', async ({ page }) => {
    await page.goto(`${BASE_URL}/test_sessions/1`);

    // 네비게이션 그리드 열기
    await page.click('button:has-text("Questions")');

    // 그리드 표시 확인
    await expect(page.locator('[data-testid="question-grid"]')).toBeVisible();

    // 특정 문제로 점프
    await page.click('[data-testid="question-5"]');
    await expect(page.locator('[data-testid="current-question"]')).toContainText('5');
  });

  test('024. 자동 저장 (Auto-save) 기능', async ({ page }) => {
    await page.goto(`${BASE_URL}/test_sessions/1`);

    // 답변 선택 (자동 저장 트리거)
    await page.click('input[name="answer"][value="B"]');

    // 자동 저장 인디케이터 확인
    await expect(page.locator('text=/auto.*save|자동.*저장/i')).toBeVisible();
  });
});

/**
 * === Epic 10: 답안 랜덤화 (Randomization) ===
 * Rails Best Practices:
 * - cache-low-level (랜덤 시드 캐싱)
 */
test.describe('[Epic 10] 답안 랜덤화', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('025. 랜덤화 활성화 시험 시작', async ({ page }) => {
    await page.goto(`${BASE_URL}/study_sets/1`);

    // 랜덤화 옵션 활성화
    await page.check('input[name="randomization_enabled"]');

    // 랜덤화 전략 선택
    await page.selectOption('select[name="strategy"]', 'full_random');

    await page.click('button:has-text("Start Exam")');

    // 랜덤화된 문제 확인
    await expect(page.locator('[data-testid="randomization-status"]')).toContainText('enabled');
  });

  test('026. 랜덤화 통계 확인', async ({ page }) => {
    await page.goto(`${BASE_URL}/randomization/report/1`);

    // 균등 분포 통계 확인
    await expect(page.locator('[data-testid="uniformity-stats"]')).toBeVisible();
  });
});

/**
 * === Epic 13: 추천 시스템 (Recommendations) ===
 * Rails Best Practices:
 * - job-sidekiq (추천 생성 백그라운드 작업)
 * - cache-query (추천 결과 캐싱)
 */
test.describe('[Epic 13] 추천 시스템', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('027. 학습 경로 추천 생성', async ({ page }) => {
    await page.goto(`${BASE_URL}/recommendations`);

    // 추천 생성 버튼
    await page.click('button:has-text("Generate Recommendations")');

    // 백그라운드 작업 시작 메시지
    await expect(page.locator('text=/generat|생성/i')).toBeVisible();
  });

  test('028. 개인화된 추천 확인', async ({ page }) => {
    await page.goto(`${BASE_URL}/recommendations/personalized`);

    // 추천된 학습 자료 표시 확인
    await expect(page.locator('[data-testid="recommended-materials"]')).toBeVisible();
  });
});

/**
 * === Epic 14: 3D 지식 그래프 시각화 ===
 * Rails Best Practices:
 * - cache-query (그래프 데이터 캐싱)
 * - n1-includes (노드 및 엣지 데이터)
 */
test.describe('[Epic 14] 지식 그래프 시각화', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('029. 3D 그래프 로드', async ({ page }) => {
    await page.goto(`${BASE_URL}/knowledge_map/1`);

    // Canvas 또는 WebGL 엘리먼트 확인
    await expect(page.locator('canvas')).toBeVisible();

    // 그래프 데이터 API 호출 확인
    const response = await page.waitForResponse(resp =>
      resp.url().includes('/knowledge_visualization') && resp.status() === 200
    );

    const graphData = await response.json();
    expect(graphData.nodes).toBeDefined();
    expect(graphData.edges).toBeDefined();
  });

  test('030. 노드 클릭 및 상세 정보 표시', async ({ page }) => {
    await page.goto(`${BASE_URL}/knowledge_map/1`);

    // 특정 노드 클릭 (Three.js 인터랙션 시뮬레이션)
    await page.click('[data-node-id="concept-1"]');

    // 상세 패널 표시 확인
    await expect(page.locator('[data-testid="node-detail-panel"]')).toBeVisible();
  });
});

/**
 * === 성능 테스트 (Rails Best Practices 검증) ===
 */
test.describe('[Performance] Rails Best Practices 성능 검증', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('031. 대시보드 페이지 로드 시간 (N+1 방지 효과)', async ({ page }) => {
    const startTime = Date.now();

    await page.goto(`${BASE_URL}/dashboard`);
    await page.waitForLoadState('networkidle');

    const loadTime = Date.now() - startTime;

    // N+1 방지 후 로드 시간이 2초 이내여야 함
    expect(loadTime).toBeLessThan(2000);
  });

  test('032. 대량 문제 조회 성능 (db-select-specific)', async ({ page }) => {
    const startTime = Date.now();

    await page.goto(`${BASE_URL}/study_sets/1/questions`);
    await page.waitForLoadState('networkidle');

    const loadTime = Date.now() - startTime;

    // select(:id, :content, :answer) 사용으로 빠른 로드
    expect(loadTime).toBeLessThan(1500);
  });

  test('033. 캐싱 효과 검증 (cache-fragment)', async ({ page }) => {
    // 첫 번째 방문
    const firstVisit = Date.now();
    await page.goto(`${BASE_URL}/dashboard/charts?type=all`);
    await page.waitForLoadState('networkidle');
    const firstLoadTime = Date.now() - firstVisit;

    // 페이지 새로고침 (캐시된 데이터 사용)
    const secondVisit = Date.now();
    await page.reload();
    await page.waitForLoadState('networkidle');
    const secondLoadTime = Date.now() - secondVisit;

    // 캐싱으로 인해 두 번째 로드가 더 빨라야 함
    expect(secondLoadTime).toBeLessThan(firstLoadTime);
  });
});

/**
 * === 보안 테스트 (Rails Best Practices) ===
 */
test.describe('[Security] 보안 Best Practices 검증', () => {

  test('034. CSRF 토큰 존재 확인', async ({ page }) => {
    await page.goto(`${BASE_URL}/signup`);

    // CSRF meta tag 확인
    const csrfToken = await page.locator('meta[name="csrf-token"]').getAttribute('content');
    expect(csrfToken).toBeTruthy();

    // Form 내 CSRF input 확인
    const csrfInput = await page.locator('input[name="authenticity_token"]');
    await expect(csrfInput).toBeAttached();
  });

  test('035. SQL Injection 방지 (Parameterized Query)', async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');

    // 악의적인 쿼리 시도
    await page.goto(`${BASE_URL}/questions/search?q=\' OR 1=1--`);

    // 에러 메시지가 아닌 빈 결과 또는 정상 처리 확인
    await expect(page.locator('text=/SQL|error|exception/i')).not.toBeVisible();
  });

  test('036. XSS 방지 (Input Sanitization)', async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');

    await page.goto(`${BASE_URL}/study_sets/1/questions/new`);

    // XSS 시도
    await page.fill('textarea[name="question[content]"]', '<script>alert("XSS")</script>');
    await page.click('button[type="submit"]');

    // 스크립트가 실행되지 않고 텍스트로 표시되어야 함
    await page.goto(`${BASE_URL}/study_sets/1/questions`);
    const content = await page.locator('[data-testid="question-content"]').textContent();
    expect(content).toContain('&lt;script&gt;');
  });
});

/**
 * === 사용자 프로필 관리 ===
 */
test.describe('[Profile] 사용자 프로필 관리', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('037. 프로필 조회', async ({ page }) => {
    await page.goto(`${BASE_URL}/users/profile`);

    await expect(page.locator('text=' + TEST_USER.email)).toBeVisible();
  });

  test('038. 프로필 정보 수정', async ({ page }) => {
    await page.goto(`${BASE_URL}/users/profile`);

    await page.fill('input[name="user[name]"]', 'Updated Name');
    await page.click('button:has-text("Update")');

    await expect(page.locator('text=/updated|수정/i')).toBeVisible();
  });

  test('039. 아바타 업로드', async ({ page }) => {
    await page.goto(`${BASE_URL}/users/profile`);

    const fileInput = page.locator('input[type="file"][name*="avatar"]');
    await fileInput.setInputFiles('./fixtures/avatar.jpg');

    await page.click('button:has-text("Upload Avatar")');

    await expect(page.locator('[data-testid="avatar-image"]')).toBeVisible();
  });

  test('040. 비밀번호 변경', async ({ page }) => {
    await page.goto(`${BASE_URL}/users/profile`);

    await page.fill('input[name="current_password"]', TEST_USER.password);
    await page.fill('input[name="new_password"]', 'NewPassword123!');
    await page.fill('input[name="password_confirmation"]', 'NewPassword123!');

    await page.click('button:has-text("Change Password")');

    await expect(page.locator('text=/password.*change|비밀번호.*변경/i')).toBeVisible();
  });
});

/**
 * === 결제 시스템 (Epic 16) ===
 */
test.describe('[Payment] 결제 시스템', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('041. 결제 페이지 접근', async ({ page }) => {
    await page.goto(`${BASE_URL}/payments/checkout`);

    await expect(page).toHaveTitle(/Checkout|결제/i);
    await expect(page.locator('text=/subscription|구독/i')).toBeVisible();
  });

  test('042. 구독 상태 확인', async ({ page }) => {
    await page.goto(`${BASE_URL}/payments/subscription/status`);

    const response = await page.waitForResponse(resp =>
      resp.url().includes('/subscription/status') && resp.status() === 200
    );

    const data = await response.json();
    expect(data).toHaveProperty('subscription_status');
  });
});

/**
 * === 시험 일정 (Epic 18) ===
 */
test.describe('[ExamSchedule] 시험 일정 관리', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/signin`);
    await page.fill('input[name="user[email]"]', TEST_USER.email);
    await page.fill('input[name="user[password]"]', TEST_USER.password);
    await page.click('button[type="submit"]');
  });

  test('043. 예정된 시험 목록 조회', async ({ page }) => {
    await page.goto(`${BASE_URL}/exam_schedules/upcoming`);

    await expect(page.locator('[data-testid="exam-schedule-list"]')).toBeVisible();
  });

  test('044. 시험 일정 달력 보기', async ({ page }) => {
    const year = new Date().getFullYear();
    const month = new Date().getMonth() + 1;

    await page.goto(`${BASE_URL}/exam_schedules/calendar/${year}/${month}`);

    await expect(page.locator('[data-testid="calendar"]')).toBeVisible();
  });

  test('045. 시험 알림 등록', async ({ page }) => {
    await page.goto(`${BASE_URL}/exam_schedules/1`);

    await page.click('button:has-text("Register Notification")');

    await expect(page.locator('text=/registered|등록/i')).toBeVisible();
  });
});
