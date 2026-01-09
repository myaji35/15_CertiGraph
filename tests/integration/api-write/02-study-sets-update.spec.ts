import { test, expect } from '@playwright/test';

/**
 * S1 Group: Write-Heavy API Tests - Study Sets Update
 * Test IDs: API-WRITE-009 to API-WRITE-014
 *
 * Uses test.describe.serial() for sequential execution
 */

test.describe.serial('S1: Study Sets Update API Tests (Sequential)', () => {
  let apiContext: any;
  let authToken: string;
  let studySetId: string;
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
      return;
    }

    // Create a study set for testing
    try {
      const createResponse = await apiContext.post('/api/v1/study-sets', {
        data: {
          name: 'Update Test Study Set',
          description: 'Original description',
          certification_id: 'cert_001'
        },
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      });

      const createBody = await createResponse.json();
      studySetId = createBody.id;
    } catch (error) {
      backendAvailable = false;
    }
  });

  test.afterAll(async () => {
    // Cleanup
    if (backendAvailable && studySetId) {
      try {
        await apiContext.delete(`/api/v1/study-sets/${studySetId}`, {
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

  test('API-WRITE-009: Update study set name', async () => {
    const response = await apiContext.patch(`/api/v1/study-sets/${studySetId}`, {
      data: {
        name: 'Updated Study Set Name'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.id).toBe(studySetId);
    expect(body.name).toBe('Updated Study Set Name');
  });

  test('API-WRITE-010: Update study set description', async () => {
    const response = await apiContext.patch(`/api/v1/study-sets/${studySetId}`, {
      data: {
        description: 'This is the updated description'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(body.description).toBe('This is the updated description');
  });

  test('API-WRITE-011: Update non-existent study set', async () => {
    const response = await apiContext.patch('/api/v1/study-sets/non_existent_id', {
      data: {
        name: 'Should Fail'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(404);
  });

  test('API-WRITE-012: Update with invalid data', async () => {
    const response = await apiContext.patch(`/api/v1/study-sets/${studySetId}`, {
      data: {
        name: ''  // Empty name should be invalid
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(400);

    const body = await response.json();
    expect(body).toHaveProperty('error');
  });

  test('API-WRITE-013: Update without authentication', async () => {
    const response = await apiContext.patch(`/api/v1/study-sets/${studySetId}`, {
      data: {
        name: 'Unauthorized Update'
      },
      headers: {
        'Content-Type': 'application/json'
      }
    });

    expect(response.status()).toBe(401);
  });

  test('API-WRITE-014: Update with concurrent modification check', async () => {
    // Get current version
    const getResponse = await apiContext.get(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    const currentData = await getResponse.json();

    // Simulate concurrent update by updating twice
    const update1 = await apiContext.patch(`/api/v1/study-sets/${studySetId}`, {
      data: {
        name: 'First Update'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    const update2 = await apiContext.patch(`/api/v1/study-sets/${studySetId}`, {
      data: {
        name: 'Second Update'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    });

    // Both should succeed (last write wins)
    expect(update1.status()).toBe(200);
    expect(update2.status()).toBe(200);

    // Verify final state
    const finalResponse = await apiContext.get(`/api/v1/study-sets/${studySetId}`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    const finalData = await finalResponse.json();
    expect(finalData.name).toBe('Second Update');
  });
});
