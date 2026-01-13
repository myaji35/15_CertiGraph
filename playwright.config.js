// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 4, // 병렬 실행을 위해 4개 워커 사용
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results.json' }],
    ['list']
  ],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    // P0 - 핵심 기능 테스트 그룹
    {
      name: 'P0-Auth',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /.*\.p0-auth\.spec\.js/,
    },
    {
      name: 'P0-Core',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /.*\.p0-core\.spec\.js/,
    },

    // P1 - 주요 기능 테스트 그룹
    {
      name: 'P1-Study',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /.*\.p1-study\.spec\.js/,
    },
    {
      name: 'P1-Exam',
      use: { ...devices['Desktop Chrome'] },
      testMatch: /.*\.p1-exam\.spec\.js/,
    },
  ],

  webServer: {
    command: 'cd rails-api && /Users/gangseungsig/.rbenv/shims/rails server',
    url: 'http://localhost:3000',
    reuseExistingServer: true,
    timeout: 120 * 1000,
  },
});