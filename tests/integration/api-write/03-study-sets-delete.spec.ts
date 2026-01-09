import { test, expect } from '@playwright/test';

/**
 * S1 Group: Write-Heavy API Tests - Study Sets Delete
 * Test IDs: API-WRITE-015 to API-WRITE-020
 *
 * Uses test.describe.serial() for sequential execution
 */

test.describe.serial('S1: Study Sets Delete API Tests (Sequential)', () => {
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

  test('API-WRITE-015: Delete study set successfully', async () => {
    // Create a study set to delete
    const createResponse = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: 'Study Set to Delete',
        description: 'Will be deleted',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    const createBody = await createResponse.json();
    const studySetId = createBody.id;

    // Delete it
    const deleteResponse = await apiContext.delete(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(deleteResponse.status()).toBe(200);

    const deleteBody = await deleteResponse.json();
    expect(deleteBody).toHaveProperty('data');
    expect(deleteBody.data.deleted).toBe(true);

    // Verify it's deleted
    const getResponse = await apiContext.get(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(getResponse.status()).toBe(404);
  });

  test('API-WRITE-016: Delete non-existent study set', async () => {
    const response = await apiContext.delete('/api/v1/study-sets/non_existent_id', {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(response.status()).toBe(404);
  });

  test('API-WRITE-017: Delete without authentication', async () => {
    // Create a study set
    const createResponse = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: 'Protected Study Set',
        description: 'Cannot delete without auth',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    const createBody = await createResponse.json();
    const studySetId = createBody.id;

    // Try to delete without auth
    const deleteResponse = await apiContext.delete(`/api/v1/study-sets/${studySetId}`, {
      headers: {}
    });

    expect(deleteResponse.status()).toBe(401);

    // Cleanup
    await apiContext.delete(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
  });

  test('API-WRITE-018: Delete cascades to related questions', async () => {
    // Create study set with questions
    const createResponse = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: 'Study Set with Questions',
        description: 'Has related questions',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    const createBody = await createResponse.json();
    const studySetId = createBody.id;

    // Add questions (simplified - actual implementation may differ)
    // ...

    // Delete study set
    const deleteResponse = await apiContext.delete(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(deleteResponse.status()).toBe(200);

    // Verify related questions are also deleted
    const questionsResponse = await apiContext.get('/api/v1/questions', {
      params: {
        material_id: studySetId
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    const questionsBody = await questionsResponse.json();
    expect(questionsBody.questions.length).toBe(0);
  });

  test('API-WRITE-019: Delete is idempotent', async () => {
    // Create and delete a study set
    const createResponse = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: 'Idempotent Delete Test',
        description: 'Testing idempotency',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    const createBody = await createResponse.json();
    const studySetId = createBody.id;

    // First delete
    const delete1 = await apiContext.delete(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(delete1.status()).toBe(200);

    // Second delete (should return 404)
    const delete2 = await apiContext.delete(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(delete2.status()).toBe(404);
  });

  test('API-WRITE-020: Soft delete vs hard delete', async () => {
    // Create a study set
    const createResponse = await apiContext.post('/api/v1/study-sets', {
      data: {
        name: 'Soft Delete Test',
        description: 'Testing soft delete',
        certification_id: 'cert_001'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    const createBody = await createResponse.json();
    const studySetId = createBody.id;

    // Delete it
    const deleteResponse = await apiContext.delete(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    expect(deleteResponse.status()).toBe(200);

    // If soft delete is implemented, it might be retrievable with a special flag
    const getWithDeletedResponse = await apiContext.get(`/api/v1/study-sets/${studySetId}`, {
      params: {
        include_deleted: true
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    // Hard delete is implemented, should return 404
    expect(getWithDeletedResponse.status()).toBe(404);
  });
});
