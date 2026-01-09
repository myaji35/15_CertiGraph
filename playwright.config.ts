import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './',
  testMatch: '**/*.spec.ts',

  // 각 테스트의 최대 실행 시간
  timeout: 60 * 1000,

  // 테스트 실행 설정
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,

  // Reporter
  reporter: 'html',

  use: {
    // 기본 URL
    baseURL: 'http://localhost:3030',

    // 스크린샷과 비디오
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',

    // 브라우저를 보이게 설정 (headed 모드)
    headless: false,

    // 액션을 천천히 실행 (밀리초)
    slowMo: 500,
  },

  // 브라우저 설정
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1280, height: 720 },
      },
    },
  ],

  // 개발 서버 설정 (옵션)
  // webServer: {
  //   command: 'cd frontend && npm run dev',
  //   url: 'http://localhost:3030',
  //   reuseExistingServer: !process.env.CI,
  // },
});
