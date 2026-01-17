# Agent Orchestration Patterns

PM이 서브 에이전트를 효과적으로 조율하는 패턴 모음.

## 1. 순차 실행 패턴 (Sequential)

### 사용 시점
- 이전 작업 결과가 다음 작업의 입력이 되는 경우
- 의존성이 명확한 작업 흐름

### 구문
```
@sequence:RA→SA→BE
```

### 예시: 새 기능 개발
```
@sequence:RA→SA→BE 결제 시스템 구현

실행 순서:
1. RA: 결제 요구사항 분석 → 명세서 출력
2. SA: 명세서 기반 아키텍처 설계 → 설계 문서 출력
3. BE: 설계 문서 기반 구현 → 코드 출력
```

### 에러 핸들링
```
@sequence:RA→SA→BE
         ↓ (RA 실패)
    PM에게 에스컬레이션
    수동 개입 후 재시작
```

---

## 2. 병렬 실행 패턴 (Parallel)

### 사용 시점
- 독립적인 작업을 동시 수행할 때
- 시간 단축이 필요할 때

### 구문
```
@parallel:BE,FE,DBA
```

### 예시: 기능 구현
```
@parallel:BE,FE 사용자 프로필 구현

실행 순서:
1. [병렬] BE: API 구현
   [병렬] FE: UI 구현
2. [대기] 모든 에이전트 완료
3. [통합] QA: 통합 테스트
```

### 동기화 포인트
```
@parallel:BE,FE → @sync → @agent:QA
                   ↑
              모두 완료 시점
```

---

## 3. 조건부 실행 패턴 (Conditional)

### 사용 시점
- 상황에 따라 다른 에이전트가 필요할 때
- 분기 처리가 필요할 때

### 구문
```
@if:[조건] @agent:[ID]
@else @agent:[ID]
```

### 예시: 보안 검토
```
@if:security_required @agent:SEC 보안 검토
@else @agent:QA 기본 테스트

조건:
- security_required: 인증, 결제, 개인정보 관련 기능
```

### 조건 매트릭스
| 조건 | True | False |
|------|------|-------|
| DB 변경 | @agent:DBA | 스킵 |
| 외부 연동 | @agent:INT | 스킵 |
| UI 변경 | @agent:UX | 스킵 |
| 성능 중요 | @agent:PERF | 스킵 |

---

## 4. 반복 실행 패턴 (Iterative)

### 사용 시점
- 품질 기준을 충족할 때까지 반복할 때
- 피드백 기반 개선이 필요할 때

### 구문
```
@loop:until:[조건] @agent:[ID]
```

### 예시: 코드 품질
```
@loop:until:lint_pass @agent:BE 코드 수정

실행:
1. BE: 코드 작성
2. 린터 실행
3. [실패] BE: 코드 수정 → 2로 복귀
4. [성공] 다음 단계
```

### 최대 반복 제한
```
@loop:max:3:until:test_pass @agent:BE
        ↓ (3회 실패)
   PM에게 에스컬레이션
```

---

## 5. 파이프라인 패턴 (Pipeline)

### 사용 시점
- 정형화된 워크플로우
- 자동화된 품질 게이트

### 구문
```
@pipeline:[이름]
```

### 예시: 기능 완성 파이프라인
```
@pipeline:feature_complete

자동 실행:
1. @agent:BE 구현 완료 확인
2. @agent:QA 단위 테스트 실행
3. @agent:QA 통합 테스트 실행
4. @agent:SEC 보안 스캔
5. @gate:code_review PM 승인 대기
6. @agent:DOC 문서 업데이트
```

### 게이트 정의
```
@gate:code_review
  - 리뷰어 1인 이상 승인
  - 모든 코멘트 해결
  - CI 통과
```

---

## 6. 위임 패턴 (Delegation)

### 사용 시점
- 복잡한 작업을 서브 에이전트에게 완전 위임
- PM은 결과만 검토

### 구문
```
@delegate:[ID] [task] --report:[주기]
```

### 예시: 스프린트 리팩토링
```
@delegate:SA 기술 부채 해소 --report:daily

SA의 권한:
- BE, FE, DBA에게 서브태스크 할당
- 코드 리뷰 요청
- 테스트 실행 요청

PM에게 보고:
- 일일 진행 상황
- 블로커 발생 시 즉시
```

---

## 7. 감시 패턴 (Monitor)

### 사용 시점
- 지속적 모니터링이 필요할 때
- 이상 감지 시 자동 대응

### 구문
```
@monitor:[대상] --alert:[조건] @agent:[ID]
```

### 예시: 배포 후 모니터링
```
@monitor:production --alert:error_rate>1% @agent:DO

동작:
- 에러율 1% 초과 시
- DO 에이전트 자동 호출
- 롤백 또는 수정 실행
- PM에게 알림
```

---

## 복합 패턴 예시

### 새 기능 E2E 개발
```
# 기능: 소셜 로그인 추가

## Phase 1: 설계
@sequence:RA→SA

## Phase 2: 구현
@parallel:BE,FE
  BE: OAuth 클라이언트 구현
  FE: 소셜 로그인 버튼 구현

## Phase 3: 검증
@sequence:QA→SEC
  QA: 기능 테스트
  SEC: OAuth 보안 검토

## Phase 4: 완료
@parallel:DOC,DO
  DOC: 사용자 가이드 업데이트
  DO: 배포 준비
```

### 긴급 핫픽스
```
# 이슈: 결제 실패

## 1. 진단
@agent:BE 원인 분석 --timeout:30m

## 2. 수정
@agent:BE 핫픽스 구현

## 3. 검증
@parallel:QA,SEC
  QA: 영향 범위 테스트
  SEC: 결제 보안 확인

## 4. 배포
@pipeline:hotfix_deploy
  - 스테이징 배포
  - 스모크 테스트
  - 프로덕션 배포
  - 모니터링 (1h)
```

---

## 에이전트 조합 가이드

### 기능 유형별 권장 조합

| 기능 유형 | 필수 에이전트 | 선택 에이전트 |
|----------|-------------|--------------|
| CRUD 기능 | BE, FE, QA | DBA |
| 인증/인가 | BE, SEC, QA | - |
| 외부 연동 | BE, INT, QA | SEC |
| 리포트 | BE, FE, DBA | PERF |
| 관리자 기능 | BE, FE, QA | SEC |
| 실시간 기능 | BE, FE, PERF | DO |

### 리스크 레벨별 검토 필수 에이전트

| 리스크 | 필수 검토 |
|--------|----------|
| 보안 | SEC, QA |
| 성능 | PERF, DBA |
| 안정성 | QA, DO |
| 데이터 | DBA, SEC |
