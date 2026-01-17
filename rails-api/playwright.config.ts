import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 120 * 1000,
  globalTimeout: 4 * 60 * 60 * 1000,
  
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 1,
  workers: process.env.CI ? 4 : 6,
  maxFailures: process.env.CI ? 20 : 10,
  
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['json', { outputFile: 'test-results/results.json' }],
    ['list'],
  ],
  
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    headless: false,
    slowMo: 100,
    navigationTimeout: 60 * 1000,
    actionTimeout: 15 * 1000,
    viewport: { width: 1280, height: 720 },
  },
  
  projects: [
    {
      name: 'auth-sequential',
      testMatch: '**/epic01-auth/**/*.spec.ts',
      fullyParallel: false,
      workers: 2,
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'isolated-parallel',
      testMatch: '**/epic{09,10}-*/*.spec.ts',
      fullyParallel: true,
      workers: 4,
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  
  webServer: {
    command: 'cd rails-api && bundle exec rails server -p 3000',
    url: 'http://localhost:3000',
    reuseExistingServer: true,
    timeout: 120 * 1000,
  },
});
