import { test, expect, Page } from '@playwright/test';

// BMad 테스트 221-250: 성능 테스트

const API_BASE = 'http://localhost:8015/api/v1';
const FRONTEND_URL = 'http://localhost:3000';

// Helper functions
async function loginAsUser(page: Page) {
  await page.goto(`${FRONTEND_URL}/login`);
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'Test1234!');
  await page.click('button[type="submit"]');
  await page.waitForURL(`${FRONTEND_URL}/dashboard`);
}

async function measureLoadTime(page: Page, url: string): Promise<number> {
  const startTime = Date.now();
  await page.goto(url);
  await page.waitForLoadState('networkidle');
  return Date.now() - startTime;
}

test.describe('BMad 성능 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(FRONTEND_URL);
  });

  // 페이지 로딩 성능
  test('221. 홈페이지 로딩 시간', async ({ page }) => {
    const loadTime = await measureLoadTime(page, FRONTEND_URL);
    expect(loadTime).toBeLessThan(2000); // 2초 이내
  });

  test('222. 대시보드 로딩 시간', async ({ page }) => {
    await loginAsUser(page);
    const loadTime = await measureLoadTime(page, `${FRONTEND_URL}/dashboard`);
    expect(loadTime).toBeLessThan(3000); // 3초 이내
  });

  test('223. 대용량 데이터 렌더링', async ({ page }) => {
    await loginAsUser(page);

    const startTime = Date.now();
    await page.goto(`${FRONTEND_URL}/study-materials/large-list`);

    // 1000개 항목 렌더링
    await expect(page.locator('.material-item')).toHaveCount(1000, { timeout: 5000 });

    const renderTime = Date.now() - startTime;
    expect(renderTime).toBeLessThan(5000);
  });

  test('224. 이미지 레이지 로딩', async ({ page }) => {
    await page.goto(`${FRONTEND_URL}/gallery`);

    // Check initial viewport images loaded
    const viewportImages = await page.locator('.image-item:visible img').count();
    expect(viewportImages).toBeGreaterThan(0);

    // Check below-fold images are lazy loaded
    const lazyImages = await page.locator('img[loading="lazy"]').count();
    expect(lazyImages).toBeGreaterThan(0);
  });

  test('225. 페이지네이션 성능', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/questions`);

    const times: number[] = [];

    for (let i = 1; i <= 5; i++) {
      const startTime = Date.now();
      await page.click(`.pagination button:has-text("${i}")`);
      await page.waitForSelector('.question-item');
      times.push(Date.now() - startTime);
    }

    // Average pagination time should be under 500ms
    const avgTime = times.reduce((a, b) => a + b, 0) / times.length;
    expect(avgTime).toBeLessThan(500);
  });

  // API 응답 성능
  test('226. API 응답 시간 - 로그인', async ({ page }) => {
    const startTime = Date.now();

    const response = await page.request.post(`${API_BASE}/auth/login`, {
      data: {
        email: 'test@example.com',
        password: 'Test1234!'
      }
    });

    const responseTime = Date.now() - startTime;
    expect(response.status()).toBe(200);
    expect(responseTime).toBeLessThan(1000);
  });

  test('227. API 응답 시간 - 데이터 조회', async ({ page }) => {
    await loginAsUser(page);

    const startTime = Date.now();
    const response = await page.request.get(`${API_BASE}/study-materials`);
    const responseTime = Date.now() - startTime;

    expect(response.status()).toBe(200);
    expect(responseTime).toBeLessThan(2000);
  });

  test('228. GraphQL 쿼리 성능', async ({ page }) => {
    await loginAsUser(page);

    const query = `
      query GetUserData {
        user {
          id
          studyMaterials {
            id
            title
          }
          exams {
            id
            score
          }
        }
      }
    `;

    const startTime = Date.now();
    const response = await page.request.post(`${API_BASE}/graphql`, {
      data: { query }
    });
    const responseTime = Date.now() - startTime;

    expect(response.status()).toBe(200);
    expect(responseTime).toBeLessThan(1500);
  });

  test('229. 파일 업로드 성능', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/upload`);

    // Create 10MB file
    const buffer = Buffer.alloc(10 * 1024 * 1024);

    const startTime = Date.now();
    await page.locator('input[type="file"]').setInputFiles({
      name: 'test.pdf',
      mimeType: 'application/pdf',
      buffer
    });

    await page.click('button:has-text("업로드")');
    await page.waitForSelector('.upload-success', { timeout: 30000 });

    const uploadTime = Date.now() - startTime;
    expect(uploadTime).toBeLessThan(30000); // 30초 이내
  });

  test('230. 동시 요청 처리', async ({ page }) => {
    await loginAsUser(page);

    const promises = [];
    const requestCount = 10;

    const startTime = Date.now();

    for (let i = 0; i < requestCount; i++) {
      promises.push(
        page.request.get(`${API_BASE}/questions?page=${i}`)
      );
    }

    const responses = await Promise.all(promises);
    const totalTime = Date.now() - startTime;

    responses.forEach(response => {
      expect(response.status()).toBe(200);
    });

    expect(totalTime).toBeLessThan(5000); // 10 requests in 5 seconds
  });

  // 메모리 사용량
  test('231. 메모리 누수 확인', async ({ page }) => {
    await loginAsUser(page);

    // Get initial memory
    const initialMemory = await page.evaluate(() => {
      if ('memory' in performance) {
        return (performance as any).memory.usedJSHeapSize;
      }
      return 0;
    });

    // Perform actions
    for (let i = 0; i < 10; i++) {
      await page.goto(`${FRONTEND_URL}/dashboard`);
      await page.goto(`${FRONTEND_URL}/exams`);
      await page.goto(`${FRONTEND_URL}/study-materials`);
    }

    // Force garbage collection
    await page.evaluate(() => {
      if (global.gc) global.gc();
    });

    // Get final memory
    const finalMemory = await page.evaluate(() => {
      if ('memory' in performance) {
        return (performance as any).memory.usedJSHeapSize;
      }
      return 0;
    });

    // Memory increase should be reasonable
    const memoryIncrease = finalMemory - initialMemory;
    expect(memoryIncrease).toBeLessThan(50 * 1024 * 1024); // Less than 50MB increase
  });

  test('232. 대용량 이미지 처리', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/image-processor`);

    // Create 5MB image
    const imageBuffer = Buffer.alloc(5 * 1024 * 1024);

    const startTime = Date.now();
    await page.locator('input[type="file"]').setInputFiles({
      name: 'large-image.jpg',
      mimeType: 'image/jpeg',
      buffer: imageBuffer
    });

    await page.waitForSelector('.image-processed', { timeout: 10000 });

    const processTime = Date.now() - startTime;
    expect(processTime).toBeLessThan(10000);
  });

  test('233. 캐싱 효과 측정', async ({ page }) => {
    await loginAsUser(page);

    // First load
    const firstLoadTime = await measureLoadTime(page, `${FRONTEND_URL}/study-materials`);

    // Second load (should be cached)
    const secondLoadTime = await measureLoadTime(page, `${FRONTEND_URL}/study-materials`);

    // Cache should improve load time by at least 30%
    expect(secondLoadTime).toBeLessThan(firstLoadTime * 0.7);
  });

  test('234. WebSocket 연결 성능', async ({ page }) => {
    await loginAsUser(page);

    const startTime = Date.now();

    await page.evaluate(() => {
      return new Promise<void>((resolve) => {
        const ws = new WebSocket('ws://localhost:8015/ws');
        ws.onopen = () => {
          ws.close();
          resolve();
        };
      });
    });

    const connectionTime = Date.now() - startTime;
    expect(connectionTime).toBeLessThan(1000);
  });

  test('235. 검색 자동완성 성능', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/search`);

    const searchInput = page.locator('input[type="search"]');

    const startTime = Date.now();
    await searchInput.fill('정보처리');

    // Wait for autocomplete suggestions
    await page.waitForSelector('.autocomplete-suggestions', { timeout: 500 });

    const suggestionTime = Date.now() - startTime;
    expect(suggestionTime).toBeLessThan(500);
  });

  // 3D 렌더링 성능
  test('236. 3D 뇌지도 렌더링 FPS', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/brain-map`);

    const fps = await page.evaluate(() => {
      return new Promise<number>((resolve) => {
        let frames = 0;
        const startTime = performance.now();

        function countFrame() {
          frames++;
          if (performance.now() - startTime < 1000) {
            requestAnimationFrame(countFrame);
          } else {
            resolve(frames);
          }
        }

        requestAnimationFrame(countFrame);
      });
    });

    expect(fps).toBeGreaterThan(30); // Should maintain at least 30 FPS
  });

  test('237. 3D 모델 로딩 시간', async ({ page }) => {
    await loginAsUser(page);

    const startTime = Date.now();
    await page.goto(`${FRONTEND_URL}/brain-map`);
    await page.waitForSelector('.brain-model-loaded', { timeout: 10000 });

    const loadTime = Date.now() - startTime;
    expect(loadTime).toBeLessThan(5000);
  });

  test('238. 그래프 시각화 성능', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/knowledge-graph/large`);

    // Large graph with 500 nodes
    const startTime = Date.now();
    await page.waitForSelector('.graph-rendered', { timeout: 10000 });

    const renderTime = Date.now() - startTime;
    expect(renderTime).toBeLessThan(5000);

    // Check interaction performance
    const node = page.locator('.node').first();
    await node.hover();

    // Tooltip should appear quickly
    await expect(page.locator('.node-tooltip')).toBeVisible({ timeout: 100 });
  });

  test('239. 애니메이션 성능', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/dashboard`);

    // Trigger animation
    await page.click('button:has-text("통계 보기")');

    // Check animation smoothness
    const animationSmooth = await page.evaluate(() => {
      return new Promise<boolean>((resolve) => {
        let lastTime = performance.now();
        let frameTimes: number[] = [];

        function checkFrame() {
          const currentTime = performance.now();
          const deltaTime = currentTime - lastTime;
          frameTimes.push(deltaTime);
          lastTime = currentTime;

          if (frameTimes.length < 60) {
            requestAnimationFrame(checkFrame);
          } else {
            // Check if 95% of frames are under 20ms (50 FPS)
            const smoothFrames = frameTimes.filter(t => t < 20).length;
            resolve(smoothFrames / frameTimes.length > 0.95);
          }
        }

        requestAnimationFrame(checkFrame);
      });
    });

    expect(animationSmooth).toBeTruthy();
  });

  test('240. 무한 스크롤 성능', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/questions/infinite`);

    const scrollTimes: number[] = [];

    for (let i = 0; i < 5; i++) {
      const startTime = Date.now();

      await page.evaluate(() => {
        window.scrollTo(0, document.body.scrollHeight);
      });

      await page.waitForSelector(`.question-item:nth-child(${(i + 1) * 20})`, { timeout: 2000 });

      scrollTimes.push(Date.now() - startTime);
    }

    // Average load time for new content
    const avgTime = scrollTimes.reduce((a, b) => a + b, 0) / scrollTimes.length;
    expect(avgTime).toBeLessThan(1000);
  });

  // 데이터베이스 성능
  test('241. 데이터베이스 쿼리 최적화', async ({ page }) => {
    await loginAsUser(page);

    // Complex query with joins
    const response = await page.request.get(`${API_BASE}/analytics/complex`);

    const data = await response.json();
    expect(data.queryTime).toBeLessThan(1000); // Query should complete in under 1 second
  });

  test('242. 벡터 검색 성능', async ({ page }) => {
    await loginAsUser(page);

    const startTime = Date.now();

    const response = await page.request.post(`${API_BASE}/search/vector`, {
      data: {
        query: '네트워크 프로토콜과 OSI 7계층',
        limit: 100
      }
    });

    const searchTime = Date.now() - startTime;

    expect(response.status()).toBe(200);
    expect(searchTime).toBeLessThan(2000);
  });

  test('243. 그래프 데이터베이스 쿼리', async ({ page }) => {
    await loginAsUser(page);

    const startTime = Date.now();

    // Complex graph traversal
    const response = await page.request.post(`${API_BASE}/graph/traverse`, {
      data: {
        startNode: 'concept-1',
        depth: 5,
        includeRelationships: true
      }
    });

    const queryTime = Date.now() - startTime;

    expect(response.status()).toBe(200);
    expect(queryTime).toBeLessThan(3000);
  });

  test('244. 일괄 처리 성능', async ({ page }) => {
    await loginAsUser(page);

    const batchData = Array.from({ length: 100 }, (_, i) => ({
      id: i,
      data: `Item ${i}`
    }));

    const startTime = Date.now();

    const response = await page.request.post(`${API_BASE}/batch/process`, {
      data: { items: batchData }
    });

    const processTime = Date.now() - startTime;

    expect(response.status()).toBe(200);
    expect(processTime).toBeLessThan(5000);
  });

  test('245. 실시간 업데이트 지연', async ({ page, context }) => {
    await loginAsUser(page);

    const page2 = await context.newPage();
    await loginAsUser(page2);

    await page.goto(`${FRONTEND_URL}/collaboration`);
    await page2.goto(`${FRONTEND_URL}/collaboration`);

    const startTime = Date.now();

    // User 1 makes a change
    await page.fill('.collaborative-input', 'Test update');

    // User 2 should see the update
    await expect(page2.locator('.collaborative-input')).toHaveValue('Test update', { timeout: 1000 });

    const updateLatency = Date.now() - startTime;
    expect(updateLatency).toBeLessThan(1000);
  });

  // 모바일 성능
  test('246. 모바일 뷰포트 성능', async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 375, height: 667 },
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15'
    });

    const page = await context.newPage();

    const loadTime = await measureLoadTime(page, FRONTEND_URL);
    expect(loadTime).toBeLessThan(3000);

    await context.close();
  });

  test('247. 터치 인터랙션 응답성', async ({ browser }) => {
    const context = await browser.newContext({
      viewport: { width: 375, height: 667 },
      hasTouch: true
    });

    const page = await context.newPage();
    await page.goto(FRONTEND_URL);

    const startTime = Date.now();
    await page.tap('.mobile-menu-button');
    await page.waitForSelector('.mobile-menu', { state: 'visible' });

    const responseTime = Date.now() - startTime;
    expect(responseTime).toBeLessThan(300);

    await context.close();
  });

  test('248. 네트워크 대역폭 최적화', async ({ browser }) => {
    const context = await browser.newContext();
    const page = await context.newPage();

    // Monitor network requests
    const requests: any[] = [];
    page.on('request', request => {
      requests.push({
        url: request.url(),
        size: request.postDataBuffer()?.length || 0
      });
    });

    await page.goto(FRONTEND_URL);
    await page.waitForLoadState('networkidle');

    // Check total data transferred
    const totalSize = requests.reduce((sum, req) => sum + req.size, 0);
    expect(totalSize).toBeLessThan(5 * 1024 * 1024); // Less than 5MB

    await context.close();
  });

  test('249. 서비스 워커 캐싱', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Check service worker registration
    const hasServiceWorker = await page.evaluate(() => {
      return 'serviceWorker' in navigator;
    });

    expect(hasServiceWorker).toBeTruthy();

    // Wait for service worker to be ready
    await page.evaluate(() => {
      return navigator.serviceWorker.ready;
    });

    // Offline mode test
    await page.context().setOffline(true);

    // Should still load from cache
    await page.reload();
    await expect(page.locator('body')).toBeVisible();

    await page.context().setOffline(false);
  });

  test('250. 번들 사이즈 최적화', async ({ page }) => {
    const response = await page.request.get(`${FRONTEND_URL}/static/js/main.js`);

    const contentLength = response.headers()['content-length'];
    const sizeInKB = parseInt(contentLength) / 1024;

    expect(sizeInKB).toBeLessThan(500); // Main bundle should be under 500KB

    // Check if gzipped
    const encoding = response.headers()['content-encoding'];
    expect(encoding).toBe('gzip');
  });
});

// Load testing
test.describe('부하 테스트', () => {
  test('L01. 동시 사용자 100명 시뮬레이션', async ({ browser }) => {
    const contexts = [];
    const pages = [];

    // Create 100 concurrent users
    for (let i = 0; i < 100; i++) {
      const context = await browser.newContext();
      const page = await context.newPage();
      contexts.push(context);
      pages.push(page);
    }

    const startTime = Date.now();

    // All users access the site simultaneously
    await Promise.all(pages.map(page => page.goto(FRONTEND_URL)));

    const totalTime = Date.now() - startTime;

    // Should handle 100 users within 10 seconds
    expect(totalTime).toBeLessThan(10000);

    // Clean up
    await Promise.all(contexts.map(context => context.close()));
  });

  test('L02. 스파이크 트래픽 처리', async ({ page }) => {
    const requests = [];

    // Generate 1000 requests in 10 seconds
    for (let i = 0; i < 1000; i++) {
      requests.push(
        page.request.get(`${API_BASE}/health`).catch(() => null)
      );

      if (i % 100 === 0) {
        await page.waitForTimeout(1000); // 100 requests per second
      }
    }

    const responses = await Promise.all(requests);
    const successfulRequests = responses.filter(r => r && r.status() === 200).length;

    // At least 95% should succeed
    expect(successfulRequests / responses.length).toBeGreaterThan(0.95);
  });
});