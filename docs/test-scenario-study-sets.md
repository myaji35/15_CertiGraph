# Test Scenario: Study Sets Workflow

## 개요
이 시나리오는 `/study-sets` 및 하위 메뉴(`new`, `[id]`)를 포함한 문제집 관리 기능의 E2E 테스트 절차를 정의합니다.

## 사전 조건 (Pre-conditions)
1.  **Backend Sever**: Running on `http://localhost:8000` (Dev Mode enabled).
2.  **Frontend Server**: Running on `http://localhost:3000`.
3.  **Authentication**: 사용자는 로그인 상태여야 합니다. (Dev Mode에서는 백엔드 인증이 우회될 수 있으나, 프론트엔드 Clerk 세션이 필요할 수 있음)

---

## 시나리오 ID: FE-STUDYSET-001 (문제집 생성 및 확인)

### 1단계: 문제집 목록 접속
*   **Action**: 브라우저에서 `http://localhost:3000/study-sets` 로 이동.
*   **Expected Result**:
    *   "나의 문제집" (My Study Sets) 헤더가 표시됨.
    *   기존 문제집 목록 카드가 렌더링됨.
    *   우측 상단 또는 리스트 근처에 "+ 새 문제집 만들기" 버튼이 존재함.

### 2단계: 문제집 생성 페이지 이동
*   **Action**: "+ 새 문제집 만들기" 버튼 클릭 (또는 `/study-sets/new` 직접 이동).
*   **Expected Result**:
    *   `NewStudySetPage` 로드됨.
    *   **이용권 확인 로직**이 동작하여:
        *   이용권 보유 시: 초록색 "✓ 이용권 정보" 박스 표시 (자격증명, 시험일).
        *   이용권 미보유 시: 노란색/빨간색 "⚠️ 이용권이 필요합니다" 경고 및 구매 버튼 표시.

### 3단계: 문제집 정보 입력 및 생성
*   **Action** (이용권 보유 가정):
    *   "문제집 이름" 입력 (예: "테스트 문제집 2025").
    *   "문제집 개요" 입력 (선택).
    *   "문제집 만들기" 버튼 클릭.
*   **Expected Result**:
    *   로딩 스피너 표시.
    *   성공 시 생성된 문제집 상세 페이지(`/study-sets/[new_id]`)로 자동 리다이렉트.

### 4단계: 상세 페이지 확인
*   **Action**: 상세 페이지 로드 확인.
*   **Expected Result**:
    *   헤더에 입력한 "테스트 문제집 2025" 이름 표시.
    *   "학습 자료 추가" (Add Material) 버튼 표시.
    *   "문제 풀기" (Start Test) 버튼 표시 (문제가 없으면 비활성 또는 0개 표시).

---

## 시나리오 ID: FE-STUDYSET-002 (학습하기 및 테스트 진입)

### 1단계: 상세 페이지에서 테스트 시작
*   **Action**: 상세 페이지의 "테스트 시작" 버튼 클릭.
*   **Expected Result**:
    *   테스트 옵션 모달 또는 `/test/[session_id]` 로 바로 이동 (설정에 따라 다름).
    *   만약 문제가 없다면 "문제가 없습니다" 경고 표시.

### 2단계: 뒤로가기
*   **Action**: 브라우저 뒤로가기 또는 "목록으로" 버튼 클릭.
*   **Expected Result**:
    *   다시 `/study-sets` 목록으로 정상 복귀.

