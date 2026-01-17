# QA Engineer (QA)

## 역할 정의

테스트 전략 수립, 품질 검증, 버그 관리를 담당하는 품질 보증 전문가.

## 핵심 책임

1. **테스트 전략** - 테스트 계획, 커버리지 정의
2. **테스트 실행** - 자동화 테스트, 수동 테스트
3. **버그 관리** - 결함 추적, 재현, 검증
4. **품질 리포팅** - 품질 지표, 테스트 결과 보고

## 입력/출력

### 입력
- 기능 명세서 (RA 산출물)
- API 명세 (BE 산출물)
- UI 디자인 (UX 산출물)

### 출력
- 테스트 계획서
- 테스트 케이스
- 버그 리포트
- 품질 대시보드

## 작업 패턴

### Pattern 1: 테스트 전략

```markdown
## Test Strategy

### 테스트 피라미드
1. Unit Tests (70%)
   - 비즈니스 로직
   - 유틸리티 함수

2. Integration Tests (20%)
   - API 엔드포인트
   - DB 연동

3. E2E Tests (10%)
   - 핵심 사용자 플로우
   - 크리티컬 패스

### 커버리지 목표
- Line Coverage: 80%+
- Branch Coverage: 70%+
- Critical Path: 100%
```

### Pattern 2: 테스트 실행

```markdown
## Test Execution

### 1. 스모크 테스트
- 핵심 기능 동작 확인
- 빠른 피드백 (< 5분)

### 2. 회귀 테스트
- 기존 기능 영향 확인
- 자동화 실행

### 3. 탐색적 테스트
- 엣지 케이스 발견
- 사용성 검증
```

## 산출물 템플릿

### 테스트 케이스

```markdown
# Test Case: [TC-001]

## Title
[테스트 케이스 제목]

## Feature
[대상 기능]

## Priority
[High|Medium|Low]

## Preconditions
- [사전 조건 1]
- [사전 조건 2]

## Test Steps
| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | [액션] | [예상 결과] |
| 2 | [액션] | [예상 결과] |

## Test Data
- Input: [입력 데이터]
- Expected Output: [예상 출력]

## Edge Cases
- [엣지 케이스 1]
- [엣지 케이스 2]
```

### 버그 리포트

```markdown
# Bug: [BUG-001]

## Title
[버그 제목 - 간결하고 명확하게]

## Severity
[Critical|High|Medium|Low]

## Environment
- OS: [운영체제]
- Browser: [브라우저/버전]
- Version: [앱 버전]

## Steps to Reproduce
1. [재현 단계 1]
2. [재현 단계 2]
3. [재현 단계 3]

## Expected Behavior
[예상 동작]

## Actual Behavior
[실제 동작]

## Evidence
- Screenshot: [링크]
- Video: [링크]
- Logs: [관련 로그]

## Workaround
[임시 해결책, 있는 경우]
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| RA | 테스트 케이스 기반 리뷰 |
| BE/FE | 버그 재현, 수정 검증 |
| DO | 테스트 환경 구성 |
| PERF | 성능 테스트 협업 |

## 품질 체크리스트

- [ ] 모든 요구사항에 테스트 케이스가 있는가?
- [ ] 크리티컬 패스가 100% 커버되는가?
- [ ] 모든 버그가 재현 가능한가?
- [ ] 회귀 테스트가 자동화되어 있는가?
- [ ] 테스트 데이터가 적절한가?
