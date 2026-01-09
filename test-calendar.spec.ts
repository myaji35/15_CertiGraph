import { test, expect } from '@playwright/test';

test('Check if Social Worker Level 1 exam appears on calendar', async ({ page }) => {
  // Go to certifications page
  await page.goto('http://localhost:3030/certifications');

  // Wait for calendar to load
  await page.waitForTimeout(2000);

  // Take screenshot of initial state
  await page.screenshot({ path: 'calendar-initial.png', fullPage: true });

  // Check current year/month displayed
  const header = await page.locator('h2').first().textContent();
  console.log('Current calendar header:', header);

  // If not on January 2026, navigate to it
  if (!header?.includes('2026') || !header?.includes('1월')) {
    console.log('Navigating to January 2026...');

    // Click next month button multiple times if needed
    const nextButton = page.locator('button').filter({ has: page.locator('svg') }).nth(1);

    for (let i = 0; i < 12; i++) {
      const currentHeader = await page.locator('h2').first().textContent();
      console.log(`Iteration ${i}: ${currentHeader}`);

      if (currentHeader?.includes('2026') && currentHeader?.includes('1월')) {
        break;
      }

      await nextButton.click();
      await page.waitForTimeout(500);
    }
  }

  // Take screenshot after navigation
  await page.screenshot({ path: 'calendar-jan-2026.png', fullPage: true });

  // Check if January 17 has the Social Worker exam
  const calendar = await page.textContent('body');
  console.log('Does page contain "사회복지사"?', calendar?.includes('사회복지사'));

  // Look for day 17 cell and check its content
  const day17Elements = await page.getByText('17', { exact: false }).all();
  console.log(`Found ${day17Elements.length} elements containing "17"`);

  for (let i = 0; i < day17Elements.length; i++) {
    const element = day17Elements[i];
    const parent = element.locator('..'); // Get parent
    const content = await parent.textContent();
    console.log(`Element ${i} parent content:`, content);
  }

  // Check for "사회복지사" text
  const socialWorkerElements = await page.getByText('사회복지사', { exact: false }).all();
  console.log(`Found ${socialWorkerElements.length} elements containing "사회복지사"`);

  if (socialWorkerElements.length > 0) {
    console.log('✅ SUCCESS: Social Worker exam found on calendar!');
  } else {
    console.log('❌ FAIL: Social Worker exam NOT found on calendar');
  }
});
