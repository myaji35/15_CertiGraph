# KPM Orchestrator - Quick Start Guide

> CertiGraph 프로젝트를 위한 KPM Orchestrator 사용 가이드

## 목차
1. [개요](#개요)
2. [기본 명령어](#기본-명령어)
3. [에이전트 사용법](#에이전트-사용법)
4. [실전 예제](#실전-예제)
5. [FAQ](#faq)

---

## 개요

KPM Orchestrator는 12개의 전문 에이전트를 조율하여 프로젝트를 효율적으로 관리하는 시스템입니다.

### 핵심 원칙
- **PM은 오케스트레이터** - 직접 실행 대신 에이전트에 위임
- **속도 > 완벽** - 빠른 피드백 루프
- **명확한 R&R** - 에이전트별 책임 영역 명확화
- **상태 투명성** - 모든 진행 상황 추적

---

## 기본 명령어

### 상태 확인 명령
```bash
@status              # 프로젝트 전체 상태
@sprint 3            # 스프린트 3 상세 정보
@risk                # 리스크 목록
@blocker             # 블로커 이슈
@next                # 다음 액션 아이템
```

### 분석 명령
```bash
@analyze "인증 시스템" --full                    # 통합 분석 (정의 누락 + 추천 + 엣지 케이스)
@detect:missing "로그인 기능"                     # 정의 누락 감지
@recommend "데이터베이스" --context:"PostgreSQL"  # 기술 추천
@edge-case "결제 프로세스"                        # 엣지 케이스 탐색
```

---

## 에이전트 사용법

### 12개 전문 에이전트

| ID | 에이전트 | 역할 | 사용 시점 |
|----|---------|------|-----------|
| SA | Solution Architect | 아키텍처 설계 | 프로젝트 초기, 기술 결정 |
| RA | Requirements Analyst | 요구사항 분석 | 기능 정의, 스토리 작성 |
| BE | Backend Engineer | 백엔드 구현 | API, 비즈니스 로직 |
| FE | Frontend Engineer | 프론트엔드 구현 | UI/UX, 컴포넌트 |
| DBA | Database Architect | DB 설계 | 스키마, 마이그레이션 |
| DO | DevOps Engineer | 인프라/배포 | CI/CD, 환경 구성 |
| QA | QA Engineer | 품질 보증 | 테스트 전략, 검증 |
| SEC | Security Specialist | 보안 검토 | 보안 리뷰, 인증 |
| PERF | Performance Engineer | 성능 최적화 | 병목 분석 |
| DOC | Tech Writer | 문서화 | API 문서, 유지보수 |
| UX | UX Designer | UX 설계 | UI 디자인, 프로토타입 |
| INT | Integration Specialist | 외부 연동 | API 통합 |

### 에이전트 호출 패턴

#### 단일 에이전트 위임
```bash
@agent:SA 인증 시스템 아키텍처 설계
@agent:BE 사용자 프로필 API 구현
@agent:QA 인증 테스트 케이스 작성
```

#### 병렬 실행
```bash
@parallel:BE,FE 사용자 대시보드 기능 구현
@parallel:SA,DBA 데이터베이스 설계 및 마이그레이션
```

#### 순차 실행
```bash
@sequence:RA→SA→BE 결제 시스템: 분석 → 설계 → 구현
@sequence:BE→QA→DO API 개발 → 테스트 → 배포
```

#### 결과 리뷰
```bash
@review:BE 백엔드 구현 검토
@review:SA 아키텍처 설계 검토
```

---

## 실전 예제

### Example 1: 새 기능 개발 (Full Cycle)

```bash
# 1. 요구사항 분석
@agent:RA "지식 그래프 시각화 기능" 요구사항 분석

# 2. 정의 누락 감지
@detect:missing "지식 그래프 시각화"

# 3. 아키텍처 설계
@agent:SA Three.js 기반 3D 시각화 아키텍처 설계

# 4. 기술 스택 추천
@recommend "3D 라이브러리" --context:"Three.js vs D3.js"

# 5. 병렬 구현
@parallel:BE,FE,DBA 지식 그래프 기능 구현

# 6. 엣지 케이스 검토
@edge-case "3D 렌더링 성능"

# 7. 테스트 및 배포
@sequence:QA→SEC→DO 테스트 → 보안 검토 → 배포
```

### Example 2: 버그 수정

```bash
# 1. 문제 분석
@analyze "PDF 업로드 실패" --full

# 2. 수정 작업
@agent:BE PDF 업로드 버그 수정

# 3. 테스트
@agent:QA PDF 업로드 회귀 테스트

# 4. 검증
@review:BE 수정 코드 리뷰
```

### Example 3: 성능 최적화

```bash
# 1. 병목 분석
@agent:PERF API 응답 시간 프로파일링

# 2. 추천사항 도출
@recommend "쿼리 최적화" --context:"N+1 문제"

# 3. 병렬 최적화
@parallel:BE,DBA 쿼리 최적화 및 인덱스 추가

# 4. 성능 검증
@agent:PERF 최적화 전후 성능 비교
```

### Example 4: 보안 강화

```bash
# 1. 보안 분석
@analyze "인증 시스템" --full

# 2. 엣지 케이스 (보안 관점)
@edge-case "토큰 만료 시나리오"

# 3. 보안 강화
@sequence:SEC→BE 보안 정책 수립 → 구현

# 4. 검증
@agent:SEC 침투 테스트 및 취약점 스캔
```

---

## KPM 워크플로우

### 프로젝트 킥오프

```
1. @agent:RA 요구사항 수집 및 분석
2. @agent:SA 아키텍처 초안 작성
3. PM: 검토 및 승인
4. @parallel:BE,FE,DBA 환경 구성
```

### 스프린트 실행

```
1. PM: 스프린트 백로그 확정
2. @agent:[담당] 각 태스크 실행
3. @agent:QA 테스트 실행
4. PM: 스프린트 리뷰
```

### 릴리즈

```
1. @agent:QA 최종 테스트
2. @agent:SEC 보안 검토
3. @agent:DO 배포 준비
4. PM: Go/No-Go 결정
5. @agent:DO 배포 실행
```

---

## PM 분석 역량 활용

### ① 정의 누락 감지 (Missing Definition Detection)

**목적**: 불완전한 명세로 인한 재작업 방지

**예제**:
```bash
@detect:missing "사용자 인증"

# 출력:
## 🔍 Missing Definition Report

### Critical (블로커)
- [MD-001] "인증 실패 시 동작" - 재시도 로직 미정의
- [MD-002] "세션 만료 시간" - 구체적 시간 누락

### Warning (명확화 필요)
- [MD-003] "빠른 응답" → 구체적 SLA (예: 2초 이내)
```

### ② 더 나은 기술/방법 제안 (Recommendation Engine)

**목적**: 최적의 기술적 선택 제시

**예제**:
```bash
@recommend "세션 저장소" --context:"Redis vs PostgreSQL"

# 출력:
## 💡 Recommendation Report

### Option A: Redis ⭐ 권장
| 기준 | 점수 | 근거 |
|------|------|------|
| 성능 | 9/10 | In-memory 캐시로 매우 빠름 |
| 확장성 | 8/10 | 클러스터 지원 우수 |
| 비용 | 6/10 | 별도 서버 필요 |

**장점**:
- 초고속 읽기/쓰기
- TTL 자동 처리
- 세션 관리에 최적화

**단점**:
- 영구 저장 아님 (필요시 RDB 백업)
- 추가 인프라 비용

### Option B: PostgreSQL
...

### PM 의견
짧은 TTL의 세션 데이터는 Redis,
영구 저장이 필요한 사용자 데이터는 PostgreSQL 조합 권장
```

### ③ 엣지 케이스 발견 (Edge Case Discovery)

**목적**: 예외 상황 사전 식별로 런타임 장애 예방

**예제**:
```bash
@edge-case "PDF 업로드"

# 출력:
## ⚠️ Edge Case Report: PDF 업로드

### Critical (반드시 처리)
| ID | 시나리오 | 현재 동작 | 예상 영향 | 권장 처리 |
|----|---------|----------|----------|------------|
| EC-001 | 파일 크기 50MB 초과 | 미정의 | 서버 과부하 | 최대 크기 제한 (10MB) |
| EC-002 | 업로드 중 네트워크 끊김 | 타임아웃 | 불완전 업로드 | 재개 가능한 업로드 |

### High (처리 권장)
| EC-003 | 동시 업로드 100개 | 미테스트 | 서버 다운 | 큐잉 시스템 |

### 담당 에이전트 할당
- EC-001 → @agent:BE 파일 크기 검증
- EC-002 → @agent:FE 재개 가능 업로드 UI
- EC-003 → @agent:DO 로드 밸런싱 및 큐
```

---

## 품질 게이트

각 단계별 통과 조건:

| Gate | 조건 |
|------|------|
| Design Review | SA 승인, 아키텍처 문서 완료 |
| Code Complete | 테스트 커버리지 80%+, 린터 통과 |
| QA Sign-off | 모든 테스트 통과, 버그 0 |
| Security Review | SEC 승인, 취약점 0 |
| Release Ready | 모든 게이트 통과 |

---

## FAQ

### Q1: 어떤 에이전트를 언제 사용해야 하나요?

**A**: 작업 성격에 따라 선택:
- **설계 단계**: SA, RA, UX
- **구현 단계**: BE, FE, DBA
- **검증 단계**: QA, SEC, PERF
- **배포 단계**: DO

### Q2: @parallel vs @sequence 차이는?

**A**:
- `@parallel`: 독립적인 작업을 동시 실행 (예: BE와 FE 동시 개발)
- `@sequence`: 의존 관계가 있는 작업을 순차 실행 (예: 설계 → 구현 → 테스트)

### Q3: @analyze --full은 언제 사용하나요?

**A**: 중요한 기능이나 복잡한 시스템을 시작하기 전에 사용:
- 정의 누락 감지
- 기술 추천
- 엣지 케이스 발견

을 한 번에 수행하여 사전에 리스크를 줄입니다.

### Q4: 기존 Playwright 테스트는 어떻게 되나요?

**A**: `tests/e2e/*` 테스트는 그대로 유지됩니다.
- KPM QA 에이전트가 테스트 전략을 수립하고
- 실행은 기존 `npx playwright test` 명령 사용

### Q5: BMad 워크플로우는 어떻게 되나요?

**A**: BMad는 제거되었지만, 기존 워크플로우는 KPM 명령으로 대체:
- `/bmad:workflows:sprint-planning` → `@status`, `@sprint [n]`
- `/bmad:workflows:code-review` → `@review:[ID]`
- `/bmad:workflows:dev-story` → `@agent:[ID]` + `@parallel/sequence`

---

## 추가 리소스

- **상세 가이드**: `docs/kpm/SKILL.md`
- **에이전트별 상세**: `docs/kpm/references/agents/*.md`
- **워크플로우 패턴**: `docs/kpm/references/workflows/*.md`
- **자동화 스크립트**: `docs/kpm/scripts/`

---

**Happy Orchestrating! 🎯**
