import { test, expect } from '@playwright/test';

test('Debug calendar - verify Social Worker exam on Jan 17', async ({ page }) => {
  // Navigate to certifications page
  await page.goto('http://localhost:3030/certifications');
  console.log('Navigated to certifications page');

  // Wait for page to load
  await page.waitForTimeout(3000);

  // Check current month/year
  const headerText = await page.locator('h2').first().textContent();
  console.log('Current header:', headerText);

  // Take screenshot
  await page.screenshot({ path: 'test-results/calendar-current.png', fullPage: true });
  console.log('Screenshot saved: calendar-current.png');

  // Log all text on page containing "사회복지사"
  const pageText = await page.textContent('body');
  if (pageText?.includes('사회복지사')) {
    console.log('✅ Page contains "사회복지사" text');

    // Find where it appears
    const elements = await page.locator('text=사회복지사').all();
    console.log(`Found ${elements.length} elements with "사회복지사"`);

    for (let i = 0; i < elements.length; i++) {
      const text = await elements[i].textContent();
      console.log(`Element ${i}:`, text);
    }
  } else {
    console.log('❌ Page does NOT contain "사회복지사" text');
  }

  // Check network requests for calendar API
  const requests: string[] = [];
  page.on('request', request => {
    if (request.url().includes('calendar') || request.url().includes('certifications')) {
      requests.push(request.url());
    }
  });

  // Wait for any pending network requests
  await page.waitForLoadState('networkidle');
  console.log('Network requests:', requests);
});
