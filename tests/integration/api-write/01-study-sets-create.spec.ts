import { test, expect } from '@playwright/test';

/**
 * S1 Group: Write-Heavy API Tests - Study Sets Create
 * Test IDs: API-WRITE-001 to API-WRITE-008
 *
 * Uses test.describe.serial() for sequential execution
 * Tests share state and must run in order
 */

test.describe.serial('S1: Study Sets Create API Tests (Sequential)', () => {
  let apiContext: any;
  let authToken: string;
  let createdStudySetId: string;
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
    // Cleanup: delete created study sets
    if (backendAvailable && createdStudySetId) {
      try {
        await apiContext.delete(`/api/v1/study-sets/${createdStudySetId}`, {
          headers: { 'Authorization': `Bearer ${authToken}` }
        });
      } catch (error) {
        // Ignore cleanup errors
      }
    }

    await apiContext.dispose();
  });

  test.beforeEach(async ({}, testInfo) => {
    if (!backendAvailable) {
      testInfo.skip(true, 'Backend server is not running on localhost:8000. Start the FastAPI backend to run these tests.');
    }
  });

  test('API-WRITE-001: Create study set with valid data', async () => {
    const response = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: '정보처리기사 샘플 테스트',
        description: 'API 통합 테스트용 학습 세트',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('id');
    expect(body).toHaveProperty('name');
    expect(body.name).toBe('정보처리기사 샘플 테스트');

    // Save ID for subsequent tests
    createdStudySetId = body.id;
  });

  test('API-WRITE-002: Verify created study set exists', async () => {
    const response = await apiContext.get(`/api/v1/study-sets/${createdStudySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body).toHaveProperty('data');
    expect(body.data.id).toBe(createdStudySetId);
    expect(body.data.name).toBe('정보처리기사 샘플 테스트');
  });

  test('API-WRITE-003: Create study set with missing required fields', async () => {
    const response = await apiContext.post('/api/v1/study-sets', {
      data: {
        description: 'No name provided'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(422);

    const body = await response.json();
    expect(body).toHaveProperty('detail');
  });

  test('API-WRITE-004: Create study set with invalid data types', async () => {
    const response = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: 12345,  // Should be string
        description: 'Invalid name type',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    // Backend may accept number and convert to string, or reject with 422
    expect([200, 422]).toContain(response.status());
  });

  test('API-WRITE-005: Create study set with duplicate name', async () => {
    // Try to create with the same name
    const response = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: '정보처리기사 샘플 테스트',
        description: 'Duplicate name test',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    // Duplicates are allowed (200), or may return 409 Conflict
    expect([200, 409]).toContain(response.status());

    if (response.status() === 409) {
      const body = await response.json();
      expect(body).toHaveProperty('detail');
    }
  });

  test('API-WRITE-006: Create study set with maximum length name', async () => {
    const longName = 'A'.repeat(255);

    const response = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: longName,
        description: 'Testing max length',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    // Should succeed if within limit, fail if exceeds
    expect([200, 400, 422]).toContain(response.status());

    if (response.status() === 200) {
      const body = await response.json();
      // Cleanup
      await apiContext.delete(`/api/v1/study-sets/${body.id}`, {
        headers: { 'Authorization': `Bearer ${authToken}` }
      });
    }
  });

  test('API-WRITE-007: Create study set without authentication', async () => {
    const response = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: 'Unauthorized Test',
        description: 'Should fail',
        certification_id: 'cert_001'
      },
      headers: {
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(401);
  });

  test('API-WRITE-008: Create study set with special characters in name', async () => {
    const response = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: '정보처리기사 (2024) - "실전" 모의고사 #1',
        description: 'Special characters test',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.name).toContain('정보처리기사');
    expect(body.name).toContain('#1');

    // Cleanup
    await apiContext.delete(`/api/v1/study-sets/${body.id}`, {
      headers: { 'Authorization': `Bearer ${authToken}` }
    });
  });
});
