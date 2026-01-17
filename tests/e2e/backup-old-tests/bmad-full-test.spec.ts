import { test, expect, Page } from '@playwright/test';

// Helper functions
async function loginAsUser(page: Page, email: string, password: string) {
  await page.goto('http://localhost:3000/signin');
  await page.fill('input[name="email"]', email);
  await page.fill('input[name="password"]', password);
  await page.click('button[type="submit"]');
  await page.waitForURL('**/dashboard/**', { timeout: 10000 });
}

async function loginAsAdmin(page: Page) {
  await loginAsUser(page, 'admin@certigraph.com', 'Admin123!@#');
}

// Test configuration
test.describe.configure({ mode: 'serial' });

// 1. Authentication Tests
test.describe('1. 인증 및 권한 테스트', () => {
  test('1.1 회원가입 프로세스', async ({ page }) => {
    await page.goto('http://localhost:3000/signup');

    // Test invalid email
    await page.fill('input[name="email"]', 'invalid-email');
    await page.fill('input[name="password"]', 'Password123!');
    await page.fill('input[name="confirmPassword"]', 'Password123!');
    await page.click('button[type="submit"]');
    await expect(page.locator('text=/유효한 이메일을 입력해주세요|Please enter a valid email/')).toBeVisible();

    // Test password mismatch
    await page.fill('input[name="email"]', 'newuser@test.com');
    await page.fill('input[name="password"]', 'Password123!');
    await page.fill('input[name="confirmPassword"]', 'DifferentPass123!');
    await page.click('button[type="submit"]');
    await expect(page.locator('text=/비밀번호가 일치하지 않습니다|Passwords do not match/')).toBeVisible();

    // Successful signup
    await page.fill('input[name="email"]', `test-${Date.now()}@test.com`);
    await page.fill('input[name="password"]', 'Password123!');
    await page.fill('input[name="confirmPassword"]', 'Password123!');
    await page.click('button[type="submit"]');

    // Should redirect to dashboard after signup
    await expect(page).toHaveURL(/.*dashboard.*/);
  });

  test('1.2 로그인/로그아웃', async ({ page }) => {
    // Test invalid login
    await page.goto('http://localhost:3000/signin');
    await page.fill('input[name="email"]', 'invalid@test.com');
    await page.fill('input[name="password"]', 'WrongPassword');
    await page.click('button[type="submit"]');
    await expect(page.locator('text=/잘못된 이메일 또는 비밀번호|Invalid email or password/')).toBeVisible();

    // Test valid login
    await loginAsUser(page, 'test@example.com', 'password123');
    await expect(page).toHaveURL(/.*dashboard.*/);

    // Test logout
    await page.click('button:has-text("로그아웃")');
    await expect(page).toHaveURL(/.*login.*/);

    // Test protected route access after logout
    await page.goto('http://localhost:3000/dashboard');
    await expect(page).toHaveURL(/.*login.*/);
  });

  test('1.3 소셜 로그인', async ({ page }) => {
    await page.goto('http://localhost:3000/signin');

    // Check Google login button exists
    const googleButton = page.locator('button:has-text("Google로 로그인")');
    await expect(googleButton).toBeVisible();

    // Note: Actual OAuth flow testing requires additional setup
    // This test verifies the button is present and clickable
    await expect(googleButton).toBeEnabled();
  });
});

// 2. Study Materials Tests
test.describe('2. 학습 자료 관리 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'password123');
  });

  test('2.1 PDF 업로드 및 처리', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/materials');

    // Click upload button
    await page.click('button:has-text("PDF 업로드")');

    // Upload test file
    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles('./dummy_test.pdf');

    // Check upload progress
    await expect(page.locator('text=/업로드 중|Uploading/')).toBeVisible();

    // Wait for processing
    await expect(page.locator('text=/처리 중|Processing/')).toBeVisible({ timeout: 30000 });

    // Check for completion or retry button
    const retryButton = page.locator('button:has-text("재시도")');
    const successMessage = page.locator('text=/처리 완료|Processing complete/');

    await expect(successMessage.or(retryButton)).toBeVisible({ timeout: 60000 });
  });

  test('2.2 학습 자료 목록 조회', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/materials');

    // Check materials list is visible
    await expect(page.locator('[data-testid="materials-list"]')).toBeVisible();

    // Test search functionality
    await page.fill('input[placeholder*="검색"]', '사회복지사');
    await page.waitForTimeout(500); // Debounce delay

    // Test pagination if available
    const nextButton = page.locator('button:has-text("다음")');
    if (await nextButton.isVisible()) {
      await nextButton.click();
      await page.waitForTimeout(500);
    }
  });

  test('2.3 학습 자료 삭제', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/materials');

    // Find first delete button
    const deleteButton = page.locator('button[aria-label="삭제"]').first();
    if (await deleteButton.isVisible()) {
      await deleteButton.click();

      // Confirm deletion
      await page.click('button:has-text("확인")');

      // Check for success message
      await expect(page.locator('text=/삭제되었습니다|Deleted successfully/')).toBeVisible();
    }
  });
});

// 3. Mock Exam Tests
test.describe('3. 모의시험 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'password123');
  });

  test('3.1 시험 시작', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/test');

    // Select exam set
    await page.click('[data-testid="exam-set-card"]');

    // Configure exam settings
    await page.fill('input[name="timeLimit"]', '60');
    await page.fill('input[name="questionCount"]', '10');

    // Start exam
    await page.click('button:has-text("시험 시작")');

    // Verify exam started
    await expect(page.locator('[data-testid="exam-timer"]')).toBeVisible();
  });

  test('3.2 시험 진행', async ({ page }) => {
    // Navigate to ongoing exam
    await page.goto('http://localhost:3000/dashboard/test/mock');

    // Answer first question
    await page.click('label:has-text("1번")');

    // Navigate to next question
    await page.click('button:has-text("다음")');

    // Test bookmark functionality
    await page.click('button[aria-label="북마크"]');

    // Check auto-save indicator
    await expect(page.locator('text=/자동 저장됨|Auto-saved/')).toBeVisible({ timeout: 5000 });
  });

  test('3.3 시험 결과', async ({ page }) => {
    // Complete exam first
    await page.goto('http://localhost:3000/dashboard/test/mock');

    // Answer all questions quickly
    for (let i = 0; i < 5; i++) {
      await page.click('label:has-text("1번")');
      await page.click('button:has-text("다음")');
    }

    // Submit exam
    await page.click('button:has-text("제출")');
    await page.click('button:has-text("확인")');

    // Check results page
    await expect(page.locator('[data-testid="exam-score"]')).toBeVisible();
    await expect(page.locator('[data-testid="exam-statistics"]')).toBeVisible();

    // Check wrong answers review
    await page.click('button:has-text("오답 노트")');
    await expect(page.locator('[data-testid="wrong-answers"]')).toBeVisible();
  });
});

// 4. Knowledge Graph Tests
test.describe('4. 지식 그래프 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'password123');
  });

  test('4.1 3D 시각화', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/knowledge-graph');

    // Wait for 3D canvas to load
    await expect(page.locator('canvas')).toBeVisible({ timeout: 10000 });

    // Test camera controls
    await page.mouse.move(400, 300);
    await page.mouse.down();
    await page.mouse.move(500, 400);
    await page.mouse.up();

    // Test node interaction
    await page.click('canvas', { position: { x: 400, y: 300 } });

    // Check for node details panel
    await expect(page.locator('[data-testid="node-details"]')).toBeVisible({ timeout: 5000 });
  });

  test('4.2 약점 분석', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/knowledge-graph');

    // Click analyze button
    await page.click('button:has-text("약점 분석")');

    // Wait for analysis results
    await expect(page.locator('[data-testid="weakness-analysis"]')).toBeVisible({ timeout: 15000 });

    // Check for recommended study path
    await expect(page.locator('[data-testid="study-path"]')).toBeVisible();

    // Test drill down
    await page.click('[data-testid="weak-concept"]');
    await expect(page.locator('[data-testid="concept-details"]')).toBeVisible();
  });
});

// 5. Payment Tests
test.describe('5. 결제 시스템 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'password123');
  });

  test('5.1 구독 플랜 선택', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/pricing');

    // Check plan comparison table
    await expect(page.locator('[data-testid="pricing-table"]')).toBeVisible();

    // Select premium plan
    await page.click('button:has-text("프리미엄 선택")');

    // Check payment method selection
    await expect(page.locator('[data-testid="payment-methods"]')).toBeVisible();
  });

  test('5.3 VIP Pass', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/settings');

    // Find VIP Pass section
    await page.click('button:has-text("VIP Pass 활성화")');

    // Enter test VIP code
    await page.fill('input[name="vipCode"]', 'TEST-VIP-2024');
    await page.click('button:has-text("활성화")');

    // Check for activation message
    const successMessage = page.locator('text=/VIP Pass 활성화됨|VIP Pass activated/');
    const errorMessage = page.locator('text=/유효하지 않은 코드|Invalid code/');

    await expect(successMessage.or(errorMessage)).toBeVisible();
  });
});

// 6. Dashboard Tests
test.describe('6. 대시보드 및 통계 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'password123');
  });

  test('6.1 학습 진행 상황', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard');

    // Check progress indicators
    await expect(page.locator('[data-testid="overall-progress"]')).toBeVisible();
    await expect(page.locator('[data-testid="daily-stats"]')).toBeVisible();
    await expect(page.locator('[data-testid="performance-chart"]')).toBeVisible();

    // Test date range selector
    await page.click('button:has-text("이번 주")');
    await page.click('text="이번 달"');
    await page.waitForTimeout(1000);
  });

  test('6.2 캘린더 뷰', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard/calendar');

    // Check calendar is visible
    await expect(page.locator('[data-testid="calendar-view"]')).toBeVisible();

    // Navigate months
    await page.click('button[aria-label="다음 달"]');
    await page.waitForTimeout(500);
    await page.click('button[aria-label="이전 달"]');

    // Click on a date
    await page.click('[data-testid="calendar-day-15"]');

    // Check for day details
    await expect(page.locator('[data-testid="day-details"]')).toBeVisible();
  });
});

// 7. Admin Tests
test.describe('7. 관리자 기능 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('7.1 사용자 관리', async ({ page }) => {
    await page.goto('http://localhost:3000/admin/users');

    // Check user list
    await expect(page.locator('[data-testid="users-table"]')).toBeVisible();

    // Search for user
    await page.fill('input[placeholder*="사용자 검색"]', 'test@example.com');
    await page.waitForTimeout(500);

    // Test user status change
    const statusToggle = page.locator('[data-testid="user-status-toggle"]').first();
    if (await statusToggle.isVisible()) {
      await statusToggle.click();
      await expect(page.locator('text=/상태가 변경되었습니다|Status updated/')).toBeVisible();
    }
  });

  test('7.2 콘텐츠 관리', async ({ page }) => {
    await page.goto('http://localhost:3000/admin/content');

    // Check content list
    await expect(page.locator('[data-testid="content-table"]')).toBeVisible();

    // Test content approval
    const approveButton = page.locator('button:has-text("승인")').first();
    if (await approveButton.isVisible()) {
      await approveButton.click();
      await expect(page.locator('text=/승인되었습니다|Approved/')).toBeVisible();
    }

    // Check MLflow stats
    await page.click('tab:has-text("MLflow 통계")');
    await expect(page.locator('[data-testid="mlflow-stats"]')).toBeVisible();
  });
});

// 8. Performance Tests
test.describe('8. 성능 및 오류 처리 테스트', () => {
  test('8.1 로딩 상태', async ({ page }) => {
    // Simulate slow network
    await page.route('**/api/**', route => {
      setTimeout(() => route.continue(), 2000);
    });

    await page.goto('http://localhost:3000/dashboard');

    // Check loading indicators
    await expect(page.locator('[data-testid="loading-spinner"]')).toBeVisible();

    // Check skeleton UI
    await expect(page.locator('[data-testid="skeleton-loader"]')).toBeVisible();

    // Wait for content
    await expect(page.locator('[data-testid="dashboard-content"]')).toBeVisible({ timeout: 30000 });
  });

  test('8.2 오류 처리', async ({ page }) => {
    // Test 404 page
    await page.goto('http://localhost:3000/non-existent-page');
    await expect(page.locator('text=/페이지를 찾을 수 없습니다|Page not found/')).toBeVisible();

    // Test API error
    await page.route('**/api/dashboard', route =>
      route.fulfill({ status: 500, body: 'Internal Server Error' })
    );

    await page.goto('http://localhost:3000/dashboard');
    await expect(page.locator('text=/오류가 발생했습니다|An error occurred/')).toBeVisible();

    // Test retry button
    await page.click('button:has-text("다시 시도")');
  });
});

// 9. Responsive Design Tests
test.describe('9. 반응형 디자인 테스트', () => {
  test('9.1 모바일 뷰', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });

    await page.goto('http://localhost:3000/dashboard');

    // Check mobile navigation
    await page.click('[data-testid="mobile-menu-button"]');
    await expect(page.locator('[data-testid="mobile-menu"]')).toBeVisible();

    // Check responsive layout
    await expect(page.locator('[data-testid="dashboard-content"]')).toHaveCSS('flex-direction', 'column');
  });

  test('9.2 태블릿 뷰', async ({ page }) => {
    // Set tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });

    await page.goto('http://localhost:3000/dashboard');

    // Check sidebar toggle
    await page.click('[data-testid="sidebar-toggle"]');
    await expect(page.locator('[data-testid="sidebar"]')).not.toBeVisible();

    // Check grid layout
    const gridContainer = page.locator('[data-testid="grid-container"]');
    await expect(gridContainer).toHaveCSS('grid-template-columns', /repeat\(2,/);
  });
});

// 10. Accessibility Tests
test.describe('10. 접근성 테스트', () => {
  test('10.1 키보드 네비게이션', async ({ page }) => {
    await page.goto('http://localhost:3000/signin');

    // Test tab navigation
    await page.keyboard.press('Tab');
    await expect(page.locator('input[name="email"]')).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(page.locator('input[name="password"]')).toBeFocused();

    await page.keyboard.press('Tab');
    await expect(page.locator('button[type="submit"]')).toBeFocused();

    // Test skip to content
    await page.keyboard.press('Tab');
    const skipLink = page.locator('a:has-text("Skip to content")');
    if (await skipLink.isVisible()) {
      await skipLink.click();
      await expect(page.locator('main')).toBeFocused();
    }
  });

  test('10.2 스크린 리더', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard');

    // Check ARIA labels
    await expect(page.locator('[aria-label]')).toHaveCount(5, { timeout: 5000 });

    // Check heading structure
    const h1 = await page.locator('h1').count();
    const h2 = await page.locator('h2').count();
    expect(h1).toBeGreaterThan(0);
    expect(h2).toBeGreaterThan(0);

    // Check image alt texts
    const images = page.locator('img');
    const imageCount = await images.count();
    for (let i = 0; i < imageCount; i++) {
      const img = images.nth(i);
      const alt = await img.getAttribute('alt');
      expect(alt).toBeTruthy();
    }

    // Check form labels
    const inputs = page.locator('input:not([type="hidden"])');
    const inputCount = await inputs.count();
    for (let i = 0; i < inputCount; i++) {
      const input = inputs.nth(i);
      const id = await input.getAttribute('id');
      if (id) {
        const label = page.locator(`label[for="${id}"]`);
        await expect(label).toHaveCount(1);
      }
    }
  });
});

// Test Report Summary
test.afterAll(async () => {
  console.log('='.repeat(60));
  console.log('BMad E2E 테스트 완료');
  console.log('='.repeat(60));
  console.log('테스트 시나리오별 결과는 HTML 리포트를 확인하세요.');
  console.log('리포트 위치: ./playwright-report/index.html');
});