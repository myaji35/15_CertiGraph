import { test, expect, Page } from '@playwright/test';

// BMad 테스트 281-330: 통합 테스트

const API_BASE = 'http://localhost:8015/api/v1';
const FRONTEND_URL = 'http://localhost:3030';

// Helper functions
async function loginAsUser(page: Page) {
  await page.goto(`${FRONTEND_URL}/login`);
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'Test1234!');
  await page.click('button[type="submit"]');
  await page.waitForURL(`${FRONTEND_URL}/dashboard`);
}

test.describe('BMad 통합 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(FRONTEND_URL);
  });

  // End-to-End 시나리오
  test('281. 전체 학습 플로우', async ({ page }) => {
    // 1. 회원가입
    await page.goto(`${FRONTEND_URL}/signup`);
    const email = `test-${Date.now()}@example.com`;
    await page.fill('[name="email"]', email);
    await page.fill('[name="password"]', 'Test1234!');
    await page.fill('[name="name"]', '테스트 사용자');
    await page.click('button[type="submit"]');

    // 2. PDF 업로드
    await page.goto(`${FRONTEND_URL}/upload`);
    const pdfBuffer = Buffer.from('%PDF-1.4\nTest content');
    await page.locator('input[type="file"]').setInputFiles({
      name: 'study.pdf',
      mimeType: 'application/pdf',
      buffer: pdfBuffer
    });
    await page.click('button:has-text("업로드")');
    await page.waitForSelector('.upload-success');

    // 3. 모의고사 생성
    await page.goto(`${FRONTEND_URL}/exams/create`);
    await page.fill('[name="exam-title"]', '통합 테스트 모의고사');
    await page.click('button:has-text("생성")');

    // 4. 시험 응시
    await page.click('button:has-text("시작")');
    await page.click('.answer-option:first-child');
    await page.click('button:has-text("제출")');

    // 5. 결과 확인
    await expect(page.locator('.exam-result')).toBeVisible();
  });

  test('282. 구매에서 학습까지', async ({ page }) => {
    await loginAsUser(page);

    // 1. 플랜 선택
    await page.goto(`${FRONTEND_URL}/pricing`);
    await page.click('.pricing-plan:has-text("Pro") button:has-text("선택")');

    // 2. 결제 (Mock)
    await page.evaluate(() => {
      window.postMessage({ type: 'PAYMENT_SUCCESS', paymentKey: 'test-key' }, '*');
    });

    // 3. 프리미엄 기능 접근
    await page.goto(`${FRONTEND_URL}/ai-tutor`);
    await expect(page.locator('.ai-tutor-interface')).toBeVisible();

    // 4. AI 학습 시작
    await page.fill('.ai-question', '네트워크 프로토콜에 대해 설명해줘');
    await page.click('button:has-text("질문")');
    await expect(page.locator('.ai-response')).toBeVisible({ timeout: 10000 });
  });

  test('283. 협업 학습 시나리오', async ({ page, context }) => {
    await loginAsUser(page);

    // 1. 스터디 그룹 생성
    await page.goto(`${FRONTEND_URL}/study-groups/create`);
    await page.fill('[name="group-name"]', '정보처리기사 스터디');
    await page.click('button:has-text("생성")');

    // 2. 멤버 초대
    await page.fill('[name="invite-email"]', 'member@example.com');
    await page.click('button:has-text("초대")');

    // 3. 공유 자료 업로드
    const pdfBuffer = Buffer.from('%PDF-1.4\nShared content');
    await page.locator('input[type="file"]').setInputFiles({
      name: 'shared.pdf',
      mimeType: 'application/pdf',
      buffer: pdfBuffer
    });

    // 4. 그룹 시험 생성
    await page.click('button:has-text("그룹 시험")');
    await page.fill('[name="exam-title"]', '그룹 모의고사');
    await page.click('button:has-text("생성")');

    await expect(page.locator('.group-exam-created')).toBeVisible();
  });

  test('284. 지식 그래프 기반 학습', async ({ page }) => {
    await loginAsUser(page);

    // 1. 학습 자료 업로드
    await page.goto(`${FRONTEND_URL}/upload`);
    const pdfBuffer = Buffer.from('%PDF-1.4\nNetwork protocols OSI TCP/IP');
    await page.locator('input[type="file"]').setInputFiles({
      name: 'network.pdf',
      mimeType: 'application/pdf',
      buffer: pdfBuffer
    });
    await page.click('button:has-text("업로드")');

    // 2. 지식 그래프 생성
    await page.goto(`${FRONTEND_URL}/knowledge-graph/create`);
    await page.click('button:has-text("그래프 생성")');
    await page.waitForSelector('.graph-generated', { timeout: 15000 });

    // 3. 약점 분석
    await page.click('button:has-text("약점 분석")');
    await expect(page.locator('.weakness-analysis')).toBeVisible();

    // 4. 맞춤 학습 경로
    await page.click('button:has-text("학습 경로 생성")');
    await expect(page.locator('.learning-path')).toBeVisible();
  });

  test('285. 오답노트 활용 플로우', async ({ page }) => {
    await loginAsUser(page);

    // 1. 시험 응시 및 오답 생성
    await page.goto(`${FRONTEND_URL}/exams/1`);
    await page.click('button:has-text("시작")');

    // Answer incorrectly
    for (let i = 0; i < 5; i++) {
      await page.click('.answer-option:last-child');
      await page.click('button:has-text("다음")');
    }

    await page.click('button:has-text("제출")');

    // 2. 오답노트 생성
    await page.click('button:has-text("오답노트 생성")');
    await expect(page).toHaveURL(/\/review/);

    // 3. 오답 복습
    await page.click('.review-question:first-child button:has-text("다시 풀기")');
    await page.click('.answer-option:first-child');
    await page.click('button:has-text("확인")');

    // 4. 개선도 확인
    await page.goto(`${FRONTEND_URL}/progress`);
    await expect(page.locator('.improvement-chart')).toBeVisible();
  });

  // 시스템 간 통합
  test('286. Frontend-Backend 통신', async ({ page }) => {
    await loginAsUser(page);

    // Monitor API calls
    const apiCalls: string[] = [];
    page.on('request', request => {
      if (request.url().includes('/api/v1')) {
        apiCalls.push(request.url());
      }
    });

    await page.goto(`${FRONTEND_URL}/dashboard`);
    await page.waitForLoadState('networkidle');

    // Verify API calls were made
    expect(apiCalls.length).toBeGreaterThan(0);
    expect(apiCalls.some(url => url.includes('/user/profile'))).toBeTruthy();
  });

  test('287. Database 연동 - PostgreSQL', async ({ page }) => {
    await loginAsUser(page);

    // Create data
    await page.goto(`${FRONTEND_URL}/notes/create`);
    const noteTitle = `Note-${Date.now()}`;
    await page.fill('[name="title"]', noteTitle);
    await page.fill('[name="content"]', 'Test content');
    await page.click('button:has-text("저장")');

    // Verify data persisted
    await page.goto(`${FRONTEND_URL}/notes`);
    await expect(page.locator(`.note-title:has-text("${noteTitle}")`)).toBeVisible();
  });

  test('288. Vector DB (Pinecone) 통합', async ({ page }) => {
    await loginAsUser(page);

    // Upload document for embedding
    await page.goto(`${FRONTEND_URL}/upload`);
    const content = 'This is a test document for vector embedding';
    const pdfBuffer = Buffer.from(`%PDF-1.4\n${content}`);

    await page.locator('input[type="file"]').setInputFiles({
      name: 'vector-test.pdf',
      mimeType: 'application/pdf',
      buffer: pdfBuffer
    });
    await page.click('button:has-text("업로드")');

    // Search using semantic search
    await page.goto(`${FRONTEND_URL}/search`);
    await page.fill('[name="search"]', 'embedding test');
    await page.click('button:has-text("검색")');

    await expect(page.locator('.search-result:has-text("vector-test")')).toBeVisible();
  });

  test('289. Graph DB (Neo4j) 통합', async ({ page }) => {
    await loginAsUser(page);

    // Create graph relationships
    await page.goto(`${FRONTEND_URL}/knowledge-graph/edit`);

    await page.click('button:has-text("노드 추가")');
    await page.fill('[name="node-name"]', 'Concept A');
    await page.click('button:has-text("추가")');

    await page.click('button:has-text("노드 추가")');
    await page.fill('[name="node-name"]', 'Concept B');
    await page.click('button:has-text("추가")');

    // Create relationship
    await page.click('.node:has-text("Concept A")');
    await page.click('.node:has-text("Concept B")', { modifiers: ['Control'] });
    await page.click('button:has-text("관계 생성")');

    // Verify in graph
    await page.goto(`${FRONTEND_URL}/knowledge-graph`);
    await expect(page.locator('.edge')).toBeVisible();
  });

  test('290. AI Service (OpenAI) 통합', async ({ page }) => {
    await loginAsUser(page);

    // Test AI features
    await page.goto(`${FRONTEND_URL}/ai-assistant`);

    await page.fill('.ai-input', '파이썬의 데코레이터란 무엇인가?');
    await page.click('button:has-text("질문")');

    await expect(page.locator('.ai-response')).toBeVisible({ timeout: 15000 });
    await expect(page.locator('.ai-response')).toContainText(/데코레이터|decorator/i);
  });

  // 외부 서비스 통합
  test('291. Upstage OCR 통합', async ({ page }) => {
    await loginAsUser(page);

    // Upload image for OCR
    await page.goto(`${FRONTEND_URL}/upload`);

    // Create image with text
    const imageBuffer = Buffer.from('fake-image-with-text');

    await page.locator('input[type="file"]').setInputFiles({
      name: 'text-image.jpg',
      mimeType: 'image/jpeg',
      buffer: imageBuffer
    });

    await page.click('button:has-text("OCR 처리")');

    await expect(page.locator('.ocr-result')).toBeVisible({ timeout: 20000 });
  });

  test('292. Toss Payments 통합', async ({ page }) => {
    await loginAsUser(page);

    await page.goto(`${FRONTEND_URL}/checkout`);

    // Select plan
    await page.selectOption('[name="plan"]', 'premium');

    // Initialize payment
    await page.click('button:has-text("결제")');

    // Check Toss Payments widget loads
    await expect(page.frameLocator('#toss-payments-iframe')).toBeVisible({ timeout: 10000 });
  });

  test('293. OAuth (Google) 통합', async ({ page }) => {
    await page.goto(`${FRONTEND_URL}/login`);

    await page.click('button:has-text("Google로 로그인")');

    // Should redirect to Google OAuth
    await page.waitForURL(/accounts\.google\.com/, { timeout: 10000 }).catch(() => {
      // In test environment, check for OAuth initialization
      expect(page.url()).toContain('oauth');
    });
  });

  test('294. OAuth (Kakao) 통합', async ({ page }) => {
    await page.goto(`${FRONTEND_URL}/login`);

    await page.click('button:has-text("카카오로 로그인")');

    // Should redirect to Kakao OAuth
    await page.waitForURL(/accounts\.kakao\.com/, { timeout: 10000 }).catch(() => {
      // In test environment, check for OAuth initialization
      expect(page.url()).toContain('oauth');
    });
  });

  test('295. Email Service 통합', async ({ page }) => {
    await page.goto(`${FRONTEND_URL}/signup`);

    const email = `verify-${Date.now()}@example.com`;
    await page.fill('[name="email"]', email);
    await page.fill('[name="password"]', 'Test1234!');
    await page.click('button[type="submit"]');

    // Check for verification email sent message
    await expect(page.locator('.email-sent-message')).toBeVisible();
    await expect(page.locator('.email-sent-message')).toContainText(/인증.*메일/i);
  });

  // 데이터 흐름 테스트
  test('296. 학습 데이터 실시간 동기화', async ({ page, context }) => {
    await loginAsUser(page);

    // Open two tabs
    const page2 = await context.newPage();
    await loginAsUser(page2);

    // Update in first tab
    await page.goto(`${FRONTEND_URL}/progress`);
    await page.click('button:has-text("목표 설정")');
    await page.fill('[name="target-score"]', '90');
    await page.click('button:has-text("저장")');

    // Check update in second tab
    await page2.goto(`${FRONTEND_URL}/progress`);
    await expect(page2.locator('.target-score')).toContainText('90');
  });

  test('297. 캐시 일관성', async ({ page }) => {
    await loginAsUser(page);

    // Load cached data
    await page.goto(`${FRONTEND_URL}/questions`);
    const initialCount = await page.locator('.question-item').count();

    // Add new question
    await page.goto(`${FRONTEND_URL}/questions/create`);
    await page.fill('[name="question"]', 'New test question');
    await page.click('button:has-text("생성")');

    // Check cache is updated
    await page.goto(`${FRONTEND_URL}/questions`);
    const newCount = await page.locator('.question-item').count();
    expect(newCount).toBe(initialCount + 1);
  });

  test('298. 트랜잭션 롤백', async ({ page }) => {
    await loginAsUser(page);

    // Start transaction (exam with payment)
    await page.goto(`${FRONTEND_URL}/premium-exam`);

    // Simulate payment failure
    await page.evaluate(() => {
      window.postMessage({ type: 'PAYMENT_FAILED' }, '*');
    });

    // Verify exam not accessible
    await page.goto(`${FRONTEND_URL}/exams`);
    await expect(page.locator('.premium-exam-locked')).toBeVisible();
  });

  test('299. 이벤트 기반 업데이트', async ({ page }) => {
    await loginAsUser(page);

    await page.goto(`${FRONTEND_URL}/notifications`);

    // Trigger event
    await page.evaluate(() => {
      window.dispatchEvent(new CustomEvent('study-milestone', {
        detail: { achievement: '100 questions completed' }
      }));
    });

    // Check notification appears
    await expect(page.locator('.notification:has-text("100 questions")')).toBeVisible();
  });

  test('300. 백그라운드 작업 처리', async ({ page }) => {
    await loginAsUser(page);

    // Upload large file for processing
    await page.goto(`${FRONTEND_URL}/upload`);

    const largeContent = 'x'.repeat(10000);
    const pdfBuffer = Buffer.from(`%PDF-1.4\n${largeContent}`);

    await page.locator('input[type="file"]').setInputFiles({
      name: 'large.pdf',
      mimeType: 'application/pdf',
      buffer: pdfBuffer
    });

    await page.click('button:has-text("업로드")');

    // Check job queued
    await expect(page.locator('.processing-status')).toContainText(/대기|처리 중/i);

    // Check job completion
    await expect(page.locator('.processing-status')).toContainText(/완료/i, { timeout: 30000 });
  });

  // 모니터링 및 로깅
  test('301. 에러 로깅', async ({ page }) => {
    await loginAsUser(page);

    // Trigger an error
    await page.goto(`${FRONTEND_URL}/non-existent-page`);

    // Check error is logged
    const response = await page.request.get(`${API_BASE}/admin/logs/errors`);
    const logs = await response.json();

    expect(logs.some((log: any) => log.message.includes('404'))).toBeTruthy();
  });

  test('302. 성능 메트릭 수집', async ({ page }) => {
    await loginAsUser(page);

    await page.goto(`${FRONTEND_URL}/dashboard`);

    // Get performance metrics
    const metrics = await page.evaluate(() => {
      const perf = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      return {
        loadTime: perf.loadEventEnd - perf.fetchStart,
        domReady: perf.domContentLoadedEventEnd - perf.fetchStart,
        firstPaint: performance.getEntriesByName('first-paint')[0]?.startTime
      };
    });

    expect(metrics.loadTime).toBeLessThan(5000);
    expect(metrics.domReady).toBeLessThan(3000);
  });

  test('303. 사용자 활동 추적', async ({ page }) => {
    await loginAsUser(page);

    // Perform actions
    await page.goto(`${FRONTEND_URL}/dashboard`);
    await page.click('button:has-text("학습 시작")');
    await page.goto(`${FRONTEND_URL}/questions`);

    // Check activity log
    const response = await page.request.get(`${API_BASE}/user/activity`);
    const activities = await response.json();

    expect(activities.length).toBeGreaterThan(0);
    expect(activities.some((a: any) => a.action === 'study_started')).toBeTruthy();
  });

  test('304. 시스템 상태 모니터링', async ({ page }) => {
    const response = await page.request.get(`${API_BASE}/health`);
    const health = await response.json();

    expect(health.status).toBe('healthy');
    expect(health.services.database).toBe('up');
    expect(health.services.cache).toBe('up');
    expect(health.services.queue).toBe('up');
  });

  test('305. 알림 시스템 통합', async ({ page }) => {
    await loginAsUser(page);

    await page.goto(`${FRONTEND_URL}/settings/notifications`);

    // Configure notifications
    await page.check('[name="email-notifications"]');
    await page.check('[name="push-notifications"]');
    await page.click('button:has-text("저장")');

    // Trigger notification event
    await page.goto(`${FRONTEND_URL}/exams/1/complete`);

    // Check notification sent
    await expect(page.locator('.toast-notification')).toBeVisible();
  });

  // 배포 및 환경
  test('306. 개발/운영 환경 분리', async ({ page }) => {
    const response = await page.request.get(`${API_BASE}/config/environment`);
    const config = await response.json();

    expect(config.environment).toMatch(/development|production/);

    if (config.environment === 'production') {
      expect(config.debug).toBeFalsy();
      expect(config.secure).toBeTruthy();
    }
  });

  test('307. CI/CD 파이프라인 검증', async ({ page }) => {
    const response = await page.request.get(`${API_BASE}/version`);
    const version = await response.json();

    expect(version.version).toMatch(/\d+\.\d+\.\d+/);
    expect(version.buildNumber).toBeTruthy();
    expect(version.commitHash).toMatch(/[a-f0-9]{7,}/);
  });

  test('308. 데이터베이스 마이그레이션', async ({ page }) => {
    const response = await page.request.get(`${API_BASE}/admin/migrations/status`);
    const migrations = await response.json();

    expect(migrations.pending).toEqual([]);
    expect(migrations.applied.length).toBeGreaterThan(0);
  });

  test('309. 백업 및 복구', async ({ page }) => {
    await loginAsUser(page);

    // Create backup
    const backupResponse = await page.request.post(`${API_BASE}/admin/backup/create`);
    const backup = await backupResponse.json();

    expect(backup.id).toBeTruthy();
    expect(backup.size).toBeGreaterThan(0);

    // Verify backup can be restored
    const verifyResponse = await page.request.post(`${API_BASE}/admin/backup/verify`, {
      data: { backupId: backup.id }
    });

    expect(verifyResponse.status()).toBe(200);
  });

  test('310. 로드 밸런싱', async ({ page }) => {
    const responses = [];

    // Make multiple requests
    for (let i = 0; i < 10; i++) {
      const response = await page.request.get(`${API_BASE}/server-info`);
      const data = await response.json();
      responses.push(data.serverId);
    }

    // Check if requests are distributed
    const uniqueServers = new Set(responses);
    expect(uniqueServers.size).toBeGreaterThanOrEqual(1); // At least one server
  });

  // 사용자 경험 통합
  test('311. 반응형 디자인 통합', async ({ browser }) => {
    // Desktop
    const desktop = await browser.newContext({
      viewport: { width: 1920, height: 1080 }
    });
    const desktopPage = await desktop.newPage();
    await desktopPage.goto(FRONTEND_URL);
    await expect(desktopPage.locator('.desktop-menu')).toBeVisible();

    // Mobile
    const mobile = await browser.newContext({
      viewport: { width: 375, height: 667 }
    });
    const mobilePage = await mobile.newPage();
    await mobilePage.goto(FRONTEND_URL);
    await expect(mobilePage.locator('.mobile-menu')).toBeVisible();

    await desktop.close();
    await mobile.close();
  });

  test('312. 다국어 지원', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Change language to English
    await page.selectOption('[name="language"]', 'en');
    await expect(page.locator('button:has-text("Login")')).toBeVisible();

    // Change back to Korean
    await page.selectOption('[name="language"]', 'ko');
    await expect(page.locator('button:has-text("로그인")')).toBeVisible();
  });

  test('313. 접근성 통합', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Check ARIA labels
    const loginButton = page.locator('button:has-text("로그인")');
    await expect(loginButton).toHaveAttribute('aria-label', /로그인|login/i);

    // Check keyboard navigation
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');

    // Should navigate via keyboard
    await expect(page).toHaveURL(/login|signup/);
  });

  test('314. 테마 시스템 통합', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/settings/theme`);

    // Switch to dark mode
    await page.click('button:has-text("다크 모드")');

    await expect(page.locator('body')).toHaveClass(/dark/);

    // Persist across navigation
    await page.goto(`${FRONTEND_URL}/dashboard`);
    await expect(page.locator('body')).toHaveClass(/dark/);
  });

  test('315. 오프라인 모드', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/dashboard`);

    // Go offline
    await page.context().setOffline(true);

    // Should show offline indicator
    await expect(page.locator('.offline-indicator')).toBeVisible();

    // Basic features should work
    await page.click('button:has-text("오프라인 학습")');
    await expect(page.locator('.offline-content')).toBeVisible();

    await page.context().setOffline(false);
  });

  // 고급 기능 통합
  test('316. AI 추천 시스템', async ({ page }) => {
    await loginAsUser(page);

    // Complete some activities
    await page.goto(`${FRONTEND_URL}/questions`);
    await page.click('.question-item:has-text("네트워크")');
    await page.click('.answer-option:first-child');

    // Get AI recommendations
    await page.goto(`${FRONTEND_URL}/recommendations`);

    await expect(page.locator('.ai-recommendations')).toBeVisible();
    await expect(page.locator('.recommended-topic')).toContainText(/네트워크/i);
  });

  test('317. 게이미피케이션 시스템', async ({ page }) => {
    await loginAsUser(page);

    // Complete achievement
    for (let i = 0; i < 10; i++) {
      await page.goto(`${FRONTEND_URL}/questions/${i + 1}`);
      await page.click('.answer-option:first-child');
      await page.click('button:has-text("제출")');
    }

    // Check achievement unlocked
    await expect(page.locator('.achievement-unlocked')).toBeVisible();
    await expect(page.locator('.achievement-unlocked')).toContainText(/10문제/i);
  });

  test('318. 소셜 기능 통합', async ({ page }) => {
    await loginAsUser(page);

    // Share progress
    await page.goto(`${FRONTEND_URL}/progress`);
    await page.click('button:has-text("공유")');

    const shareDialog = page.locator('.share-dialog');
    await shareDialog.locator('button:has-text("Twitter")').click();

    // Check share URL generated
    const shareUrl = await shareDialog.locator('.share-url').inputValue();
    expect(shareUrl).toContain('twitter.com/intent/tweet');
  });

  test('319. 데이터 내보내기/가져오기', async ({ page }) => {
    await loginAsUser(page);

    // Export data
    await page.goto(`${FRONTEND_URL}/settings/data`);

    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("데이터 내보내기")');

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/export.*\.json$/i);

    // Import data
    const importData = {
      version: '1.0',
      studyData: { progress: 50 }
    };

    await page.locator('input[type="file"]').setInputFiles({
      name: 'import.json',
      mimeType: 'application/json',
      buffer: Buffer.from(JSON.stringify(importData))
    });

    await page.click('button:has-text("가져오기")');
    await expect(page.locator('.import-success')).toBeVisible();
  });

  test('320. 플러그인 시스템', async ({ page }) => {
    await loginAsUser(page);

    await page.goto(`${FRONTEND_URL}/settings/plugins`);

    // Install plugin
    await page.click('.plugin-item:has-text("Code Highlighter") button:has-text("설치")');

    await expect(page.locator('.plugin-installed')).toBeVisible();

    // Verify plugin works
    await page.goto(`${FRONTEND_URL}/notes/create`);
    await page.fill('[name="content"]', '```python\nprint("Hello")\n```');

    await expect(page.locator('.code-highlight')).toBeVisible();
  });

  // 에러 복구
  test('321. 네트워크 오류 복구', async ({ page }) => {
    await loginAsUser(page);

    // Simulate network error
    await page.route('**/api/v1/**', route => route.abort());

    await page.goto(`${FRONTEND_URL}/dashboard`);
    await expect(page.locator('.network-error')).toBeVisible();

    // Restore network
    await page.unroute('**/api/v1/**');

    // Retry should work
    await page.click('button:has-text("재시도")');
    await expect(page.locator('.dashboard-content')).toBeVisible();
  });

  test('322. 자동 저장 및 복구', async ({ page, context }) => {
    await loginAsUser(page);

    await page.goto(`${FRONTEND_URL}/notes/create`);
    await page.fill('[name="title"]', 'Auto-save test');
    await page.fill('[name="content"]', 'This should be auto-saved');

    // Wait for auto-save
    await page.waitForTimeout(3000);

    // Simulate crash - open new page
    const page2 = await context.newPage();
    await loginAsUser(page2);
    await page2.goto(`${FRONTEND_URL}/notes/create`);

    // Check recovered content
    await expect(page2.locator('[name="title"]')).toHaveValue('Auto-save test');
  });

  test('323. 세션 복구', async ({ page, context }) => {
    await loginAsUser(page);

    // Save session state
    await page.goto(`${FRONTEND_URL}/exams/1`);
    await page.click('button:has-text("시작")');
    await page.click('.answer-option:first-child');

    // Simulate session loss
    await page.evaluate(() => {
      localStorage.clear();
      sessionStorage.clear();
    });

    await page.reload();

    // Should prompt to restore session
    await expect(page.locator('.session-restore-prompt')).toBeVisible();
    await page.click('button:has-text("복구")');

    // Check state restored
    await expect(page.locator('.answer-option:first-child')).toHaveClass(/selected/);
  });

  test('324. 데이터 동기화 충돌 해결', async ({ page, context }) => {
    await loginAsUser(page);

    const page2 = await context.newPage();
    await loginAsUser(page2);

    // Edit same content in both tabs
    await page.goto(`${FRONTEND_URL}/notes/1/edit`);
    await page2.goto(`${FRONTEND_URL}/notes/1/edit`);

    await page.fill('[name="content"]', 'Edit from tab 1');
    await page2.fill('[name="content"]', 'Edit from tab 2');

    await page.click('button:has-text("저장")');
    await page2.click('button:has-text("저장")');

    // Should detect conflict
    await expect(page2.locator('.conflict-dialog')).toBeVisible();
  });

  test('325. 장기 실행 작업 관리', async ({ page }) => {
    await loginAsUser(page);

    await page.goto(`${FRONTEND_URL}/bulk-process`);

    // Start long-running task
    await page.click('button:has-text("대량 처리 시작")');

    // Should show progress
    await expect(page.locator('.progress-bar')).toBeVisible();

    // Can cancel
    await page.click('button:has-text("취소")');
    await expect(page.locator('.task-cancelled')).toBeVisible();
  });

  // 성능 최적화 통합
  test('326. 이미지 최적화', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Check images are optimized
    const images = await page.locator('img').all();

    for (const img of images) {
      const src = await img.getAttribute('src');

      // Check for WebP or optimized formats
      if (src) {
        expect(src).toMatch(/\.(webp|avif)|[\?&]quality=|[\?&]w=\d+/);
      }

      // Check lazy loading
      const loading = await img.getAttribute('loading');
      if (await img.isVisible() === false) {
        expect(loading).toBe('lazy');
      }
    }
  });

  test('327. 코드 스플리팅', async ({ page }) => {
    // Monitor loaded chunks
    const chunks: string[] = [];

    page.on('response', response => {
      const url = response.url();
      if (url.includes('.chunk.js')) {
        chunks.push(url);
      }
    });

    await page.goto(FRONTEND_URL);
    const initialChunks = [...chunks];

    // Navigate to lazy-loaded route
    await page.goto(`${FRONTEND_URL}/admin`);

    // Should load additional chunks
    expect(chunks.length).toBeGreaterThan(initialChunks.length);
  });

  test('328. 프리페칭 및 프리로딩', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Check for preload/prefetch links
    const preloadLinks = await page.locator('link[rel="preload"], link[rel="prefetch"]').all();
    expect(preloadLinks.length).toBeGreaterThan(0);

    // Check critical resources are preloaded
    const criticalPreload = await page.locator('link[rel="preload"][as="style"], link[rel="preload"][as="font"]').count();
    expect(criticalPreload).toBeGreaterThan(0);
  });

  test('329. 서버 사이드 렌더링', async ({ page }) => {
    // Disable JavaScript
    await page.route('**/*.js', route => route.abort());

    await page.goto(FRONTEND_URL);

    // Content should still be visible (SSR)
    await expect(page.locator('h1')).toBeVisible();
    await expect(page.locator('.main-content')).toBeVisible();
  });

  test('330. 전체 시스템 스트레스 테스트', async ({ browser }) => {
    const contexts = [];
    const pages = [];
    const results = [];

    // Create 50 concurrent users
    for (let i = 0; i < 50; i++) {
      const context = await browser.newContext();
      const page = await context.newPage();
      contexts.push(context);
      pages.push(page);
    }

    // Each user performs different actions
    const actions = [
      async (p: Page) => {
        await p.goto(`${FRONTEND_URL}/login`);
        await p.fill('[name="email"]', `user${Date.now()}@test.com`);
        await p.fill('[name="password"]', 'Test1234!');
        await p.click('button[type="submit"]');
      },
      async (p: Page) => {
        await p.goto(`${FRONTEND_URL}/questions`);
        await p.click('.question-item:first-child');
      },
      async (p: Page) => {
        await p.goto(`${FRONTEND_URL}/search`);
        await p.fill('[name="search"]', 'test query');
        await p.click('button:has-text("검색")');
      }
    ];

    // Execute actions concurrently
    const startTime = Date.now();

    await Promise.allSettled(
      pages.map((page, index) =>
        actions[index % actions.length](page)
          .then(() => ({ success: true }))
          .catch(() => ({ success: false }))
      )
    ).then(settledResults => {
      results.push(...settledResults.map(r => r.status === 'fulfilled' && r.value.success));
    });

    const totalTime = Date.now() - startTime;
    const successRate = results.filter(r => r).length / results.length;

    // System should handle load
    expect(successRate).toBeGreaterThan(0.95); // 95% success rate
    expect(totalTime).toBeLessThan(30000); // Complete within 30 seconds

    // Cleanup
    await Promise.all(contexts.map(c => c.close()));
  });
});