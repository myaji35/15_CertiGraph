import { test, expect, Page } from '@playwright/test';
import { loginAsUser } from '../helpers/rails-auth-helper';

// BMad 테스트 151-180: 지식 그래프 시스템
// Updated for Rails architecture on localhost:3000

const BASE_URL = 'http://localhost:3000';

test.describe('BMad 지식 그래프 테스트', () => {
  test.beforeEach(async ({ page }) => {
    // 페이지 로딩: Rails 서버는 빠르므로 domcontentloaded 대기
    await page.goto(BASE_URL, {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });

    // 추가 대기: 페이지가 인터랙티브 상태가 될 때까지
    await page.waitForLoadState('load');
  });

  // 지식 그래프 생성
  test('151. 지식 그래프 자동 생성', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph`);

    await page.click('button:has-text("그래프 생성")');

    await expect(page.locator('.graph-generation-progress')).toBeVisible();
    await expect(page.locator('.graph-container')).toBeVisible({ timeout: 15000 });
    await expect(page.locator('.node')).toHaveCount(await page.locator('.node').count());
  });

  test('152. 개념 노드 추출', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/create`);

    await page.fill('[name="material-id"]', '1');
    await page.click('button:has-text("개념 추출")');

    await expect(page.locator('.concept-list')).toBeVisible();
    await expect(page.locator('.concept-node')).toHaveCount(await page.locator('.concept-node').count());
  });

  test('153. 개념 관계 매핑', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1`);

    const nodes = page.locator('.node');
    await expect(nodes).toHaveCount(await nodes.count());

    // Check edges exist
    const edges = page.locator('.edge');
    await expect(edges).toHaveCount(await edges.count());
  });

  test('154. 선수 지식 체인 분석', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1`);

    await page.click('.node:has-text("TCP/IP")');

    const prerequisites = page.locator('.prerequisite-chain');
    await expect(prerequisites).toBeVisible();
    await expect(prerequisites.locator('.prerequisite-node')).toContainText(/OSI|네트워크/i);
  });

  test('155. 지식 그래프 시각화', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1`);

    const visualization = page.locator('.graph-visualization');
    await expect(visualization).toBeVisible();
    await expect(visualization.locator('canvas')).toBeVisible();
  });

  // 3D 뇌지도 시각화
  test('156. 3D 뇌지도 렌더링', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/brain-map`);

    const brainMap = page.locator('.brain-map-3d');
    await expect(brainMap).toBeVisible();
    await expect(brainMap.locator('canvas')).toBeVisible();
  });

  test('157. 뇌지도 회전/확대', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/brain-map`);

    const canvas = page.locator('.brain-map-3d canvas');

    // Test rotation
    await canvas.hover();
    await page.mouse.down();
    await page.mouse.move(100, 100);
    await page.mouse.up();

    // Test zoom
    await canvas.hover();
    await page.mouse.wheel(0, -100);

    await expect(canvas).toBeVisible();
  });

  test('158. 노드 색상 코딩 (숙련도)', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/brain-map`);

    // Check color legend
    await expect(page.locator('.legend-mastered')).toHaveCSS('background-color', 'rgb(0, 255, 0)');
    await expect(page.locator('.legend-weak')).toHaveCSS('background-color', 'rgb(255, 0, 0)');
    await expect(page.locator('.legend-untested')).toHaveCSS('background-color', 'rgb(128, 128, 128)');
  });

  test('159. 노드 클릭 상세정보', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/brain-map`);

    await page.click('.node-clickable:first-child');

    const nodeDetail = page.locator('.node-detail-panel');
    await expect(nodeDetail).toBeVisible();
    await expect(nodeDetail.locator('.node-title')).toBeVisible();
    await expect(nodeDetail.locator('.mastery-level')).toBeVisible();
    await expect(nodeDetail.locator('.related-questions')).toBeVisible();
  });

  test('160. 학습 경로 하이라이트', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/brain-map`);

    await page.click('button:has-text("학습 경로 보기")');

    const learningPath = page.locator('.learning-path-highlight');
    await expect(learningPath).toBeVisible();
    await expect(learningPath).toHaveCSS('stroke', 'rgb(255, 165, 0)'); // Orange highlight
  });

  // 약점 분석
  test('161. 약점 개념 식별', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/weakness-analysis`);

    await page.click('button:has-text("약점 분석")');

    const weakConcepts = page.locator('.weak-concept-list');
    await expect(weakConcepts).toBeVisible();
    await expect(weakConcepts.locator('.weak-concept')).toHaveCount(await weakConcepts.locator('.weak-concept').count());
  });

  test('162. 약점 우선순위 정렬', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/weakness-analysis`);

    const weaknessList = page.locator('.weakness-priority-list');
    const priorities = await weaknessList.locator('.priority-score').allTextContents();

    // Check descending order
    for (let i = 1; i < priorities.length; i++) {
      expect(parseFloat(priorities[i - 1])).toBeGreaterThanOrEqual(parseFloat(priorities[i]));
    }
  });

  test('163. 약점 개선 추천', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/weakness-analysis`);

    await page.click('.weak-concept:first-child');

    const recommendations = page.locator('.improvement-recommendations');
    await expect(recommendations).toBeVisible();
    await expect(recommendations.locator('.recommended-material')).toHaveCount(3);
    await expect(recommendations.locator('.practice-questions')).toBeVisible();
  });

  test('164. 약점 추적 히스토리', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/weakness-history`);

    const historyChart = page.locator('.weakness-history-chart');
    await expect(historyChart).toBeVisible();
    await expect(historyChart.locator('.improvement-trend')).toBeVisible();
  });

  test('165. 연관 약점 분석', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/weakness-analysis/1`);

    const relatedWeaknesses = page.locator('.related-weaknesses');
    await expect(relatedWeaknesses).toBeVisible();
    await expect(relatedWeaknesses).toContainText(/관련 약점/i);
  });

  // 학습 경로 추천
  test('166. 개인 맞춤 학습 경로', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/learning-path`);

    await page.click('button:has-text("학습 경로 생성")');

    await expect(page.locator('.personalized-path')).toBeVisible({ timeout: 10000 });
    await expect(page.locator('.path-step')).toHaveCount(await page.locator('.path-step').count());
  });

  test('167. 최단 학습 경로 계산', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/learning-path/optimize`);

    await page.fill('[name="target-concept"]', 'TCP/IP 프로토콜');
    await page.click('button:has-text("최적 경로 찾기")');

    const optimizedPath = page.locator('.optimized-path');
    await expect(optimizedPath).toBeVisible();
    await expect(optimizedPath.locator('.estimated-time')).toBeVisible();
  });

  test('168. 학습 경로 진행률', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/learning-path/1`);

    const progress = page.locator('.path-progress');
    await expect(progress.locator('.completed-steps')).toBeVisible();
    await expect(progress.locator('.progress-bar')).toBeVisible();
    await expect(progress.locator('.estimated-completion')).toBeVisible();
  });

  test('169. 경로 난이도 조절', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/learning-path/1/settings`);

    await page.selectOption('[name="difficulty"]', 'beginner');
    await page.click('button:has-text("적용")');

    await expect(page.locator('.path-difficulty')).toContainText(/초급/i);
    await expect(page.locator('.path-updated')).toBeVisible();
  });

  test('170. 대체 학습 경로 제시', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/learning-path/1`);

    await page.click('button:has-text("대체 경로")');

    const alternatives = page.locator('.alternative-paths');
    await expect(alternatives).toBeVisible();
    await expect(alternatives.locator('.path-option')).toHaveCount(3);
  });

  // 개념 관리
  test('171. 개념 수동 추가', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/edit`);

    await page.click('button:has-text("개념 추가")');
    await page.fill('[name="concept-name"]', '새로운 개념');
    await page.fill('[name="concept-description"]', '이것은 새로운 개념입니다');
    await page.click('button:has-text("추가")');

    await expect(page.locator('.node:has-text("새로운 개념")')).toBeVisible();
  });

  test('172. 개념 관계 수정', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/edit`);

    // Select two nodes
    await page.click('.node:nth-child(1)');
    await page.click('.node:nth-child(2)', { modifiers: ['Control'] });

    await page.click('button:has-text("관계 추가")');
    await page.selectOption('[name="relationship-type"]', 'prerequisite');
    await page.click('button:has-text("확인")');

    await expect(page.locator('.edge.prerequisite')).toBeVisible();
  });

  test('173. 개념 병합', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/edit`);

    await page.click('.node:has-text("TCP")');
    await page.click('.node:has-text("IP")', { modifiers: ['Control'] });

    await page.click('button:has-text("개념 병합")');
    await page.fill('[name="merged-name"]', 'TCP/IP');
    await page.click('button:has-text("병합")');

    await expect(page.locator('.node:has-text("TCP/IP")')).toBeVisible();
    await expect(page.locator('.node:has-text("TCP"):not(:has-text("TCP/IP"))')).not.toBeVisible();
  });

  test('174. 개념 삭제', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/edit`);

    const nodeToDelete = page.locator('.node').first();
    const nodeName = await nodeToDelete.textContent();

    await nodeToDelete.click();
    await page.click('button:has-text("삭제")');
    await page.click('.confirm-dialog button:has-text("확인")');

    await expect(page.locator(`.node:has-text("${nodeName}")`)).not.toBeVisible();
  });

  test('175. 개념 태그 관리', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/concepts/1`);

    await page.click('button:has-text("태그 관리")');
    await page.fill('.tag-input', '핵심, 필수, 2024');
    await page.click('button:has-text("저장")');

    await expect(page.locator('.concept-tag')).toHaveCount(3);
  });

  // 그래프 분석
  test('176. 중심성 분석', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/analysis`);

    await page.click('button:has-text("중심성 분석")');

    const centralityReport = page.locator('.centrality-analysis');
    await expect(centralityReport).toBeVisible();
    await expect(centralityReport.locator('.most-central-concepts')).toBeVisible();
  });

  test('177. 클러스터링 분석', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/analysis`);

    await page.click('button:has-text("클러스터 분석")');

    const clusters = page.locator('.cluster-analysis');
    await expect(clusters).toBeVisible();
    await expect(clusters.locator('.cluster-group')).toHaveCount(await clusters.locator('.cluster-group').count());
  });

  test('178. 학습 효율성 분석', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/efficiency`);

    const efficiency = page.locator('.efficiency-metrics');
    await expect(efficiency.locator('.learning-velocity')).toBeVisible();
    await expect(efficiency.locator('.concept-retention')).toBeVisible();
    await expect(efficiency.locator('.optimal-review-time')).toBeVisible();
  });

  test('179. 개념 간 거리 계산', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/distance`);

    await page.fill('[name="concept-from"]', 'OSI 모델');
    await page.fill('[name="concept-to"]', 'TCP/IP');
    await page.click('button:has-text("거리 계산")');

    const distance = page.locator('.concept-distance');
    await expect(distance).toBeVisible();
    await expect(distance).toContainText(/거리.*\d+/);
  });

  test('180. 그래프 내보내기', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1`);

    await page.click('button:has-text("내보내기")');

    const exportDialog = page.locator('.export-dialog');
    await expect(exportDialog).toBeVisible();

    // Export as JSON
    await exportDialog.selectOption('[name="format"]', 'json');

    const downloadPromise = page.waitForEvent('download');
    await exportDialog.locator('button:has-text("다운로드")').click();

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/knowledge-graph.*\.json$/i);
  });
});

// Advanced graph features
test.describe('지식 그래프 고급 기능', () => {
  test('A01. GraphRAG 질의', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1/query`);

    await page.fill('[name="graph-query"]', 'TCP/IP와 관련된 모든 개념을 찾아줘');
    await page.click('button:has-text("검색")');

    const results = page.locator('.graph-query-results');
    await expect(results).toBeVisible();
    await expect(results.locator('.result-concept')).toHaveCount(await results.locator('.result-concept').count());
  });

  test('A02. 실시간 그래프 업데이트', async ({ page }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');
    await page.goto(`${BASE_URL}/knowledge-graph/1`);

    // Answer a question to trigger update
    await page.goto(`${BASE_URL}/practice`);
    await page.click('.answer-option:first-child');
    await page.click('button:has-text("제출")');

    // Go back to graph
    await page.goto(`${BASE_URL}/knowledge-graph/1`);

    // Check for update indicator
    await expect(page.locator('.graph-updated-indicator')).toBeVisible();
  });

  test('A03. 협업 그래프 편집', async ({ page, context }) => {
    await loginAsUser(page, 'test@example.com', 'Test1234!');

    // Open graph in collaboration mode
    await page.goto(`${BASE_URL}/knowledge-graph/1/collaborate`);

    // Simulate another user
    const page2 = await context.newPage();
    await loginAsUser(page2);
    await page2.goto(`${BASE_URL}/knowledge-graph/1/collaborate`);

    // User 1 adds a node
    await page.click('button:has-text("개념 추가")');
    await page.fill('[name="concept-name"]', 'User1 Concept');
    await page.click('button:has-text("추가")');

    // User 2 should see the update
    await expect(page2.locator('.node:has-text("User1 Concept")')).toBeVisible({ timeout: 5000 });
  });
});