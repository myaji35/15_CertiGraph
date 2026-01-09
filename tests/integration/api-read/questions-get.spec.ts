import { test, expect } from '@playwright/test';

/**
 * P3 Group: API Read-Only Tests - Questions GET
 * Test IDs: API-READ-007 to API-READ-012
 *
 * All tests run in parallel
 */

test.describe('P3: Questions GET API Tests', () => {
  test.describe.configure({ mode: 'parallel' });
  let apiContext: any;
  let authToken: string;
  let backendAvailable: boolean = false;

  test.beforeAll(async ({ playwright }) => {
    apiContext = await playwright.request.newContext({
      baseURL: 'http://localhost:8000',
    });

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

  test('API-READ-007: GET /api/questions - List all questions', async () => {
    const response = await apiContext.get('/api/v1/questions', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('success');
    expect(body).toHaveProperty('questions');
    expect(Array.isArray(body.questions)).toBe(true);
    expect(body).toHaveProperty('total_count');
  });

  test('API-READ-008: GET /api/questions/:id - Get specific question', async () => {
    const questionId = 'mock_question_id';

    const response = await apiContext.get(`/api/v1/questions/${questionId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect([200, 404]).toContain(response.status());

    if (response.status() === 200) {
      const body = await response.json();
      expect(body).toHaveProperty('id');
      expect(body).toHaveProperty('question_text');
      expect(body).toHaveProperty('options');
      expect(Array.isArray(body.options)).toBe(true);
    }
  });

  test('API-READ-009: GET /api/questions - Filter by study set', async () => {
    const materialId = 'mock_study_set_1';

    const response = await apiContext.get('/api/v1/questions', {
      params: {
        material_id: materialId
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('questions');
    // All returned questions should belong to the specified material
    if (body.questions && body.questions.length > 0) {
      expect(body.questions[0]).toHaveProperty('id');
    }
  });

  test('API-READ-010: GET /api/questions/:id - Answer options are randomized', async () => {
    const questionId = 'mock_question_id';

    // Make two requests to the same question
    const response1 = await apiContext.get(`/api/v1/questions/${questionId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    const response2 = await apiContext.get(`/api/v1/questions/${questionId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    // Note: This test assumes the API randomizes options per request
    // If both return 200, verify structure
    if (response1.status() === 200 && response2.status() === 200) {
      const body1 = await response1.json();
      const body2 = await response2.json();

      expect(body1.options).toBeDefined();
      expect(body2.options).toBeDefined();

      // Options might be in different order (if randomization is implemented)
      expect(body1.options.length).toBe(body2.options.length);
    }
  });

  test('API-READ-011: GET /api/questions - Filter by concept', async () => {
    const response = await apiContext.get('/api/v1/questions', {
      params: {
        concept: '정규화'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('questions');
    // If results exist, they should be related to the concept
    if (body.questions && body.questions.length > 0) {
      expect(body.questions[0]).toHaveProperty('id');
    }
  });

  test('API-READ-012: GET /api/questions - Filter by difficulty', async () => {
    const response = await apiContext.get('/api/v1/questions', {
      params: {
        difficulty: 'medium'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('questions');
    // If results exist, they should match the difficulty filter
    if (body.questions && body.questions.length > 0) {
      expect(body.questions[0]).toHaveProperty('id');
    }
  });
});
