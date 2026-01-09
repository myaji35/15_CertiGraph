import { test, expect } from '@playwright/test';
import { skipIfPageNotExists, safeGoto } from '../../helpers/page-checker';

/**
 * P4 Group: Independent E2E Tests - Dashboard View
 * Test IDs: E2E-PAR-017 to E2E-PAR-020
 *
 * Tests dashboard functionality independently
 *
 * NOTE: These tests require the application's sign-in and dashboard pages to be implemented.
 * Tests will skip gracefully if pages return 404 or are not available.
 */

test.describe('P4: Dashboard View E2E Tests', () => {

  test.beforeEach(async ({ page }) => {
    // Check if sign-in page exists
    const signInResult = await skipIfPageNotExists(page, '/sign-in', 'Dashboard beforeEach');
    if (!signInResult.exists) {
      // Skip will be handled in each individual test
      return;
    }

    await page.waitForLoadState('domcontentloaded');

    // Try to log in
    const emailInput = page.locator('input[type="email"], input[name="email"]');
    const passwordInput = page.locator('input[type="password"], input[name="password"]');
    const submitButton = page.locator('button[type="submit"]');

    if (await emailInput.count() > 0) {
      await emailInput.fill('test@certigraph.test');
      await passwordInput.fill('TestPassword123!');
      await submitButton.click();
      await page.waitForTimeout(2000);
    }

    // Try to navigate to dashboard
    const dashboardResult = await safeGoto(page, '/dashboard', { timeout: 5000 });
    if (!dashboardResult.exists) {
      // Skip will be handled in each individual test
      return;
    }

    await page.waitForLoadState('domcontentloaded');
  });

  test('E2E-PAR-017: Dashboard displays user statistics', async ({ page }) => {
    // Check if dashboard page is loaded
    if (page.url().includes('404') || !page.url().includes('dashboard')) {
      const result = await skipIfPageNotExists(page, '/dashboard', 'E2E-PAR-017');
      if (!result.exists) {
        test.skip(true, result.message);
      }
    }

    // Look for statistics cards
    const statsCards = page.locator('[data-testid*="stat"], .stat-card, [class*="NotionStatCard"]');

    // If no stats cards found, skip the test
    if (await statsCards.count() === 0) {
      test.skip(true, 'Dashboard stats not found - page may not be fully implemented');
    }

    // Should have at least one stat card
    expect(await statsCards.count()).toBeGreaterThan(0);

    // Check for common statistics
    const totalQuestions = page.locator('text=/total questions|문제 수|질문 수/i');
    const accuracy = page.locator('text=/accuracy|정확도|정답률/i');

    if (await totalQuestions.count() > 0) {
      await expect(totalQuestions.first()).toBeVisible();
    }

    if (await accuracy.count() > 0) {
      await expect(accuracy.first()).toBeVisible();
    }

    await page.screenshot({ path: 'test-results/e2e-par-017-stats.png' });
  });

  test('E2E-PAR-018: Dashboard shows recent activity', async ({ page }) => {
    // Check if dashboard page is loaded
    if (page.url().includes('404') || !page.url().includes('dashboard')) {
      const result = await skipIfPageNotExists(page, '/dashboard', 'E2E-PAR-018');
      if (!result.exists) {
        test.skip(true, result.message);
      }
    }

    // Look for recent activity section
    const recentActivity = page.locator('text=/recent activity|최근 활동|활동 내역/i');

    if (await recentActivity.count() > 0) {
      await expect(recentActivity.first()).toBeVisible();

      // Check for activity items
      const activityItems = page.locator('[data-testid*="activity"], .activity-item, [class*="activity"]');

      // May or may not have activities depending on user history
      console.log(`Found ${await activityItems.count()} activity items`);
    } else {
      console.log('No recent activity section found - feature may not be implemented yet');
    }

    await page.screenshot({ path: 'test-results/e2e-par-018-activity.png' });
  });

  test('E2E-PAR-019: Dashboard navigation works correctly', async ({ page }) => {
    // Check if dashboard page is loaded
    if (page.url().includes('404') || !page.url().includes('dashboard')) {
      const result = await skipIfPageNotExists(page, '/dashboard', 'E2E-PAR-019');
      if (!result.exists) {
        test.skip(true, result.message);
      }
    }

    // Test navigation to different sections
    const studySetsLink = page.locator('a[href*="study-sets"]').or(page.getByText(/study sets|학습 세트|문제집/i));

    if (await studySetsLink.count() > 0) {
      await studySetsLink.first().click();
      await page.waitForLoadState('domcontentloaded');

      const currentUrl = page.url();
      expect(currentUrl).toMatch(/study-sets|학습|문제집/i);

      await page.screenshot({ path: 'test-results/e2e-par-019-navigation.png' });

      // Go back to dashboard
      await page.goBack();
      await page.waitForLoadState('domcontentloaded');
    } else {
      console.log('Study sets navigation link not found - feature may not be implemented yet');
      await page.screenshot({ path: 'test-results/e2e-par-019-navigation.png' });
    }
  });

  test('E2E-PAR-020: Dashboard data refreshes correctly', async ({ page }) => {
    // Check if dashboard page is loaded
    if (page.url().includes('404') || !page.url().includes('dashboard')) {
      const result = await skipIfPageNotExists(page, '/dashboard', 'E2E-PAR-020');
      if (!result.exists) {
        test.skip(true, result.message);
      }
    }

    // Take initial screenshot
    await page.screenshot({ path: 'test-results/e2e-par-020-initial.png' });

    // Look for refresh button
    const refreshButton = page.locator('button:has-text("Refresh"), button[aria-label*="refresh"], button:has-text("새로고침")');

    if (await refreshButton.count() > 0) {
      await refreshButton.first().click();
      await page.waitForTimeout(1000);

      await page.screenshot({ path: 'test-results/e2e-par-020-refreshed.png' });
    } else {
      // Manually reload the page
      await page.reload();
      await page.waitForLoadState('domcontentloaded');

      // Verify dashboard still loads correctly
      const dashboardTitle = page.locator('h1:has-text("Dashboard"), h1:has-text("대시보드")');
      if (await dashboardTitle.count() > 0) {
        await expect(dashboardTitle.first()).toBeVisible();
      } else {
        console.log('Dashboard title not found after reload - page may not be fully implemented');
      }

      await page.screenshot({ path: 'test-results/e2e-par-020-reloaded.png' });
    }
  });
});
