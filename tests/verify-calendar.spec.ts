import { test, expect } from '@playwright/test';

test('Verify Social Worker Level 1 exam appears on January 17, 2026', async ({ page }) => {
  // Capture console logs
  page.on('console', msg => {
    if (msg.text().includes('[Calendar Debug]')) {
      console.log('Browser console:', msg.text());
    }
  });

  // Navigate to certifications page
  await page.goto('http://localhost:3030/certifications');

  // Wait for page to load
  await page.waitForTimeout(3000);

  // Take screenshot before navigation
  await page.screenshot({ path: 'test-results/calendar-before.png', fullPage: true });

  // Check current month/year
  const headerText = await page.locator('h2').first().textContent();
  console.log('Current header:', headerText);

  // Navigate to January 2026 if not already there
  if (!headerText?.includes('2026년 1월')) {
    const nextButton = page.locator('button').nth(1);

    for (let i = 0; i < 12; i++) {
      const currentHeader = await page.locator('h2').first().textContent();

      if (currentHeader?.includes('2026년 1월')) {
        console.log('Found January 2026');
        break;
      }

      await nextButton.click();
      await page.waitForTimeout(500);
    }
  }

  // Take screenshot of January 2026
  await page.screenshot({ path: 'test-results/calendar-jan-2026.png', fullPage: true });

  // Check for "사회복지사" text on the page
  const pageContent = await page.textContent('body');
  const hasSocialWorker = pageContent?.includes('사회복지사');

  console.log('Page contains "사회복지사":', hasSocialWorker);

  // Try to find the exam on day 17
  const calendarCells = await page.locator('.grid.grid-cols-7 > div').all();

  for (let i = 0; i < calendarCells.length; i++) {
    const cellText = await calendarCells[i].textContent();
    if (cellText?.includes('17') && cellText?.includes('사회복지사')) {
      console.log('✅ SUCCESS: Found Social Worker exam on day 17!');
      console.log('Cell content:', cellText);

      // Highlight and screenshot the cell
      await calendarCells[i].highlight();
      await page.screenshot({ path: 'test-results/calendar-day-17-highlighted.png', fullPage: true });

      expect(hasSocialWorker).toBe(true);
      return;
    }
  }

  // If not found, log all cells with day numbers
  console.log('❌ FAIL: Social Worker exam NOT found on day 17');
  console.log('Checking all calendar cells...');

  for (let i = 0; i < Math.min(calendarCells.length, 35); i++) {
    const cellText = await calendarCells[i].textContent();
    if (cellText && cellText.trim().length > 0 && cellText.trim().length < 50) {
      console.log(`Cell ${i}:`, cellText.substring(0, 100));
    }
  }

  expect(hasSocialWorker).toBe(true);
});
