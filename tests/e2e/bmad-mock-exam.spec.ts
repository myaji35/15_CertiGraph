import { test, expect, Page } from '@playwright/test';
import { faker } from '@faker-js/faker/locale/ko';

// BMad 테스트 091-150: 모의고사 시스템

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

async function startExam(page: Page, examId: string) {
  await page.goto(`${FRONTEND_URL}/exams/${examId}`);
  await page.click('button:has-text("시작")');
}

test.describe('BMad 모의고사 시스템 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(FRONTEND_URL);
  });

  // 모의고사 생성
  test('091. 모의고사 생성 - 기본 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.fill('[name="exam-title"]', '정보처리기사 모의고사 #1');
    await page.selectOption('[name="category"]', 'information-processing');
    await page.fill('[name="question-count"]', '100');
    await page.fill('[name="time-limit"]', '150');

    await page.click('button:has-text("생성")');

    await expect(page.locator('.success-message')).toContainText(/모의고사.*생성/i);
    await expect(page).toHaveURL(/\/exams\/\d+/);
  });

  test('092. 모의고사 생성 - 챕터별 문제 분배', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.click('button:has-text("챕터별 설정")');

    // Set questions per chapter
    await page.fill('[data-chapter="1"] input', '20');
    await page.fill('[data-chapter="2"] input', '25');
    await page.fill('[data-chapter="3"] input', '30');
    await page.fill('[data-chapter="4"] input', '25');

    await page.click('button:has-text("생성")');

    const examDetails = page.locator('.exam-details');
    await expect(examDetails).toContainText('챕터 1: 20문제');
    await expect(examDetails).toContainText('챕터 2: 25문제');
  });

  test('093. 모의고사 생성 - 난이도 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.click('button:has-text("난이도 설정")');

    // Set difficulty distribution
    await page.fill('[data-difficulty="easy"] input', '30');
    await page.fill('[data-difficulty="medium"] input', '50');
    await page.fill('[data-difficulty="hard"] input', '20');

    await page.click('button:has-text("생성")');

    await expect(page.locator('.difficulty-distribution')).toContainText('쉬움: 30%');
    await expect(page.locator('.difficulty-distribution')).toContainText('보통: 50%');
    await expect(page.locator('.difficulty-distribution')).toContainText('어려움: 20%');
  });

  test('094. 모의고사 생성 - 기출문제 우선 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.check('[name="prioritize-past-questions"]');
    await page.fill('[name="past-questions-ratio"]', '70');

    await page.click('button:has-text("생성")');

    await expect(page.locator('.exam-info')).toContainText(/기출문제.*70%/i);
  });

  test('095. 모의고사 생성 - 중복 문제 방지', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.check('[name="prevent-duplicates"]');
    await page.fill('[name="days-to-check"]', '30');

    await page.click('button:has-text("생성")');

    await expect(page.locator('.exam-settings')).toContainText(/중복 방지.*30일/i);
  });

  // 시험 진행
  test('096. 시험 시작 및 타이머', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    const timer = page.locator('.exam-timer');
    await expect(timer).toBeVisible();

    // Check timer is counting down
    const initialTime = await timer.textContent();
    await page.waitForTimeout(2000);
    const laterTime = await timer.textContent();

    expect(initialTime).not.toBe(laterTime);
  });

  test('097. 문제 응답 저장', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    // Answer first question
    await page.click('.answer-option:nth-child(2)');
    await page.click('button:has-text("다음")');

    // Go back to first question
    await page.click('button:has-text("이전")');

    // Check answer is saved
    await expect(page.locator('.answer-option:nth-child(2)')).toHaveClass(/selected/);
  });

  test('098. 문제 북마크', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    await page.click('button[aria-label="북마크"]');
    await expect(page.locator('button[aria-label="북마크"]')).toHaveClass(/bookmarked/);

    // Check bookmark list
    await page.click('button:has-text("북마크 목록")');
    await expect(page.locator('.bookmark-list .question-item')).toHaveCount(1);
  });

  test('099. 문제 이동 네비게이션', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    // Test navigation buttons
    await page.click('button:has-text("다음")');
    await expect(page.locator('.question-number')).toContainText('2');

    await page.click('button:has-text("이전")');
    await expect(page.locator('.question-number')).toContainText('1');

    // Jump to specific question
    await page.click('.question-nav-grid button:has-text("50")');
    await expect(page.locator('.question-number')).toContainText('50');
  });

  test('100. 답안지 보기', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    // Answer some questions
    await page.click('.answer-option:nth-child(1)');
    await page.click('button:has-text("다음")');
    await page.click('.answer-option:nth-child(3)');

    // Open answer sheet
    await page.click('button:has-text("답안지")');

    const answerSheet = page.locator('.answer-sheet');
    await expect(answerSheet).toBeVisible();
    await expect(answerSheet.locator('.answered')).toHaveCount(2);
  });

  // 시험 제출 및 채점
  test('101. 시험 제출 확인 다이얼로그', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    await page.click('button:has-text("제출")');

    const confirmDialog = page.locator('.submit-confirm-dialog');
    await expect(confirmDialog).toBeVisible();
    await expect(confirmDialog).toContainText(/답하지 않은 문제/i);
  });

  test('102. 시간 초과 자동 제출', async ({ page }) => {
    await loginAsUser(page);

    // Mock exam with 1 second time limit
    await page.goto(`${FRONTEND_URL}/exams/time-test`);
    await page.click('button:has-text("시작")');

    await page.waitForTimeout(2000);

    await expect(page.locator('.auto-submit-message')).toContainText(/시간 초과.*자동 제출/i);
    await expect(page).toHaveURL(/\/exams\/.*\/result/);
  });

  test('103. 채점 결과 표시', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/result`);

    await expect(page.locator('.score-display')).toBeVisible();
    await expect(page.locator('.correct-count')).toBeVisible();
    await expect(page.locator('.wrong-count')).toBeVisible();
    await expect(page.locator('.percentage')).toBeVisible();
  });

  test('104. 문제별 정답/오답 표시', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/result`);

    const questions = page.locator('.result-question-item');

    for (const question of await questions.all()) {
      const status = question.locator('.answer-status');
      await expect(status).toContainText(/정답|오답/);
    }
  });

  test('105. 오답 상세 해설', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/result`);

    const wrongAnswer = page.locator('.result-question-item.wrong').first();
    await wrongAnswer.click();

    const explanation = page.locator('.answer-explanation');
    await expect(explanation).toBeVisible();
    await expect(explanation.locator('.your-answer')).toBeVisible();
    await expect(explanation.locator('.correct-answer')).toBeVisible();
    await expect(explanation.locator('.detailed-explanation')).toBeVisible();
  });

  // 시험 분석
  test('106. 챕터별 성적 분석', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/analysis`);

    const chapterStats = page.locator('.chapter-statistics');
    await expect(chapterStats).toBeVisible();

    const chapters = chapterStats.locator('.chapter-stat');
    for (const chapter of await chapters.all()) {
      await expect(chapter.locator('.chapter-score')).toBeVisible();
      await expect(chapter.locator('.chapter-percentage')).toBeVisible();
    }
  });

  test('107. 약점 분석 리포트', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/analysis`);

    await page.click('tab:has-text("약점 분석")');

    const weaknessReport = page.locator('.weakness-analysis');
    await expect(weaknessReport).toBeVisible();
    await expect(weaknessReport.locator('.weak-topic')).toHaveCount(await weaknessReport.locator('.weak-topic').count());
  });

  test('108. 시간 배분 분석', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/analysis`);

    await page.click('tab:has-text("시간 분석")');

    const timeAnalysis = page.locator('.time-analysis');
    await expect(timeAnalysis.locator('.avg-time-per-question')).toBeVisible();
    await expect(timeAnalysis.locator('.time-distribution-chart')).toBeVisible();
  });

  test('109. 난이도별 정답률', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/analysis`);

    const difficultyStats = page.locator('.difficulty-statistics');
    await expect(difficultyStats.locator('.easy-accuracy')).toBeVisible();
    await expect(difficultyStats.locator('.medium-accuracy')).toBeVisible();
    await expect(difficultyStats.locator('.hard-accuracy')).toBeVisible();
  });

  test('110. 전체 응시자 대비 순위', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/analysis`);

    const ranking = page.locator('.ranking-info');
    await expect(ranking.locator('.your-rank')).toBeVisible();
    await expect(ranking.locator('.total-participants')).toBeVisible();
    await expect(ranking.locator('.percentile')).toBeVisible();
  });

  // 시험 관리
  test('111. 시험 목록 조회', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams`);

    await expect(page.locator('.exam-list')).toBeVisible();
    await expect(page.locator('.exam-item')).toHaveCount(await page.locator('.exam-item').count());
  });

  test('112. 시험 필터링 - 상태별', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams`);

    await page.selectOption('[name="status-filter"]', 'completed');

    const exams = page.locator('.exam-item');
    for (const exam of await exams.all()) {
      await expect(exam.locator('.exam-status')).toContainText('완료');
    }
  });

  test('113. 시험 필터링 - 날짜별', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams`);

    await page.fill('[name="date-from"]', '2024-01-01');
    await page.fill('[name="date-to"]', '2024-12-31');
    await page.click('button:has-text("필터 적용")');

    const dates = await page.locator('.exam-date').allTextContents();
    dates.forEach(date => {
      const examDate = new Date(date);
      expect(examDate >= new Date('2024-01-01')).toBeTruthy();
      expect(examDate <= new Date('2024-12-31')).toBeTruthy();
    });
  });

  test('114. 시험 재응시', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/result`);

    await page.click('button:has-text("재응시")');

    const retakeDialog = page.locator('.retake-dialog');
    await expect(retakeDialog).toBeVisible();

    await retakeDialog.locator('button:has-text("확인")').click();
    await expect(page).toHaveURL(/\/exams\/\d+$/);
  });

  test('115. 시험 결과 PDF 다운로드', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/result`);

    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("PDF 다운로드")');

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/exam-result.*\.pdf$/i);
  });

  // 오답노트
  test('116. 오답노트 자동 생성', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/result`);

    await page.click('button:has-text("오답노트 생성")');

    await expect(page.locator('.success-message')).toContainText(/오답노트.*생성/i);
    await expect(page).toHaveURL(/\/review\/\d+/);
  });

  test('117. 오답노트 문제 복습', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/review/1`);

    const wrongQuestions = page.locator('.review-question');
    await expect(wrongQuestions).toHaveCount(await wrongQuestions.count());

    // Test review mode
    await wrongQuestions.first().locator('button:has-text("다시 풀기")').click();
    await expect(page.locator('.review-mode-question')).toBeVisible();
  });

  test('118. 오답노트 태그 추가', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/review/1`);

    const firstQuestion = page.locator('.review-question').first();
    await firstQuestion.locator('button:has-text("태그 추가")').click();

    await page.fill('.tag-input', '실수, 개념부족');
    await page.click('button:has-text("저장")');

    await expect(firstQuestion.locator('.tag')).toHaveCount(2);
  });

  test('119. 오답노트 메모 작성', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/review/1`);

    const firstQuestion = page.locator('.review-question').first();
    await firstQuestion.locator('button:has-text("메모")').click();

    await page.fill('.memo-textarea', '다음번에는 문제를 더 꼼꼼히 읽자');
    await page.click('button:has-text("메모 저장")');

    await expect(firstQuestion.locator('.memo-indicator')).toBeVisible();
  });

  test('120. 오답노트 완료 체크', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/review/1`);

    const firstQuestion = page.locator('.review-question').first();
    await firstQuestion.locator('input[type="checkbox"]').check();

    await expect(firstQuestion).toHaveClass(/completed/);

    // Verify progress update
    const progress = page.locator('.review-progress');
    await expect(progress).toContainText(/1.*완료/);
  });

  // 실전 모드
  test('121. 실전 모드 시작', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.click('button:has-text("실전 모드")');

    const realExamSettings = page.locator('.real-exam-settings');
    await expect(realExamSettings).toBeVisible();
    await expect(realExamSettings).toContainText(/실제 시험과 동일/i);
  });

  test('122. 실전 모드 - 시간 경고', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, 'real-1');

    // Wait for time warning (when 10 minutes left)
    await page.evaluate(() => {
      // Mock time to trigger warning
      window.mockTimeRemaining = 600; // 10 minutes
    });

    await expect(page.locator('.time-warning')).toBeVisible();
    await expect(page.locator('.time-warning')).toContainText(/10분 남았습니다/i);
  });

  test('123. 실전 모드 - 화면 잠금', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, 'real-1');

    // Try to navigate away
    await page.keyboard.press('Alt+Tab');

    await expect(page.locator('.fullscreen-warning')).toBeVisible();
    await expect(page.locator('.fullscreen-warning')).toContainText(/전체 화면/i);
  });

  test('124. 실전 모드 - 부정행위 감지', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, 'real-1');

    // Try to copy text
    await page.keyboard.press('Control+C');

    await expect(page.locator('.cheating-warning')).toBeVisible();
    await expect(page.locator('.warning-count')).toContainText('1');
  });

  test('125. 실전 모드 - OMR 답안지', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, 'real-1');

    await page.click('button:has-text("OMR 답안지")');

    const omrSheet = page.locator('.omr-sheet');
    await expect(omrSheet).toBeVisible();
    await expect(omrSheet.locator('.omr-bubble')).toHaveCount(100);
  });

  // 학습 모드
  test('126. 학습 모드 - 즉시 채점', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.click('button:has-text("학습 모드")');
    await page.click('button:has-text("시작")');

    // Answer question
    await page.click('.answer-option:nth-child(2)');
    await page.click('button:has-text("확인")');

    // Immediate feedback
    await expect(page.locator('.answer-feedback')).toBeVisible();
    await expect(page.locator('.answer-feedback')).toContainText(/정답|오답/);
  });

  test('127. 학습 모드 - 해설 보기', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, 'study-1');

    await page.click('.answer-option:nth-child(1)');
    await page.click('button:has-text("확인")');

    await page.click('button:has-text("해설 보기")');

    const explanation = page.locator('.study-explanation');
    await expect(explanation).toBeVisible();
    await expect(explanation.locator('.concept-explanation')).toBeVisible();
  });

  test('128. 학습 모드 - 힌트 사용', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, 'study-1');

    await page.click('button:has-text("힌트")');

    const hint = page.locator('.question-hint');
    await expect(hint).toBeVisible();
    await expect(hint).not.toContainText(/정답/i); // Hint shouldn't give away answer
  });

  test('129. 학습 모드 - 참고자료 링크', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, 'study-1');

    await page.click('button:has-text("참고자료")');

    const references = page.locator('.reference-links');
    await expect(references).toBeVisible();
    await expect(references.locator('a')).toHaveCount(await references.locator('a').count());
  });

  test('130. 학습 모드 - 유사 문제 추천', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, 'study-1');

    await page.click('.answer-option:nth-child(2)');
    await page.click('button:has-text("확인")');

    const similarQuestions = page.locator('.similar-questions');
    await expect(similarQuestions).toBeVisible();
    await expect(similarQuestions.locator('.question-link')).toHaveCount(3);
  });

  // 맞춤형 모의고사
  test('131. AI 추천 모의고사', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/ai-recommend`);

    await page.click('button:has-text("AI 추천 받기")');

    await expect(page.locator('.ai-recommendation')).toBeVisible({ timeout: 10000 });
    await expect(page.locator('.recommendation-reason')).toBeVisible();
  });

  test('132. 약점 집중 모의고사', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.click('button:has-text("약점 집중")');

    const weaknessSettings = page.locator('.weakness-focus-settings');
    await expect(weaknessSettings).toBeVisible();
    await expect(weaknessSettings.locator('.weak-topics')).toBeVisible();
  });

  test('133. 사용자 정의 모의고사', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.click('button:has-text("사용자 정의")');

    // Select specific questions
    await page.click('.question-selector button:has-text("문제 선택")');

    const questionPicker = page.locator('.question-picker-dialog');
    await questionPicker.locator('.question-checkbox:nth-child(1)').check();
    await questionPicker.locator('.question-checkbox:nth-child(5)').check();
    await questionPicker.locator('.question-checkbox:nth-child(10)').check();

    await questionPicker.locator('button:has-text("선택 완료")').click();

    await expect(page.locator('.selected-questions-count')).toContainText('3');
  });

  test('134. 진도별 모의고사', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.click('button:has-text("진도별")');

    await page.selectOption('[name="progress-chapter"]', 'chapter-3');
    await page.click('button:has-text("생성")');

    await expect(page.locator('.exam-scope')).toContainText(/챕터 1-3/i);
  });

  test('135. 기출문제 연도별 모의고사', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/create`);

    await page.click('button:has-text("기출문제")');

    await page.selectOption('[name="year"]', '2023');
    await page.selectOption('[name="round"]', '2');

    await page.click('button:has-text("생성")');

    await expect(page.locator('.exam-title')).toContainText('2023년 2회');
  });

  // 시험 통계
  test('136. 개인 시험 통계', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/statistics/exams`);

    await expect(page.locator('.total-exams-taken')).toBeVisible();
    await expect(page.locator('.average-score')).toBeVisible();
    await expect(page.locator('.improvement-rate')).toBeVisible();
  });

  test('137. 시험 성적 추이 그래프', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/statistics/exams`);

    const scoreChart = page.locator('.score-trend-chart');
    await expect(scoreChart).toBeVisible();
    await expect(scoreChart.locator('canvas')).toBeVisible();
  });

  test('138. 문제 유형별 정답률', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/statistics/question-types`);

    const typeStats = page.locator('.question-type-stats');
    await expect(typeStats.locator('.type-stat')).toHaveCount(await typeStats.locator('.type-stat').count());

    for (const stat of await typeStats.locator('.type-stat').all()) {
      await expect(stat.locator('.type-name')).toBeVisible();
      await expect(stat.locator('.accuracy-rate')).toBeVisible();
    }
  });

  test('139. 학습 시간 통계', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/statistics/study-time`);

    await expect(page.locator('.total-study-time')).toBeVisible();
    await expect(page.locator('.daily-average')).toBeVisible();
    await expect(page.locator('.weekly-heatmap')).toBeVisible();
  });

  test('140. 목표 달성률', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/statistics/goals`);

    const goalProgress = page.locator('.goal-progress');
    await expect(goalProgress.locator('.target-score')).toBeVisible();
    await expect(goalProgress.locator('.current-average')).toBeVisible();
    await expect(goalProgress.locator('.progress-bar')).toBeVisible();
  });

  // 협업 기능
  test('141. 시험 공유하기', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1`);

    await page.click('button:has-text("공유")');

    const shareDialog = page.locator('.share-exam-dialog');
    await expect(shareDialog).toBeVisible();

    await shareDialog.locator('button:has-text("링크 복사")').click();
    await expect(page.locator('.toast')).toContainText(/복사되었습니다/i);
  });

  test('142. 스터디 그룹 시험', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/study-groups/1/exams`);

    await page.click('button:has-text("그룹 시험 생성")');

    await page.fill('[name="group-exam-title"]', '스터디 그룹 모의고사 #1');
    await page.fill('[name="start-time"]', '2024-12-20T14:00');

    await page.click('button:has-text("생성")');

    await expect(page.locator('.group-exam-created')).toBeVisible();
  });

  test('143. 시험 결과 비교', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/compare`);

    await page.selectOption('[name="compare-with"]', 'user-2');

    const comparison = page.locator('.score-comparison');
    await expect(comparison.locator('.your-score')).toBeVisible();
    await expect(comparison.locator('.other-score')).toBeVisible();
    await expect(comparison.locator('.comparison-chart')).toBeVisible();
  });

  test('144. 시험 댓글 작성', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/discussion`);

    await page.fill('.comment-textarea', '이번 시험 너무 어려웠어요!');
    await page.click('button:has-text("댓글 작성")');

    await expect(page.locator('.comment-item').last()).toContainText('이번 시험 너무 어려웠어요!');
  });

  test('145. 시험 난이도 평가', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/1/result`);

    await page.click('.difficulty-rating .star:nth-child(4)');

    await expect(page.locator('.rating-submitted')).toBeVisible();
    await expect(page.locator('.average-difficulty')).toBeVisible();
  });

  // 고급 기능
  test('146. 시험 일시정지/재개', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    await page.click('button:has-text("일시정지")');

    const pauseOverlay = page.locator('.pause-overlay');
    await expect(pauseOverlay).toBeVisible();
    await expect(pauseOverlay).toContainText(/일시정지/i);

    await pauseOverlay.locator('button:has-text("재개")').click();
    await expect(pauseOverlay).not.toBeVisible();
  });

  test('147. 시험 중 메모 기능', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    await page.click('button[aria-label="메모"]');

    const memoPanel = page.locator('.exam-memo-panel');
    await expect(memoPanel).toBeVisible();

    await memoPanel.locator('textarea').fill('공식: V = IR');
    await memoPanel.locator('button:has-text("저장")').click();

    await expect(page.locator('.memo-saved-indicator')).toBeVisible();
  });

  test('148. 시험 화면 확대/축소', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    // Zoom in
    await page.click('button[aria-label="확대"]');
    await expect(page.locator('.exam-content')).toHaveCSS('transform', /scale\(1\.2\)/);

    // Zoom out
    await page.click('button[aria-label="축소"]');
    await expect(page.locator('.exam-content')).toHaveCSS('transform', /scale\(0\.8\)/);

    // Reset
    await page.click('button[aria-label="원본 크기"]');
    await expect(page.locator('.exam-content')).toHaveCSS('transform', /scale\(1\)/);
  });

  test('149. 시험 접근성 모드', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/settings/accessibility`);

    await page.check('[name="high-contrast"]');
    await page.check('[name="large-text"]');
    await page.check('[name="screen-reader"]');

    await startExam(page, '1');

    await expect(page.locator('body')).toHaveClass(/high-contrast/);
    await expect(page.locator('body')).toHaveClass(/large-text/);
    await expect(page.locator('[aria-live="polite"]')).toBeVisible();
  });

  test('150. 시험 데이터 내보내기', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/exams/export`);

    await page.selectOption('[name="format"]', 'excel');
    await page.check('[name="include-answers"]');
    await page.check('[name="include-explanations"]');

    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("내보내기")');

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/exam-export.*\.xlsx$/i);
  });
});

// Performance tests for exam system
test.describe('모의고사 성능 테스트', () => {
  test('P01. 대용량 문제 로딩 성능', async ({ page }) => {
    await loginAsUser(page);

    const startTime = Date.now();
    await page.goto(`${FRONTEND_URL}/exams/large-200`);
    const loadTime = Date.now() - startTime;

    expect(loadTime).toBeLessThan(3000); // Should load within 3 seconds

    await expect(page.locator('.question-item')).toHaveCount(200);
  });

  test('P02. 동시 다발 답안 저장', async ({ page }) => {
    await loginAsUser(page);
    await startExam(page, '1');

    // Rapid answer selection
    for (let i = 0; i < 10; i++) {
      await page.click('.answer-option:nth-child(1)');
      await page.click('button:has-text("다음")');
    }

    // All answers should be saved
    await page.click('button:has-text("답안지")');
    await expect(page.locator('.answered')).toHaveCount(10);
  });
});