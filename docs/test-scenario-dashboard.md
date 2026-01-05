# Test Scenario: Dashboard & Navigation Flow

## 개요
이 시나리오는 메인 대시보드(`http://localhost:3000/dashboard`)의 구성 요소와 주요 하위 메뉴로의 탐색 기능을 검증하는 E2E 테스트 절차입니다. 사용자 경험의 핵심인 허브 페이지의 안정성을 확인합니다.

## 사전 조건
1.  **Server Status**: Backend(8000) & Frontend(3000) Running.
2.  **Auth**: User Logged In.

---

## 시나리오 ID: FE-DASH-001 (대시보드 메인 화면 점검)

### 1단계: 대시보드 진입
*   **Action**: `http://localhost:3000/dashboard` 접속.
*   **Expected Result**:
    *   페이지 로드 완료 (5초 이내).
    *   오류 배지("Issues")가 0개여야 함.
    *   **헤더**: "안녕하세요, [사용자]님" 환영 문구 표시.
    *   **통계 요약**: "현재 점수", "학습 진도율", "예측 합격률" 카드 표시.
    *   **차트**: "학습 활동" 또는 "영역별 강약점" 차트 렌더링.

### 2단계: 최근 학습 활동 확인
*   **Action**: "최근 학습한 문제집" 또는 "퀵 메뉴" 섹션 확인.
*   **Expected Result**:
    *   최근 접근한 문제집 카드 표시 (없을 경우 "학습 기록이 없습니다" 또는 안내 문구).
    *   "바로가기" 버튼 동작 확인.

---

## 시나리오 ID: FE-DASH-002 (주요 하위 메뉴 네비게이션)

### 1단계: 내 문제집 (Study Sets)
*   **Action**: 사이드바/메뉴에서 "내 문제집" 클릭.
*   **Expected Result**: `/study-sets`로 이동 및 리스트 표시.
*   **Return**: 다시 대시보드로 복귀.

### 2단계: 실전 모의고사 (Test / Exam)
*   **Action**: 메뉴에서 "실전 모의고사" 또는 "시험 보기" 클릭.
*   **Expected Result**: `/test` 또는 `/exam` 페이지 로드.

### 3단계: 성적 분석 (Analysis)
*   **Action**: 메뉴에서 "성적 분석" 클릭.
*   **Expected Result**: `/grade-analysis` 또는 `/analysis` 페이지 로드.
    *   상세 차트/그래프 표시 여부 확인.

### 4단계: 지식 그래프 (Knowledge Graph)
*   **Action**: 메뉴에서 "지식 그래프" 클릭.
*   **Expected Result**: `/knowledge-graph` 페이지 로드.
    *   그래프 캔버스 렌더링 확인 (빈 화면이 아니어야 함).

### 5단계: 자격증/일정 (Certifications)
*   **Action**: 메뉴에서 "자격증 일정" 클릭.
*   **Expected Result**: `/certifications` 페이지 이동 (이전 테스트 완료 항목 재확인).

---

## 시나리오 ID: FE-DASH-003 (반응형/상호작용)

### 1단계: 차트 인터랙션 (Optional)
*   **Action**: 대시보드 메인 차트에 마우스 오버.
*   **Expected Result**: 툴팁 표시 등 반응성 확인. (스크린샷으로 확인 어려울 수 있음)
