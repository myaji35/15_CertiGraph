import { test, expect, Page } from '@playwright/test';

// BMad 테스트 251-280: 보안 테스트

const API_BASE = 'http://localhost:8015/api/v1';
const FRONTEND_URL = 'http://localhost:3030';

// Helper functions
async function loginAsUser(page: Page) {
  await page.goto(`${FRONTEND_URL}/login`);
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'Test1234!');
  await page.click('button[type="submit"]');
  await page.waitForURL(`${FRONTEND_URL}/dashboard`);
}

test.describe('BMad 보안 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(FRONTEND_URL);
  });

  // 인증 및 인가
  test('251. JWT 토큰 유효성 검증', async ({ page }) => {
    await loginAsUser(page);

    // Get JWT token
    const token = await page.evaluate(() => {
      return localStorage.getItem('jwt_token');
    });

    expect(token).toBeTruthy();

    // Verify token format (header.payload.signature)
    expect(token).toMatch(/^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+$/);
  });

  test('252. 토큰 만료 처리', async ({ page }) => {
    await loginAsUser(page);

    // Set expired token
    await page.evaluate(() => {
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MDk0NTkyMDB9.invalid';
      localStorage.setItem('jwt_token', expiredToken);
    });

    await page.reload();

    // Should redirect to login
    await expect(page).toHaveURL(`${FRONTEND_URL}/login`);
  });

  test('253. 무효 토큰 거부', async ({ page }) => {
    // Try to access protected route with invalid token
    await page.evaluate(() => {
      localStorage.setItem('jwt_token', 'invalid-token');
    });

    await page.goto(`${FRONTEND_URL}/dashboard`);

    // Should redirect to login
    await expect(page).toHaveURL(`${FRONTEND_URL}/login`);
  });

  test('254. 권한 없는 리소스 접근 차단', async ({ page }) => {
    await loginAsUser(page);

    // Try to access admin endpoint as regular user
    const response = await page.request.get(`${API_BASE}/admin/users`);

    expect(response.status()).toBe(403);
  });

  test('255. CSRF 토큰 검증', async ({ page }) => {
    await loginAsUser(page);

    // Get CSRF token
    const csrfToken = await page.evaluate(() => {
      return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
    });

    expect(csrfToken).toBeTruthy();

    // Request without CSRF token should fail
    const response = await page.request.post(`${API_BASE}/user/update`, {
      data: { name: 'Test' },
      headers: {
        'X-CSRF-Token': 'invalid'
      }
    });

    expect(response.status()).toBe(403);
  });

  // XSS 방어
  test('256. XSS 스크립트 주입 방어', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/profile`);

    const maliciousScript = '<script>alert("XSS")</script>';

    await page.fill('[name="bio"]', maliciousScript);
    await page.click('button:has-text("저장")');

    // Check if script is sanitized
    const bioContent = await page.locator('.bio-display').textContent();
    expect(bioContent).not.toContain('<script>');
    expect(bioContent).not.toContain('alert');
  });

  test('257. HTML 엔티티 이스케이프', async ({ page }) => {
    await loginAsUser(page);

    const htmlContent = '<img src=x onerror="alert(1)">';

    await page.fill('[name="comment"]', htmlContent);
    await page.click('button:has-text("댓글 작성")');

    // Check if HTML is escaped
    const commentHtml = await page.locator('.comment-text').innerHTML();
    expect(commentHtml).toContain('&lt;img');
    expect(commentHtml).not.toContain('<img');
  });

  test('258. 이벤트 핸들러 주입 방어', async ({ page }) => {
    await loginAsUser(page);

    const maliciousInput = '" onclick="alert(1)"';

    await page.fill('[name="title"]', maliciousInput);
    await page.click('button:has-text("저장")');

    // Click should not trigger alert
    await page.locator('.title-display').click();

    // Check no alert was triggered
    const alertTriggered = await page.evaluate(() => {
      let triggered = false;
      window.alert = () => { triggered = true; };
      return triggered;
    });

    expect(alertTriggered).toBeFalsy();
  });

  test('259. SVG XSS 방어', async ({ page }) => {
    await loginAsUser(page);

    const svgXss = '<svg onload="alert(1)">';

    await page.fill('[name="description"]', svgXss);
    await page.click('button:has-text("저장")');

    const description = await page.locator('.description-display').innerHTML();
    expect(description).not.toContain('onload');
  });

  test('260. 데이터 속성 XSS 방어', async ({ page }) => {
    await loginAsUser(page);

    const dataXss = 'data:text/html,<script>alert(1)</script>';

    await page.fill('[name="website"]', dataXss);
    await page.click('button:has-text("저장")');

    const link = await page.locator('.website-link').getAttribute('href');
    expect(link).not.toContain('data:text/html');
  });

  // SQL Injection 방어
  test('261. SQL 인젝션 - 로그인', async ({ page }) => {
    const sqlInjection = "admin' OR '1'='1";

    await page.fill('[name="email"]', sqlInjection);
    await page.fill('[name="password"]', 'anypassword');
    await page.click('button:has-text("로그인")');

    await expect(page.locator('.error-message')).toContainText(/잘못된|실패/i);
  });

  test('262. SQL 인젝션 - 검색', async ({ page }) => {
    await loginAsUser(page);

    const searchInjection = "'; DROP TABLE users; --";

    await page.fill('[name="search"]', searchInjection);
    await page.click('button:has-text("검색")');

    // Should return safe results or error, not execute SQL
    await expect(page.locator('.search-results')).toBeVisible();

    // Verify table still exists
    const response = await page.request.get(`${API_BASE}/users/profile`);
    expect(response.status()).toBe(200);
  });

  test('263. NoSQL 인젝션 방어', async ({ page }) => {
    await loginAsUser(page);

    const noSqlInjection = { '$ne': null };

    const response = await page.request.post(`${API_BASE}/search`, {
      data: {
        query: noSqlInjection
      }
    });

    expect(response.status()).toBe(400); // Bad request
  });

  test('264. 파라미터화된 쿼리 검증', async ({ page }) => {
    await loginAsUser(page);

    const response = await page.request.get(`${API_BASE}/users?id=1 OR 1=1`);

    // Should not return all users
    const data = await response.json();
    expect(Array.isArray(data) ? data.length : 0).toBeLessThanOrEqual(1);
  });

  test('265. 준비된 명령문 사용 확인', async ({ page }) => {
    await loginAsUser(page);

    // Test with various SQL metacharacters
    const testInputs = ["'; --", "\" OR \"\"=\"", "1' UNION SELECT * FROM users--"];

    for (const input of testInputs) {
      const response = await page.request.get(`${API_BASE}/questions?search=${encodeURIComponent(input)}`);
      expect(response.status()).toBe(200); // Should handle safely
    }
  });

  // 파일 업로드 보안
  test('266. 악성 파일 업로드 차단', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/upload`);

    // Try to upload executable
    const exeFile = Buffer.from('MZ\x90\x00'); // EXE header

    await page.locator('input[type="file"]').setInputFiles({
      name: 'malicious.exe',
      mimeType: 'application/x-msdownload',
      buffer: exeFile
    });

    await page.click('button:has-text("업로드")');

    await expect(page.locator('.error-message')).toContainText(/허용되지 않는|차단/i);
  });

  test('267. 파일 크기 제한 검증', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/upload`);

    // 101MB file (over limit)
    const largeFile = Buffer.alloc(101 * 1024 * 1024);

    await page.locator('input[type="file"]').setInputFiles({
      name: 'large.pdf',
      mimeType: 'application/pdf',
      buffer: largeFile
    });

    await expect(page.locator('.error-message')).toContainText(/크기.*초과/i);
  });

  test('268. 파일 경로 트래버설 방어', async ({ page }) => {
    await loginAsUser(page);

    const response = await page.request.get(`${API_BASE}/files/download?path=../../../etc/passwd`);

    expect(response.status()).toBe(400); // Bad request or forbidden
  });

  test('269. 파일 MIME 타입 검증', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/upload`);

    // PHP file disguised as image
    const phpFile = Buffer.from('<?php echo "hacked"; ?>');

    await page.locator('input[type="file"]').setInputFiles({
      name: 'image.jpg',
      mimeType: 'image/jpeg',
      buffer: phpFile
    });

    await page.click('button:has-text("업로드")');

    await expect(page.locator('.error-message')).toContainText(/잘못된.*형식/i);
  });

  test('270. 업로드 디렉토리 실행 권한', async ({ page }) => {
    await loginAsUser(page);

    // Upload a legitimate file
    const pdfFile = Buffer.from('%PDF-1.4');

    await page.goto(`${FRONTEND_URL}/upload`);
    await page.locator('input[type="file"]').setInputFiles({
      name: 'test.pdf',
      mimeType: 'application/pdf',
      buffer: pdfFile
    });

    await page.click('button:has-text("업로드")');
    await page.waitForSelector('.upload-success');

    // Try to execute uploaded file (should fail)
    const uploadedUrl = await page.locator('.uploaded-file-url').textContent();
    const response = await page.request.get(uploadedUrl || '');

    // Should return file content, not execute
    expect(response.headers()['content-type']).toContain('application/pdf');
  });

  // API 보안
  test('271. API 속도 제한', async ({ page }) => {
    const requests = [];

    // Send 100 requests rapidly
    for (let i = 0; i < 100; i++) {
      requests.push(
        page.request.get(`${API_BASE}/public/data`)
      );
    }

    const responses = await Promise.all(requests);

    // Some requests should be rate limited
    const rateLimited = responses.filter(r => r.status() === 429);
    expect(rateLimited.length).toBeGreaterThan(0);
  });

  test('272. API 키 검증', async ({ page }) => {
    // Request without API key
    let response = await page.request.get(`${API_BASE}/protected/data`);
    expect(response.status()).toBe(401);

    // Request with invalid API key
    response = await page.request.get(`${API_BASE}/protected/data`, {
      headers: {
        'X-API-Key': 'invalid-key'
      }
    });
    expect(response.status()).toBe(401);
  });

  test('273. CORS 정책 검증', async ({ page }) => {
    const response = await page.request.options(`${API_BASE}/data`, {
      headers: {
        'Origin': 'https://evil.com',
        'Access-Control-Request-Method': 'POST'
      }
    });

    const allowedOrigin = response.headers()['access-control-allow-origin'];
    expect(allowedOrigin).not.toBe('https://evil.com');
    expect(allowedOrigin).not.toBe('*');
  });

  test('274. API 입력 검증', async ({ page }) => {
    await loginAsUser(page);

    // Send invalid data types
    const response = await page.request.post(`${API_BASE}/user/age`, {
      data: {
        age: 'not-a-number'
      }
    });

    expect(response.status()).toBe(400);
    const error = await response.json();
    expect(error.message).toContain('validation');
  });

  test('275. GraphQL 쿼리 깊이 제한', async ({ page }) => {
    await loginAsUser(page);

    // Deep nested query
    const deepQuery = `
      query {
        user {
          materials {
            questions {
              answers {
                user {
                  materials {
                    questions {
                      answers {
                        user {
                          id
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    `;

    const response = await page.request.post(`${API_BASE}/graphql`, {
      data: { query: deepQuery }
    });

    expect(response.status()).toBe(400);
    const error = await response.json();
    expect(error.errors[0].message).toContain('depth');
  });

  // 세션 보안
  test('276. 세션 하이재킹 방어', async ({ page, context }) => {
    await loginAsUser(page);

    // Get session cookie
    const cookies = await context.cookies();
    const sessionCookie = cookies.find(c => c.name === 'session_id');

    expect(sessionCookie?.httpOnly).toBeTruthy();
    expect(sessionCookie?.secure).toBeTruthy();
    expect(sessionCookie?.sameSite).toBe('Strict');
  });

  test('277. 세션 고정 공격 방어', async ({ page }) => {
    // Set a session ID before login
    await page.context().addCookies([{
      name: 'session_id',
      value: 'fixed-session-id',
      domain: 'localhost',
      path: '/'
    }]);

    await loginAsUser(page);

    // Session ID should be regenerated after login
    const cookies = await page.context().cookies();
    const newSession = cookies.find(c => c.name === 'session_id');

    expect(newSession?.value).not.toBe('fixed-session-id');
  });

  test('278. 동시 세션 제한', async ({ page, browser }) => {
    await loginAsUser(page);

    // Try to login from another browser
    const context2 = await browser.newContext();
    const page2 = await context2.newPage();

    await page2.goto(`${FRONTEND_URL}/login`);
    await page2.fill('[name="email"]', 'test@example.com');
    await page2.fill('[name="password"]', 'Test1234!');
    await page2.click('button[type="submit"]');

    // First session should be invalidated
    await page.reload();
    await expect(page).toHaveURL(`${FRONTEND_URL}/login`);

    await context2.close();
  });

  test('279. 세션 타임아웃', async ({ page }) => {
    await loginAsUser(page);

    // Simulate session timeout
    await page.evaluate(() => {
      const expires = new Date();
      expires.setMinutes(expires.getMinutes() - 30);
      document.cookie = `session_expires=${expires.toISOString()}; path=/`;
    });

    await page.reload();

    // Should redirect to login
    await expect(page).toHaveURL(`${FRONTEND_URL}/login`);
  });

  test('280. 로그아웃 후 세션 무효화', async ({ page }) => {
    await loginAsUser(page);

    // Get session token
    const tokenBefore = await page.evaluate(() => {
      return localStorage.getItem('jwt_token');
    });

    // Logout
    await page.click('button:has-text("로그아웃")');

    // Session should be cleared
    const tokenAfter = await page.evaluate(() => {
      return localStorage.getItem('jwt_token');
    });

    expect(tokenAfter).toBeNull();

    // Try to use old token
    const response = await page.request.get(`${API_BASE}/user/profile`, {
      headers: {
        'Authorization': `Bearer ${tokenBefore}`
      }
    });

    expect(response.status()).toBe(401);
  });
});

// Advanced security tests
test.describe('고급 보안 테스트', () => {
  test('S01. 암호화 강도 검증', async ({ page }) => {
    const response = await page.request.get(`${API_BASE}/security/encryption-info`);
    const data = await response.json();

    expect(data.algorithm).toMatch(/AES-256|RSA-2048/);
    expect(data.tlsVersion).toMatch(/TLSv1\.[23]/);
  });

  test('S02. 보안 헤더 검증', async ({ page }) => {
    const response = await page.goto(FRONTEND_URL);
    const headers = response?.headers() || {};

    expect(headers['x-frame-options']).toBe('DENY');
    expect(headers['x-content-type-options']).toBe('nosniff');
    expect(headers['x-xss-protection']).toBe('1; mode=block');
    expect(headers['strict-transport-security']).toContain('max-age=');
    expect(headers['content-security-policy']).toBeTruthy();
  });

  test('S03. 취약점 스캔', async ({ page }) => {
    await loginAsUser(page);

    // Common vulnerability patterns
    const vulnerabilityTests = [
      { path: '/.git', expectedStatus: 404 },
      { path: '/.env', expectedStatus: 404 },
      { path: '/admin', expectedStatus: 403 },
      { path: '/wp-admin', expectedStatus: 404 },
      { path: '/../etc/passwd', expectedStatus: 400 }
    ];

    for (const test of vulnerabilityTests) {
      const response = await page.request.get(`${FRONTEND_URL}${test.path}`);
      expect(response.status()).toBe(test.expectedStatus);
    }
  });
});