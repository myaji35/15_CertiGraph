import { test } from '@playwright/test';

test('Debug calendar data - check what the frontend receives', async ({ page }) => {
  // Navigate to certifications page
  await page.goto('http://localhost:3030/certifications');

  // Wait for page to load
  await page.waitForTimeout(3000);

  // Navigate to January 2026 by clicking next button repeatedly
  const headerText = await page.locator('h2').first().textContent();
  console.log('Initial header:', headerText);

  if (!headerText?.includes('2026년 1월')) {
    const nextButton = page.locator('button').filter({ hasText: '›' }).or(page.locator('button[aria-label="다음 달"]'));

    for (let i = 0; i < 12; i++) {
      const currentHeader = await page.locator('h2').first().textContent();
      console.log(`Iteration ${i}: ${currentHeader}`);

      if (currentHeader?.includes('2026년 1월')) {
        console.log('Found January 2026!');
        break;
      }

      await nextButton.first().click();
      await page.waitForTimeout(500);
    }
  }

  // Log calendar data from the console
  const calendarData = await page.evaluate(() => {
    // Try to find calendar data in window or component state
    return (window as any).__calendar_data__ || null;
  });

  console.log('Calendar data from window:', JSON.stringify(calendarData, null, 2));

  // Check all day cells
  const dayCells = await page.locator('[class*="h-32"]').all();
  console.log(`Found ${dayCells.length} day cells`);

  for (let i = 0; i < Math.min(dayCells.length, 40); i++) {
    const cellText = await dayCells[i].textContent();
    if (cellText && cellText.includes('17')) {
      console.log(`Cell ${i} (day 17):`, cellText);
    }
    if (cellText && cellText.includes('사회복지사')) {
      console.log(`Cell ${i} contains Social Worker:`, cellText);
    }
  }

  // Take screenshot
  await page.screenshot({ path: 'test-results/debug-calendar-jan-2026.png', fullPage: true });

  console.log('Screenshot saved to test-results/debug-calendar-jan-2026.png');
});
