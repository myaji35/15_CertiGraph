import { test, expect } from '@playwright/test';

test('VIP user should see VIP subscription instead of payment button', async ({ page }) => {
  // Navigate to the new study set page
  await page.goto('http://localhost:3030/dashboard/study-sets/new');

  // Wait for page to load
  await page.waitForLoadState('networkidle');

  // Check if VIP subscription info is displayed
  const vipSubscriptionBox = page.locator('text=VIP 무료 이용권');
  await expect(vipSubscriptionBox).toBeVisible({ timeout: 10000 });

  // Check that payment button is NOT visible
  const paymentButton = page.locator('text=이용권 구매하러 가기');
  await expect(paymentButton).not.toBeVisible();

  console.log('✅ VIP subscription test passed!');
});
