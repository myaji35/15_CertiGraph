import { test, expect } from '@playwright/test';

/**
 * P3 Group: API Read-Only Tests - Study Sets GET
 * Test IDs: API-READ-001 to API-READ-006
 *
 * All tests run in parallel
 * Uses Playwright request context for API testing
 */

test.describe('P3: Study Sets GET API Tests', () => {
  test.describe.configure({ mode: 'parallel' });
  let apiContext: any;
  let authToken: string;
  let backendAvailable: boolean = false;

  test.beforeAll(async ({ playwright }) => {
    apiContext = await playwright.request.newContext({
      baseURL: 'http://localhost:8000',
    });

    // Mock authentication token
    authToken = 'mock_token_for_testing';

    // Check if backend is available
    try {
      const healthCheck = await apiContext.get('/health', { timeout: 3000 });
      backendAvailable = healthCheck.ok();
    } catch (error) {
      backendAvailable = false;
      console.log('Backend server not available at http://localhost:8000 - tests will be skipped');
    }
  });

  test.afterAll(async () => {
    await apiContext.dispose();
  });

  test.beforeEach(async ({}, testInfo) => {
    if (!backendAvailable) {
      testInfo.skip(true, 'Backend server is not running on localhost:8000. Start the FastAPI backend to run these tests.');
    }
  });

  test('API-READ-001: GET /api/study-sets - List with default pagination', async () => {
    const response = await apiContext.get('/api/v1/study-sets', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('data');
    expect(body).toHaveProperty('total');
    expect(Array.isArray(body.data)).toBe(true);
  });

  test('API-READ-002: GET /api/study-sets - Filter by certification type', async () => {
    const response = await apiContext.get('/api/v1/study-sets', {
      params: {
        certification: '정보처리기사'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('data');
    // All returned items should have valid structure
    if (body.data.length > 0) {
      expect(body.data[0]).toHaveProperty('id');
      expect(body.data[0]).toHaveProperty('name');
    }
  });

  test('API-READ-003: GET /api/study-sets/:id - Get specific study set', async () => {
    const studySetId = 'mock_study_set_id';

    const response = await apiContext.get(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    // May return 200 or 404 depending on whether data exists
    expect([200, 404]).toContain(response.status());

    if (response.status() === 200) {
      const body = await response.json();
      expect(body).toHaveProperty('data');
      expect(body.data).toHaveProperty('id');
      expect(body.data).toHaveProperty('name');
    }
  });

  test('API-READ-004: GET /api/study-sets - Pagination works correctly', async () => {
    const response = await apiContext.get('/api/v1/study-sets', {
      params: {
        offset: 0,
        limit: 10
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('data');
    expect(body).toHaveProperty('total');
    expect(Array.isArray(body.data)).toBe(true);
  });

  test('API-READ-005: GET /api/study-sets - Sort by created date', async () => {
    const response = await apiContext.get('/api/v1/study-sets', {
      params: {
        sort: 'created_at',
        order: 'desc'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    // Verify sorting (if data exists)
    if (body.data.length >= 2) {
      const firstDate = new Date(body.data[0].created_at);
      const secondDate = new Date(body.data[1].created_at);
      expect(firstDate >= secondDate).toBe(true);
    }
  });

  test('API-READ-006: GET /api/study-sets - Search by name', async () => {
    const response = await apiContext.get('/api/v1/study-sets', {
      params: {
        search: '정보처리'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    // If results exist, they should match the search term
    if (body.data.length > 0) {
      const firstResult = body.data[0];
      expect(firstResult.name.toLowerCase()).toContain('정보처리'.toLowerCase());
    }
  });
});
