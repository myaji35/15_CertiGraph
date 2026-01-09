# Tech-Spec: 실전모의고사 및 기출문제 기능

**Created:** 2025-01-09
**Status:** Completed

## Overview

### 문제 설명
현재 CertiGraph에는 기본적인 테스트 기능만 있으며, 실제 사회복지사 1급 시험과 동일한 형태의 모의고사 기능이 없습니다. 수험생들은 실제 시험 환경을 체험하고, 과거 기출문제로 연습할 수 있는 기능을 필요로 합니다.

### 솔루션
실제 시험과 동일한 형식의 실전모의고사 기능을 구현합니다:
- 기출문제 연도별/회차별 선택 기능
- 3교시 구분 (1교시, 2교시, 3교시)
- 교시별 시간 제한 (각 60분)
- 과락 시스템 (교시별 40%, 전체 60%)
- 상세한 성적 분석 및 오답 해설

### 범위 (포함/제외)

**포함:**
- 기출문제 데이터베이스 구축 (제19회~제23회)
- 실전모의고사 모드 (전체 3교시)
- 교시별 개별 응시 모드
- 시간 제한 및 자동 제출
- 과락 판정 시스템
- 상세 성적표 및 분석
- 오답노트 자동 생성

**제외:**
- 실시간 순위 시스템 (향후 구현)
- AI 기반 문제 생성 (현재는 기출문제만)
- 모의고사 공유 기능 (향후 구현)

## Context for Development

### Codebase Patterns

**Backend 패턴:**
```python
# Repository Pattern
class ExamRepository:
    async def get_past_exams()
    async def get_exam_by_year_round()

# Service Layer
class MockExamService:
    async def start_mock_exam()
    async def calculate_cutoff()

# Pydantic Models
class MockExamRequest(BaseModel):
    exam_year: int
    exam_round: int
    session_number: Optional[int]  # None이면 전체 3교시
```

**Frontend 패턴:**
```typescript
// Component Structure
MockExamPage
├── ExamSelector (연도/회차 선택)
├── ExamTimer (시간 제한 표시)
├── QuestionView (문제 표시)
└── ResultAnalysis (결과 분석)
```

### Files to Reference

**기존 파일 (참조):**
- `/backend/app/api/v1/endpoints/tests.py` - 테스트 엔드포인트
- `/backend/app/models/test.py` - 테스트 모델
- `/backend/app/models/study_set.py` - exam_year, exam_round 필드
- `/frontend/src/app/(dashboard)/test/page.tsx` - 테스트 페이지

**새로 생성할 파일:**
- `/backend/app/api/v1/endpoints/mock_exam.py` - 모의고사 전용 엔드포인트
- `/backend/app/models/mock_exam.py` - 모의고사 모델
- `/backend/app/services/mock_exam.py` - 모의고사 서비스
- `/frontend/src/app/(dashboard)/mock-exam/page.tsx` - 모의고사 페이지
- `/frontend/src/components/mock-exam/` - 모의고사 컴포넌트들

### Technical Decisions

1. **데이터 구조:**
   - 기출문제는 study_sets 테이블의 exam_year, exam_round, exam_session 필드 활용
   - 각 교시는 별도의 study_set으로 관리
   - tags에 ['기출문제', '2024년', '제22회'] 형태로 저장

2. **시험 모드:**
   - `MOCK_FULL`: 전체 3교시 연속 응시 (180분)
   - `MOCK_SESSION`: 교시별 개별 응시 (60분)
   - `PAST_EXAM`: 특정 연도/회차 기출문제

3. **과락 판정:**
   - 교시별 점수 40점 미만 → 과락
   - 전체 평균 60점 미만 → 불합격
   - 모든 조건 충족 시 → 합격

## Implementation Plan

### Tasks

- [x] **Task 1: 백엔드 모의고사 API 구현**
  - mock_exam 엔드포인트 생성 ✅
  - 기출문제 필터링 로직 ✅
  - 과락 판정 시스템 ✅

- [x] **Task 2: 모의고사 모델 정의**
  - MockExamMode enum 추가 ✅
  - MockExamSession 모델 ✅
  - CutoffResult 모델 ✅

- [x] **Task 3: 프론트엔드 모의고사 페이지**
  - 기출문제 선택 UI ✅
  - 시험 타이머 컴포넌트 ✅
  - 교시 전환 로직 ✅

- [x] **Task 4: 실전 시험 모드 구현**
  - 3교시 연속 응시 플로우 ✅
  - 교시별 시간 관리 ✅
  - 자동 저장 및 복구 ✅

- [x] **Task 5: 결과 분석 기능**
  - 과락 판정 표시 ✅
  - 교시별 성적 분석 ✅
  - 약점 과목 분석 ✅

- [ ] **Task 6: 기출문제 데이터 입력**
  - 제19회~제23회 데이터 구조화
  - 메타데이터 태깅
  - 정답 및 해설 입력

### Acceptance Criteria

- [ ] **AC 1: 기출문제 선택**
  - Given: 사용자가 모의고사 페이지 접속
  - When: 연도와 회차를 선택
  - Then: 해당 기출문제로 시험 시작

- [ ] **AC 2: 시간 제한**
  - Given: 모의고사 시작
  - When: 교시별 60분 경과
  - Then: 자동으로 답안 제출 및 다음 교시 진행

- [ ] **AC 3: 과락 판정**
  - Given: 3교시 모두 완료
  - When: 채점 완료
  - Then: 교시별 40점, 전체 60점 기준으로 합격/불합격 판정

- [ ] **AC 4: 결과 분석**
  - Given: 시험 완료
  - When: 결과 페이지 확인
  - Then: 교시별 점수, 과락 여부, 약점 분석 표시

- [ ] **AC 5: 오답 복습**
  - Given: 시험 결과 확인
  - When: 오답노트 버튼 클릭
  - Then: 틀린 문제만 모아서 복습 가능

## Additional Context

### Dependencies
- 기존 테스트 시스템과 호환성 유지
- Clerk 인증 시스템 활용
- Supabase 데이터베이스 스키마 확장

### Testing Strategy
1. **단위 테스트:**
   - 과락 판정 로직
   - 시간 제한 기능
   - 점수 계산

2. **통합 테스트:**
   - 3교시 연속 응시 플로우
   - 데이터 저장 및 복구
   - 결과 분석 정확성

3. **E2E 테스트:**
   - 전체 시험 시나리오
   - 중간 이탈 후 재접속
   - 다양한 브라우저 호환성

### Notes

**우선순위:**
1. 기본 모의고사 기능 (MVP)
2. 기출문제 데이터 입력
3. 상세 분석 기능
4. UI/UX 개선

**성능 고려사항:**
- 문제 로딩 최적화 (lazy loading)
- 답안 자동 저장 (30초마다)
- 타이머 정확성 (서버 시간 동기화)

**보안 고려사항:**
- 문제 유출 방지 (복사 방지)
- 시험 중 탭 전환 감지
- 답안 무결성 검증

---

**다음 단계:**
이 기술 명세서를 바탕으로 개발을 시작하시려면:
```bash
/bmad:bmm:workflows:quick-dev /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/docs/sprint-artifacts/tech-spec-mock-exam.md
```