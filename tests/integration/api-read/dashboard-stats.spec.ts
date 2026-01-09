import { test, expect } from '@playwright/test';

/**
 * P3 Group: API Read-Only Tests - Dashboard Stats
 * Test IDs: API-READ-013 to API-READ-018
 *
 * All tests run in parallel
 */

test.describe('P3: Dashboard Stats API Tests', () => {
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

  test('API-READ-013: GET /api/dashboard/stats - Get user statistics', async () => {
    const response = await apiContext.get('/api/v1/dashboard/stats', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('total_questions');
    expect(body).toHaveProperty('correct_answers');
    expect(body).toHaveProperty('accuracy_percentage');
  });

  test('API-READ-014: GET /api/dashboard/recent-activity - Get recent activity', async () => {
    const response = await apiContext.get('/api/v1/dashboard/recent-activity', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(Array.isArray(body.activities)).toBe(true);

    if (body.activities.length > 0) {
      const activity = body.activities[0];
      expect(activity).toHaveProperty('date');
      expect(activity).toHaveProperty('type');
    }
  });

  test('API-READ-015: GET /api/dashboard/weak-concepts - Get weak concepts', async () => {
    const response = await apiContext.get('/api/v1/dashboard/weak-concepts', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(Array.isArray(body.weak_concepts)).toBe(true);

    if (body.weak_concepts.length > 0) {
      const concept = body.weak_concepts[0];
      expect(concept).toHaveProperty('concept');
      expect(concept).toHaveProperty('accuracy');
      expect(concept.accuracy).toBeLessThan(70.0);  // Weak concepts have < 70% accuracy
    }
  });

  test('API-READ-016: GET /api/knowledge-graph - Get knowledge graph data', async () => {
    const response = await apiContext.get('/api/v1/knowledge-graph', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('nodes');
    expect(body).toHaveProperty('edges');
    expect(Array.isArray(body.nodes)).toBe(true);
    expect(Array.isArray(body.edges)).toBe(true);

    if (body.nodes.length > 0) {
      const node = body.nodes[0];
      expect(node).toHaveProperty('id');
      expect(node).toHaveProperty('label');
      expect(node).toHaveProperty('status');
    }
  });

  test('API-READ-017: GET /api/knowledge-graph/:concept - Get concept details', async () => {
    const conceptId = 'concept_normalization';

    const response = await apiContext.get(`/api/v1/knowledge-graph/${conceptId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect([200, 404]).toContain(response.status());

    if (response.status() === 200) {
      const body = await response.json();
      expect(body).toHaveProperty('id');
      expect(body).toHaveProperty('name');
      expect(body).toHaveProperty('prerequisites');
      expect(body).toHaveProperty('related_questions');
      expect(Array.isArray(body.prerequisites)).toBe(true);
    }
  });

  test('API-READ-018: GET /api/dashboard/study-progress - Get study progress over time', async () => {
    const response = await apiContext.get('/api/v1/dashboard/study-progress', {
      params: {
        period: 'last_7_days'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('total_materials');
    expect(body).toHaveProperty('completed_materials');
    expect(body).toHaveProperty('progress_percentage');
    expect(body).toHaveProperty('total_questions');
    expect(body).toHaveProperty('attempted_questions');
    expect(body).toHaveProperty('mastered_questions');
  });
});
