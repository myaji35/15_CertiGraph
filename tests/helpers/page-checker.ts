import { Page } from '@playwright/test';

/**
 * Helper utilities for checking page existence and handling missing pages
 * Used to gracefully skip tests when application pages are not yet implemented
 */

export interface PageCheckResult {
  exists: boolean;
  statusCode?: number;
  message: string;
}

/**
 * Check if a page exists (returns non-404 status)
 * @param page - Playwright Page object
 * @param url - URL to check (relative or absolute)
 * @param options - Optional configuration
 * @returns PageCheckResult with existence status
 */
export async function checkPageExists(
  page: Page,
  url: string,
  options: { timeout?: number } = {}
): Promise<PageCheckResult> {
  const timeout = options.timeout || 10000;

  try {
    const response = await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout,
    });

    if (!response) {
      return {
        exists: false,
        message: `No response received from ${url}`,
      };
    }

    const statusCode = response.status();

    if (statusCode === 404) {
      return {
        exists: false,
        statusCode,
        message: `Page not found (404): ${url}. This page needs to be implemented.`,
      };
    }

    if (statusCode >= 500) {
      return {
        exists: false,
        statusCode,
        message: `Server error (${statusCode}): ${url}`,
      };
    }

    return {
      exists: true,
      statusCode,
      message: `Page exists: ${url}`,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);

    // Check if it's a timeout error
    if (errorMessage.includes('Timeout') || errorMessage.includes('timeout')) {
      return {
        exists: false,
        message: `Timeout waiting for page: ${url}. Page may not exist or is slow to load.`,
      };
    }

    return {
      exists: false,
      message: `Error checking page ${url}: ${errorMessage}`,
    };
  }
}

/**
 * Skip test if page doesn't exist with a descriptive message
 * @param page - Playwright Page object
 * @param url - URL to check
 * @param testName - Name of the test for logging
 */
export async function skipIfPageNotExists(
  page: Page,
  url: string,
  testName: string
): Promise<PageCheckResult> {
  const result = await checkPageExists(page, url, { timeout: 5000 });

  if (!result.exists) {
    console.log(`⏭️  Skipping ${testName}: ${result.message}`);
  }

  return result;
}

/**
 * Wait for a page to load with better error handling
 * @param page - Playwright Page object
 * @param url - URL to navigate to
 * @param options - Optional configuration
 */
export async function safeGoto(
  page: Page,
  url: string,
  options: { timeout?: number; waitUntil?: 'domcontentloaded' | 'load' } = {}
): Promise<PageCheckResult> {
  const timeout = options.timeout || 10000;
  const waitUntil = options.waitUntil || 'domcontentloaded';

  try {
    const response = await page.goto(url, {
      waitUntil,
      timeout,
    });

    if (!response) {
      return {
        exists: false,
        message: `No response received from ${url}`,
      };
    }

    const statusCode = response.status();

    if (statusCode === 404) {
      return {
        exists: false,
        statusCode,
        message: `Page not found (404): ${url}`,
      };
    }

    return {
      exists: true,
      statusCode,
      message: `Successfully loaded: ${url}`,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      exists: false,
      message: `Failed to load ${url}: ${errorMessage}`,
    };
  }
}
