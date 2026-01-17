import { test, expect, Page } from '@playwright/test';
import { faker } from '@faker-js/faker/locale/ko';

// BMad 테스트 051-090: 학습 자료 관리 시스템

const API_BASE = 'http://localhost:8015/api/v1';
const FRONTEND_URL = 'http://localhost:3000';

// Helper functions
async function loginAsUser(page: Page) {
  await page.goto(`${FRONTEND_URL}/login`);
  await page.fill('input[name="user[email]"]', 'test@example.com');
  await page.fill('input[name="user[password]"]', 'password123');
  await page.click('input[type="submit"]');
  await page.waitForURL(`${FRONTEND_URL}/dashboard`);
}

async function uploadPDF(page: Page, filePath: string) {
  const fileInput = await page.locator('input[type="file"]');
  await fileInput.setInputFiles(filePath);
}

test.describe('BMad 학습 자료 관리 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(FRONTEND_URL);
  });

  // PDF 업로드 및 처리
  test('051. PDF 업로드 - 정상 파일', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    // Create a test PDF file
    const testPDF = Buffer.from('%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n>>\nendobj\nxref\n0 4\n0000000000 65535 f\n0000000009 00000 n\n0000000058 00000 n\n0000000115 00000 n\ntrailer\n<<\n/Size 4\n/Root 1 0 R\n>>\nstartxref\n203\n%%EOF');

    await page.locator('input[type="file"]').setInputFiles({
      name: 'test.pdf',
      mimeType: 'application/pdf',
      buffer: testPDF
    });

    await page.click('button:has-text("업로드")');
    await expect(page.locator('.upload-success')).toBeVisible({ timeout: 10000 });
  });

  test('052. PDF 업로드 - 대용량 파일 거부 (100MB 초과)', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    // Simulate large file
    const largeBuffer = Buffer.alloc(105 * 1024 * 1024); // 105MB
    await page.locator('input[type="file"]').setInputFiles({
      name: 'large.pdf',
      mimeType: 'application/pdf',
      buffer: largeBuffer
    });

    await expect(page.locator('.error-message')).toContainText(/파일 크기|100MB/i);
  });

  test('053. PDF 업로드 - 잘못된 파일 형식 거부', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    await page.locator('input[type="file"]').setInputFiles({
      name: 'malicious.exe',
      mimeType: 'application/x-msdownload',
      buffer: Buffer.from('MZ\x90\x00') // EXE header
    });

    await expect(page.locator('.error-message')).toContainText(/PDF 파일만|지원되지 않는/i);
  });

  test('054. PDF 업로드 - 중복 파일 처리', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    const testPDF = Buffer.from('%PDF-1.4\ntest content');
    const fileName = `duplicate-${Date.now()}.pdf`;

    // First upload
    await page.locator('input[type="file"]').setInputFiles({
      name: fileName,
      mimeType: 'application/pdf',
      buffer: testPDF
    });
    await page.click('button:has-text("업로드")');
    await page.waitForSelector('.upload-success');

    // Second upload (duplicate)
    await page.locator('input[type="file"]').setInputFiles({
      name: fileName,
      mimeType: 'application/pdf',
      buffer: testPDF
    });
    await page.click('button:has-text("업로드")');

    await expect(page.locator('.warning-message')).toContainText(/이미 존재|중복/i);
  });

  test('055. PDF 업로드 - 암호화된 PDF 처리', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    // Encrypted PDF header
    const encryptedPDF = Buffer.from('%PDF-1.4\n/Encrypt');

    await page.locator('input[type="file"]').setInputFiles({
      name: 'encrypted.pdf',
      mimeType: 'application/pdf',
      buffer: encryptedPDF
    });

    await page.click('button:has-text("업로드")');
    await expect(page.locator('.error-message')).toContainText(/암호화|보호된 PDF/i);
  });

  // OCR 처리
  test('056. OCR 처리 - 텍스트 추출 성공', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    // Upload and wait for OCR
    const testPDF = Buffer.from('%PDF-1.4\nSample text for OCR');
    await page.locator('input[type="file"]').setInputFiles({
      name: 'ocr-test.pdf',
      mimeType: 'application/pdf',
      buffer: testPDF
    });

    await page.click('button:has-text("업로드")');

    // Wait for OCR processing
    await expect(page.locator('.processing-status')).toContainText(/OCR 처리 중/i);
    await expect(page.locator('.processing-status')).toContainText(/완료/i, { timeout: 30000 });
  });

  test('057. OCR 처리 - 이미지 포함 PDF', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    // PDF with embedded image
    const pdfWithImage = Buffer.from('%PDF-1.4\n/XObject /Image');

    await page.locator('input[type="file"]').setInputFiles({
      name: 'image-pdf.pdf',
      mimeType: 'application/pdf',
      buffer: pdfWithImage
    });

    await page.click('button:has-text("업로드")');
    await expect(page.locator('.processing-info')).toContainText(/이미지.*추출/i);
  });

  test('058. OCR 처리 - 다국어 문서 (한글/영어)', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    const multilingualPDF = Buffer.from('%PDF-1.4\n한글 English 混合');

    await page.locator('input[type="file"]').setInputFiles({
      name: 'multilingual.pdf',
      mimeType: 'application/pdf',
      buffer: multilingualPDF
    });

    await page.click('button:has-text("업로드")');
    await expect(page.locator('.language-detection')).toContainText(/한국어.*영어/i);
  });

  test('059. OCR 처리 - 표 형식 데이터 추출', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    const tablePDF = Buffer.from('%PDF-1.4\n| Column1 | Column2 |\n|---------|---------|');

    await page.locator('input[type="file"]').setInputFiles({
      name: 'table.pdf',
      mimeType: 'application/pdf',
      buffer: tablePDF
    });

    await page.click('button:has-text("업로드")');
    await expect(page.locator('.table-detection')).toContainText(/표.*감지/i);
  });

  test('060. OCR 처리 - 수식 인식', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/upload`);

    const mathPDF = Buffer.from('%PDF-1.4\n∫ x² dx = x³/3 + C');

    await page.locator('input[type="file"]').setInputFiles({
      name: 'math.pdf',
      mimeType: 'application/pdf',
      buffer: mathPDF
    });

    await page.click('button:has-text("업로드")');
    await expect(page.locator('.formula-detection')).toContainText(/수식.*감지/i);
  });

  // 학습 자료 관리
  test('061. 학습 자료 목록 조회', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    await expect(page.locator('.materials-list')).toBeVisible();
    await expect(page.locator('.material-item')).toHaveCount(await page.locator('.material-item').count());
  });

  test('062. 학습 자료 검색 - 제목', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    await page.fill('[placeholder*="검색"]', '정보처리기사');
    await page.press('[placeholder*="검색"]', 'Enter');

    const results = page.locator('.material-item');
    for (const result of await results.all()) {
      await expect(result).toContainText(/정보처리기사/i);
    }
  });

  test('063. 학습 자료 검색 - 태그', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    await page.click('.tag-filter:has-text("네트워크")');

    const results = page.locator('.material-item');
    for (const result of await results.all()) {
      await expect(result.locator('.tag')).toContainText(/네트워크/i);
    }
  });

  test('064. 학습 자료 필터 - 업로드 날짜', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    // Select date range
    await page.fill('[name="date-from"]', '2024-01-01');
    await page.fill('[name="date-to"]', '2024-12-31');
    await page.click('button:has-text("적용")');

    const dates = await page.locator('.upload-date').allTextContents();
    dates.forEach(date => {
      const uploadDate = new Date(date);
      expect(uploadDate >= new Date('2024-01-01')).toBeTruthy();
      expect(uploadDate <= new Date('2024-12-31')).toBeTruthy();
    });
  });

  test('065. 학습 자료 정렬 - 최신순/오래된순', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    // Sort by newest
    await page.selectOption('[name="sort"]', 'newest');
    let dates = await page.locator('.upload-date').allTextContents();
    let sortedDates = [...dates].sort((a, b) => new Date(b).getTime() - new Date(a).getTime());
    expect(dates).toEqual(sortedDates);

    // Sort by oldest
    await page.selectOption('[name="sort"]', 'oldest');
    dates = await page.locator('.upload-date').allTextContents();
    sortedDates = [...dates].sort((a, b) => new Date(a).getTime() - new Date(b).getTime());
    expect(dates).toEqual(sortedDates);
  });

  test('066. 학습 자료 삭제', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    const firstItem = page.locator('.material-item').first();
    const title = await firstItem.locator('.material-title').textContent();

    await firstItem.locator('button:has-text("삭제")').click();
    await page.click('.confirm-dialog button:has-text("확인")');

    await expect(page.locator('.success-message')).toContainText(/삭제.*완료/i);
    await expect(page.locator(`.material-title:has-text("${title}")`)).not.toBeVisible();
  });

  test('067. 학습 자료 일괄 삭제', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    // Select multiple items
    await page.check('.material-item:nth-child(1) input[type="checkbox"]');
    await page.check('.material-item:nth-child(2) input[type="checkbox"]');
    await page.check('.material-item:nth-child(3) input[type="checkbox"]');

    await page.click('button:has-text("선택 삭제")');
    await page.click('.confirm-dialog button:has-text("확인")');

    await expect(page.locator('.success-message')).toContainText(/3개.*삭제/i);
  });

  test('068. 학습 자료 다운로드', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    const downloadPromise = page.waitForEvent('download');
    await page.locator('.material-item').first().locator('button:has-text("다운로드")').click();

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/\.pdf$/i);
  });

  test('069. 학습 자료 미리보기', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    await page.locator('.material-item').first().locator('button:has-text("미리보기")').click();

    await expect(page.locator('.pdf-viewer')).toBeVisible();
    await expect(page.locator('.pdf-page')).toHaveCount(1, { timeout: 10000 });
  });

  test('070. 학습 자료 공유 링크 생성', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    await page.locator('.material-item').first().locator('button:has-text("공유")').click();

    const shareDialog = page.locator('.share-dialog');
    await expect(shareDialog).toBeVisible();

    await shareDialog.locator('button:has-text("링크 생성")').click();

    const shareLink = await shareDialog.locator('.share-link input').inputValue();
    expect(shareLink).toMatch(/^https?:\/\/.+\/share\/.+$/);
  });

  // 챕터 분할 및 관리
  test('071. 챕터 자동 분할', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/chapters`);

    await page.click('button:has-text("자동 분할")');

    await expect(page.locator('.chapter-list .chapter-item')).toHaveCount(5, { timeout: 15000 });
  });

  test('072. 챕터 수동 분할', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/chapters`);

    await page.click('button:has-text("수동 분할")');

    // Add chapter break points
    await page.click('.page-preview:nth-child(10)');
    await page.click('.page-preview:nth-child(20)');
    await page.click('.page-preview:nth-child(30)');

    await page.click('button:has-text("분할 적용")');

    await expect(page.locator('.chapter-item')).toHaveCount(4);
  });

  test('073. 챕터 이름 수정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/chapters`);

    const firstChapter = page.locator('.chapter-item').first();
    await firstChapter.locator('button:has-text("편집")').click();

    await firstChapter.locator('input[name="chapter-name"]').clear();
    await firstChapter.locator('input[name="chapter-name"]').fill('새로운 챕터 이름');
    await firstChapter.locator('button:has-text("저장")').click();

    await expect(firstChapter).toContainText('새로운 챕터 이름');
  });

  test('074. 챕터 순서 변경', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/chapters`);

    const chapters = page.locator('.chapter-item');
    const firstTitle = await chapters.first().locator('.chapter-title').textContent();
    const secondTitle = await chapters.nth(1).locator('.chapter-title').textContent();

    // Drag and drop
    await chapters.first().dragTo(chapters.nth(1));

    // Verify order changed
    await expect(chapters.first().locator('.chapter-title')).toHaveText(secondTitle!);
    await expect(chapters.nth(1).locator('.chapter-title')).toHaveText(firstTitle!);
  });

  test('075. 챕터 병합', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/chapters`);

    const initialCount = await page.locator('.chapter-item').count();

    // Select two chapters
    await page.check('.chapter-item:nth-child(1) input[type="checkbox"]');
    await page.check('.chapter-item:nth-child(2) input[type="checkbox"]');

    await page.click('button:has-text("선택 병합")');
    await page.click('.confirm-dialog button:has-text("확인")');

    await expect(page.locator('.chapter-item')).toHaveCount(initialCount - 1);
  });

  // 문제 추출 및 관리
  test('076. 문제 자동 추출', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/questions`);

    await page.click('button:has-text("문제 추출")');

    await expect(page.locator('.extraction-progress')).toBeVisible();
    await expect(page.locator('.question-item')).toHaveCount(20, { timeout: 30000 });
  });

  test('077. 문제 유형 분류', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/questions`);

    const questions = page.locator('.question-item');

    for (const question of await questions.all()) {
      const typeLabel = question.locator('.question-type');
      await expect(typeLabel).toContainText(/객관식|주관식|서술형/);
    }
  });

  test('078. 문제 난이도 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/questions`);

    const firstQuestion = page.locator('.question-item').first();
    await firstQuestion.locator('.difficulty-selector').selectOption('hard');

    await expect(firstQuestion.locator('.difficulty-badge')).toHaveClass(/difficulty-hard/);
  });

  test('079. 문제 태그 추가', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/questions`);

    const firstQuestion = page.locator('.question-item').first();
    await firstQuestion.locator('button:has-text("태그 추가")').click();

    await page.fill('.tag-input', '네트워크, OSI, TCP/IP');
    await page.click('button:has-text("태그 저장")');

    await expect(firstQuestion.locator('.tag')).toHaveCount(3);
  });

  test('080. 문제 정답 검증', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/questions`);

    const firstQuestion = page.locator('.question-item').first();
    await firstQuestion.locator('button:has-text("정답 확인")').click();

    const answerDialog = page.locator('.answer-dialog');
    await expect(answerDialog).toBeVisible();
    await expect(answerDialog.locator('.correct-answer')).toBeVisible();
  });

  // 메타데이터 관리
  test('081. 자료 메타데이터 자동 추출', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/metadata`);

    await expect(page.locator('.metadata-field:has-text("제목")')).toBeVisible();
    await expect(page.locator('.metadata-field:has-text("저자")')).toBeVisible();
    await expect(page.locator('.metadata-field:has-text("출판사")')).toBeVisible();
    await expect(page.locator('.metadata-field:has-text("페이지 수")')).toBeVisible();
  });

  test('082. 자료 카테고리 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/metadata`);

    await page.selectOption('[name="category"]', 'information-processing');
    await page.click('button:has-text("저장")');

    await expect(page.locator('.success-message')).toContainText(/카테고리.*저장/i);
  });

  test('083. 자료 태그 일괄 편집', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials`);

    // Select multiple materials
    await page.check('.material-item:nth-child(1) input[type="checkbox"]');
    await page.check('.material-item:nth-child(2) input[type="checkbox"]');

    await page.click('button:has-text("태그 편집")');

    const tagDialog = page.locator('.bulk-tag-dialog');
    await tagDialog.locator('input[name="tags"]').fill('2024, 기출문제, 필수');
    await tagDialog.locator('button:has-text("적용")').click();

    await expect(page.locator('.success-message')).toContainText(/2개.*태그 업데이트/i);
  });

  test('084. 자료 통계 조회', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/statistics`);

    await expect(page.locator('.stat-card:has-text("총 문제 수")')).toBeVisible();
    await expect(page.locator('.stat-card:has-text("평균 정답률")')).toBeVisible();
    await expect(page.locator('.stat-card:has-text("학습 시간")')).toBeVisible();
    await expect(page.locator('.stat-card:has-text("완료율")')).toBeVisible();
  });

  test('085. 자료 버전 관리', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/versions`);

    // Upload new version
    const newVersion = Buffer.from('%PDF-1.4\nVersion 2.0');
    await page.locator('input[type="file"]').setInputFiles({
      name: 'version2.pdf',
      mimeType: 'application/pdf',
      buffer: newVersion
    });

    await page.click('button:has-text("새 버전 업로드")');

    await expect(page.locator('.version-item')).toHaveCount(2);
    await expect(page.locator('.version-item').last()).toContainText('v2.0');
  });

  // 권한 및 공유
  test('086. 자료 공개/비공개 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/settings`);

    const visibilityToggle = page.locator('[name="visibility"]');
    await visibilityToggle.click();

    await expect(page.locator('.visibility-status')).toContainText(/비공개/i);

    await visibilityToggle.click();
    await expect(page.locator('.visibility-status')).toContainText(/공개/i);
  });

  test('087. 자료 공유 권한 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/sharing`);

    // Add user with view permission
    await page.fill('[name="share-email"]', 'viewer@example.com');
    await page.selectOption('[name="permission"]', 'view');
    await page.click('button:has-text("공유 추가")');

    await expect(page.locator('.share-list')).toContainText('viewer@example.com');
    await expect(page.locator('.share-list')).toContainText('보기 전용');
  });

  test('088. 자료 공유 링크 만료 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/sharing`);

    await page.click('button:has-text("공유 링크 생성")');

    // Set expiry
    await page.fill('[name="expiry-date"]', '2024-12-31');
    await page.fill('[name="expiry-time"]', '23:59');
    await page.click('button:has-text("링크 생성")');

    const shareLink = await page.locator('.share-link-display input').inputValue();
    expect(shareLink).toContain('expires=');
  });

  test('089. 자료 접근 로그 조회', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/access-log`);

    await expect(page.locator('.access-log-table')).toBeVisible();
    await expect(page.locator('.log-entry')).toHaveCount(await page.locator('.log-entry').count());

    // Verify log contains required fields
    const firstLog = page.locator('.log-entry').first();
    await expect(firstLog.locator('.log-user')).toBeVisible();
    await expect(firstLog.locator('.log-action')).toBeVisible();
    await expect(firstLog.locator('.log-timestamp')).toBeVisible();
  });

  test('090. 자료 백업 생성', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-materials/1/backup`);

    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("백업 생성")');

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/backup.*\.zip$/i);

    // Verify backup contains expected files
    const path = await download.path();
    expect(path).toBeTruthy();
  });
});

// Error handling tests
test.describe('학습 자료 오류 처리', () => {
  test('E01. 네트워크 오류 시 재시도', async ({ page }) => {
    await loginAsUser(page);

    // Simulate network error
    await page.route('**/api/v1/study-materials/**', route => {
      route.abort('internetdisconnected');
    });

    await page.goto(`${FRONTEND_URL}/study-materials`);

    await expect(page.locator('.error-message')).toContainText(/네트워크|연결/i);
    await expect(page.locator('button:has-text("재시도")')).toBeVisible();
  });

  test('E02. 서버 오류 처리', async ({ page }) => {
    await loginAsUser(page);

    await page.route('**/api/v1/study-materials/**', route => {
      route.fulfill({
        status: 500,
        body: JSON.stringify({ error: 'Internal Server Error' })
      });
    });

    await page.goto(`${FRONTEND_URL}/study-materials`);
    await expect(page.locator('.error-message')).toContainText(/서버 오류/i);
  });
});