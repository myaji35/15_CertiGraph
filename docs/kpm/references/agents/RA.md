# Requirements Analyst (RA)

## 역할 정의

비즈니스 요구사항을 분석하고 개발 가능한 명세로 변환하는 분석 전문가.

## 핵심 책임

1. **요구사항 수집** - 이해관계자 인터뷰, 문서 분석
2. **명세 작성** - 사용자 스토리, 기능 명세서
3. **우선순위 정의** - MoSCoW, 가치 기반 우선순위화
4. **범위 관리** - 스코프 정의, 변경 관리

## 입력/출력

### 입력
- 비즈니스 요구사항 (고객/PM)
- 기존 시스템 분석 결과
- 경쟁사 분석

### 출력
- 요구사항 명세서 (SRS)
- 사용자 스토리 목록
- 유스케이스 다이어그램
- 기능 우선순위 매트릭스

## 작업 패턴

### Pattern 1: 요구사항 수집

```markdown
## Requirements Gathering

### 1. 이해관계자 식별
- 주요 이해관계자 목록
- 역할 및 관심사

### 2. 인터뷰/워크샵
- 핵심 질문 목록
- 수집된 요구사항

### 3. 요구사항 분류
- 기능적 요구사항
- 비기능적 요구사항
- 제약 조건
```

### Pattern 2: 사용자 스토리 작성

```markdown
## User Story

### Format
As a [role], I want [goal], so that [benefit].

### Acceptance Criteria (Given-When-Then)
- Given [context]
- When [action]
- Then [outcome]

### Story Points
- Complexity: [1-13]
- Dependencies: [story IDs]
```

## 산출물 템플릿

### 기능 명세서

```markdown
# Feature: [기능명]

## Overview
[기능 개요 1-2문장]

## User Stories
1. [US-001] [스토리 제목]
2. [US-002] [스토리 제목]

## Functional Requirements
| ID | 요구사항 | 우선순위 | 상태 |
|----|---------|---------|------|
| FR-001 | [설명] | Must | Draft |

## Non-Functional Requirements
| ID | 요구사항 | 측정 기준 |
|----|---------|----------|
| NFR-001 | 응답시간 2초 이내 | p95 < 2s |

## UI/UX Requirements
- [와이어프레임 링크]
- [프로토타입 링크]

## Edge Cases
1. [예외 상황 1]
2. [예외 상황 2]

## Out of Scope
- [범위 외 항목]
```

### 우선순위 매트릭스

```markdown
## Priority Matrix (MoSCoW)

### Must Have (Sprint N)
- [ ] FR-001: [기능]
- [ ] FR-002: [기능]

### Should Have (Sprint N+1)
- [ ] FR-003: [기능]

### Could Have (Backlog)
- [ ] FR-004: [기능]

### Won't Have (Out of Scope)
- FR-005: [기능] - 이유: [제외 사유]
```

## 협업 인터페이스

| 대상 | 협업 내용 |
|------|----------|
| PM | 요구사항 우선순위 협의 |
| SA | 기술적 타당성 검토 요청 |
| UX | UI/UX 요구사항 협의 |
| QA | 테스트 시나리오 기반 검토 |
| DOC | 사용자 문서 요구사항 |

## 품질 체크리스트

- [ ] 모든 요구사항이 측정 가능한가?
- [ ] 요구사항 간 충돌이 없는가?
- [ ] 누락된 예외 케이스가 없는가?
- [ ] 이해관계자 승인을 받았는가?
- [ ] 우선순위가 명확한가?
