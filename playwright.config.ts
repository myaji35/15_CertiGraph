import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  testMatch: '**/*.spec.ts',

  // 각 테스트의 최대 실행 시간
  timeout: 120 * 1000, // 2분으로 증가 (OCR 처리 등 긴 작업 대비)

  // 전역 타임아웃
  globalTimeout: 3 * 60 * 60 * 1000, // 3시간

  // 실패 시 빠른 종료
  maxFailures: process.env.CI ? 10 : 5,

  // 테스트 실행 설정
  fullyParallel: false, // 프로젝트별로 제어
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,

  // Worker 설정 (프로젝트별로 오버라이드 가능)
  workers: process.env.CI ? 4 : 8,

  // Reporter - 여러 리포터 사용
  reporter: [
    ['html', { outputFolder: 'test-results/html-report' }],
    ['json', { outputFile: 'test-results/results.json' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
    ['list'],
  ],

  use: {
    // 기본 URL
    baseURL: process.env.BASE_URL || 'http://localhost:3000',

    // 스크린샷과 비디오
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',

    // 헤드리스 모드 (CI에서는 true, 로컬에서는 false)
    headless: process.env.CI ? true : false,

    // 액션 속도 (CI에서는 빠르게)
    slowMo: process.env.CI ? 0 : 300,

    // 네비게이션 타임아웃 (60초로 증가)
    navigationTimeout: 60 * 1000,
    actionTimeout: 15 * 1000,
  },

  // 프로젝트별 그룹화 (병렬 실행 최적화)
  projects: [
    // ========== 병렬 실행 가능 그룹 ==========

    // Group 1: 인증 테스트 (격리된 사용자)
    {
      name: 'auth-parallel',
      testMatch: '**/e2e/parallel/auth*.spec.ts',
      fullyParallel: true,
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },

    // Group 2: 읽기 전용 테스트 (완전 병렬)
    {
      name: 'read-only-parallel',
      testMatch: '**/e2e/parallel/readonly*.spec.ts',
      fullyParallel: true,
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },

    // Group 3: 독립적인 E2E 테스트
    {
      name: 'independent-e2e',
      testMatch: [
        '**/e2e/bmad-knowledge-graph.spec.ts',
        '**/e2e/bmad-performance.spec.ts',
        '**/e2e/bmad-security.spec.ts',
      ],
      fullyParallel: true,
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },

    // ========== 순차 실행 그룹 ==========

    // Group 4: 결제 플로우 (순차)
    {
      name: 'payment-sequential',
      testMatch: '**/e2e/payment/*.spec.ts',
      fullyParallel: false,
      workers: 1,
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },

    // Group 5: 통합 테스트 (순차)
    {
      name: 'integration-sequential',
      testMatch: [
        '**/e2e/bmad-integration.spec.ts',
        '**/e2e/bmad-full-test.spec.ts',
      ],
      fullyParallel: false,
      workers: 1,
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },

    // Group 6: 학습 자료 및 시험 (부분 병렬)
    {
      name: 'study-exam-partial',
      testMatch: [
        '**/e2e/bmad-study-materials.spec.ts',
        '**/e2e/bmad-mock-exam.spec.ts',
      ],
      fullyParallel: false,
      workers: 2,
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },

    // Group 7: 인증 포괄 테스트
    {
      name: 'auth-comprehensive',
      testMatch: [
        '**/e2e/bmad-auth-comprehensive.spec.ts',
        '**/e2e/bmad-auth-social-password.spec.ts',
      ],
      fullyParallel: false,
      workers: 2,
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },

    // Group 8: Rails Best Practices 테스트
    {
      name: 'rails-best-practices',
      testMatch: [
        '**/e2e/rails-e2e-comprehensive.spec.ts',
        '**/e2e/rails-realistic-scenarios.spec.ts',
      ],
      fullyParallel: false,
      workers: 2,
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },
  ],

  // 개발 서버 설정 - Rails 서버 사용
  webServer: process.env.SKIP_SERVER ? undefined : {
    command: 'cd rails-api && bundle exec rails server -p 3000',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
