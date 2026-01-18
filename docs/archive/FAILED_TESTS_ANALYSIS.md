# 42개 실패 테스트 상세 분석 및 구현 계획

## 📊 실패 테스트 카테고리 분석

### 카테고리별 분포:
- **Frontend Component 테스트**: 18개 (42.9%)
- **API Integration 테스트**: 23개 (54.8%)
- **E2E Demo 테스트**: 1개 (2.3%)

---

## 🎯 우선순위 1: API Integration 테스트 (23개)

### A. Dashboard Stats API (6개 실패)

**누락된 엔드포인트:**
1. `GET /api/v1/dashboard/stats` - 사용자 통계
2. `GET /api/v1/dashboard/recent-activity` - 최근 활동
3. `GET /api/v1/dashboard/weak-concepts` - 취약 개념
4. `GET /api/v1/dashboard/study-progress` - 학습 진도
5. `GET /api/v1/knowledge-graph` - 지식 그래프 데이터
6. `GET /api/v1/knowledge-graph/:concept` - 개념 상세 (통과 중)

**구현 필요:**
- Epic 4 Story 4.1~4.3 구현
- Neo4j 연결 및 GraphRAG 로직

### B. Questions API (5개 실패)

**실패 원인**: 필터링 기능 미구현
1. `GET /api/v1/questions` - 전체 목록 (응답 형식 불일치)
2. `GET /api/v1/questions?study_set_id=X` - Study Set 필터
3. `GET /api/v1/questions?concept=X` - Concept 필터
4. `GET /api/v1/questions?difficulty=X` - Difficulty 필터

**구현 필요:**
- 쿼리 파라미터 처리
- Pinecone 필터링 로직
- 응답 형식 통일

### C. Study Sets API (7개 실패)

**실패 원인**: 인증 및 응답 형식 문제
1. `GET /api/v1/study-sets` - 목록 (pagination, sorting)
2. `GET /api/v1/study-sets?certification_id=X` - 필터링
3. `GET /api/v1/study-sets?search=X` - 검색
4. `GET /api/v1/study-sets/:id` - 상세 조회
5. `POST /api/v1/study-sets` - 생성
6. `PATCH /api/v1/study-sets/:id` - 수정
7. `DELETE /api/v1/study-sets/:id` - 삭제

**구현 필요:**
- 인증 토큰 처리 개선
- 페이지네이션 구현
- 정렬/필터/검색 기능

---

## 🎯 우선순위 2: Frontend Component 테스트 (18개)

### A. NotionCard Component (8개 실패)

**실패 원인**: 실제 컴포넌트가 존재하지 않음

**필요한 구현:**
```typescript
// frontend/src/components/NotionCard.tsx
interface NotionCardProps {
  title: string;
  description?: string;
  icon?: string;
  className?: string;
  onClick?: () => void;
}

export function NotionCard({ title, description, icon, className, onClick }: NotionCardProps) {
  // 구현 필요
}
```

**테스트 요구사항:**
- 기본 props 렌더링
- title/description 표시
- hover 효과
- click 이벤트 처리
- className 커스터마이징
- icon 표시
- 긴 텍스트 오버플로우 처리
- ARIA 접근성

### B. NotionStatCard Component (8개 실패)

**필요한 구현:**
```typescript
// frontend/src/components/NotionStatCard.tsx
interface NotionStatCardProps {
  title: string;
  value: number | string;
  trend?: 'up' | 'down' | 'neutral';
  trendValue?: string;
  isLoading?: boolean;
  onClick?: () => void;
}

export function NotionStatCard({ title, value, trend, trendValue, isLoading, onClick }: NotionStatCardProps) {
  // 구현 필요
}
```

**테스트 요구사항:**
- 기본 렌더링
- title/value 표시
- trend indicator (up/down/neutral)
- 큰 숫자 포맷팅
- 퍼센트 표시
- 로딩 상태
- 클릭 네비게이션

### C. QuestionCard Component (6개 실패)

**필요한 구현:**
```typescript
// frontend/src/components/QuestionCard.tsx
interface QuestionCardProps {
  questionNumber: number;
  questionText: string;
  options: string[];
  correctAnswer?: number;
  explanation?: string;
  onAnswerSelect?: (index: number) => void;
  isSubmitted?: boolean;
}

export function QuestionCard(props: QuestionCardProps) {
  // 구현 필요
}
```

**테스트 요구사항:**
- question text 렌더링
- 5개 답변 옵션 표시
- 답변 선택 기능
- 제출 후 정답 표시
- Markdown 렌더링
- 문제 번호 표시
- 제출 후 해설 표시
- 제출 후 답변 변경 방지

---

## 🎯 우선순위 3: E2E Demo 테스트 (1개)

**실패 테스트:**
- `데모: 홈페이지 접속 및 기본 요소 확인`

**실패 원인**: 홈페이지 요소 변경 또는 누락

**수정 필요:**
- 테스트 selector 업데이트
- 또는 홈페이지 요소 추가

---

## 📋 구현 계획 (Quick Win 우선)

### Phase 1: Frontend Components (1-2시간)
**목표**: 18개 Component 테스트 통과

1. **NotionCard Component 구현**
   - 파일: `frontend/src/components/NotionCard.tsx`
   - 테스트 페이지에 import
   - 예상 시간: 30분
   - **결과**: +8개 테스트 통과

2. **NotionStatCard Component 구현**
   - 파일: `frontend/src/components/NotionStatCard.tsx`
   - 테스트 페이지에 import
   - 예상 시간: 30분
   - **결과**: +8개 테스트 통과

3. **QuestionCard Component 구현**
   - 파일: `frontend/src/components/QuestionCard.tsx`
   - Markdown 렌더링 추가
   - 예상 시간: 45분
   - **결과**: +6개 테스트 통과

**Phase 1 완료 시: 32/95 테스트 통과 (33.7%)**

---

### Phase 2: Study Sets API 수정 (2-3시간)
**목표**: 7개 Study Sets API 테스트 통과

1. **인증 개선**
   - Mock user 생성 또는 Dev mode 인증 우회
   - 예상 시간: 30분

2. **Pagination 구현**
   - `GET /api/v1/study-sets?page=1&limit=10`
   - 예상 시간: 45분

3. **Sorting 구현**
   - `GET /api/v1/study-sets?sort=created_at&order=desc`
   - 예상 시간: 30분

4. **Filtering & Search**
   - certification_id 필터
   - name 검색
   - 예상 시간: 1시간

**Phase 2 완료 시: 39/95 테스트 통과 (41.1%)**

---

### Phase 3: Questions API 개선 (1-2시간)
**목표**: 5개 Questions API 테스트 통과

1. **응답 형식 통일**
   - 예상 시간: 30분

2. **필터링 구현**
   - study_set_id, concept, difficulty
   - Pinecone metadata 필터
   - 예상 시간: 1시간

**Phase 3 완료 시: 44/95 테스트 통과 (46.3%)**

---

### Phase 4: Dashboard API 구현 (3-4시간)
**목표**: 6개 Dashboard Stats API 테스트 통과

1. **기본 통계 엔드포인트**
   ```python
   GET /api/v1/dashboard/stats
   {
     "total_study_sets": 10,
     "total_questions": 500,
     "average_score": 75.5,
     "tests_taken": 25
   }
   ```
   - 예상 시간: 1시간

2. **최근 활동**
   ```python
   GET /api/v1/dashboard/recent-activity
   ```
   - 예상 시간: 45분

3. **취약 개념 (GraphRAG)**
   ```python
   GET /api/v1/dashboard/weak-concepts
   ```
   - Neo4j 쿼리 필요
   - 예상 시간: 1.5시간

4. **학습 진도**
   ```python
   GET /api/v1/dashboard/study-progress
   ```
   - 예상 시간: 45분

**Phase 4 완료 시: 50/95 테스트 통과 (52.6%)**

---

### Phase 5: 나머지 수정 (1시간)
**목표**: E2E Demo 테스트 수정

**Phase 5 완료 시: 51/95 테스트 통과 (53.7%)**

---

## 🚀 Total Timeline

**예상 총 시간**: 8-12시간
**예상 최종 결과**: **51/95 테스트 통과 (53.7%)**

**남은 44개 테스트**:
- Authentication 관련 (Clerk 설정 필요)
- Payment 관련 (Toss 설정 필요)

---

## 📌 즉시 실행 가능한 다음 단계

**지금 바로 시작:**
1. NotionCard Component 구현 → +8 tests
2. NotionStatCard Component 구현 → +8 tests
3. QuestionCard Component 구현 → +6 tests

**총 소요 시간**: 1-2시간
**효과**: 42개 실패 → 20개 실패 (테스트 통과율 11.6% → 33.7%)
