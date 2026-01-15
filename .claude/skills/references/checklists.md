# BMAD Phase별 체크리스트

각 Phase 완료 시 해당 체크리스트로 검증하세요.

---

## Phase 1: Analysis 완료 체크리스트

### 필수 조건
```
□ workflow-status.yaml 생성됨
□ 프로젝트 트랙 결정됨 (Quick Flow / BMad Method / Enterprise)
□ 프로젝트 타입 결정됨 (Greenfield / Brownfield)
□ clarified-requirements.md 작성됨
```

### 요구사항 명확화
```
□ 모호한 요구사항에 대한 질문/답변 완료
□ 핵심 기능 (P0) 목록 확정
□ MVP 범위 명확히 정의됨
□ 제외 범위 (Out of Scope) 문서화됨
```

### 기술적 결정
```
□ 주요 기술 스택 결정됨
□ 결정 근거 문서화됨
□ 리스크 식별 완료
```

### 다음 단계 준비
```
□ Handoff Prompt 제시됨
□ 다음 에이전트 (PM) 호출 안내됨
```

---

## Phase 2: Planning 완료 체크리스트

### PRD 품질
```
□ prd.md 작성됨
□ Executive Summary 포함
□ Target Users / Personas 정의됨
□ User Stories 작성됨 (ID, Actor, Story, AC, Priority)
□ Functional Requirements 상세화됨
□ Non-Functional Requirements 정의됨
□ Success Metrics (KPIs) 설정됨
□ MVP Scope (In/Out) 명확함
```

### User Stories 품질
```
□ 각 Story에 고유 ID 있음
□ Acceptance Criteria가 테스트 가능함
□ 우선순위 (P0/P1/P2) 지정됨
□ 의존성 명시됨
```

### Frontend Spec (UI 프로젝트만)
```
□ frontend-spec.md 작성됨
□ 디자인 토큰 정의됨 (색상, 타이포, 간격)
□ 컴포넌트 명세 포함
□ 화면 흐름도 작성됨
□ 반응형 브레이크포인트 정의됨
□ 접근성 요구사항 명시됨
□ design-tokens.css 생성됨
```

### stitch 연동 (디자인 목업 있는 경우)
```
□ /stitch 폴더 이미지 분석됨
□ 색상 팔레트 추출됨
□ 컴포넌트 스타일 매핑됨
```

### 다음 단계 준비
```
□ Handoff Prompt 제시됨
□ 다음 에이전트 (Architect) 호출 안내됨
```

---

## Phase 3: Solutioning 완료 체크리스트

### 기술 스택
```
□ architecture.md 작성됨
□ 모든 기술 선택에 대한 근거 문서화됨
□ 대안 분석 포함됨
```

### 시스템 아키텍처
```
□ High-Level Architecture 다이어그램 (Mermaid)
□ 컴포넌트 다이어그램
□ 데이터 플로우 다이어그램
□ 배포 아키텍처 (필요시)
```

### 데이터 모델
```
□ ERD 작성됨
□ 테이블 스키마 정의됨
□ 관계(Relationship) 명시됨
□ 인덱스 전략 포함됨
```

### API 설계
```
□ 엔드포인트 목록 정의됨
□ HTTP 메서드 명시됨
□ 인증 방식 정의됨
□ 요청/응답 형식 (필요시)
```

### 디렉토리 구조
```
□ 프로젝트 디렉토리 구조 정의됨
□ 레이어 분리 명확함 (Controller/Service/Model)
□ 파일 네이밍 컨벤션 정의됨
```

### 보안 고려사항
```
□ 인증/인가 방식 정의됨
□ 데이터 보호 방안 명시됨
□ 보안 체크리스트 포함됨
```

### 다음 단계 준비
```
□ Handoff Prompt 제시됨
□ 다음 에이전트 (SM) 호출 안내됨
```

---

## Phase 4: Implementation 완료 체크리스트

### Sprint 계획 (SM)
```
□ sprint-status.yaml 생성됨
□ Epic이 Story로 분해됨
□ 의존성 순서 정렬됨
□ 예상 시간 산정됨
```

### Story 파일 품질
```
□ 모든 Story가 개별 파일로 생성됨
□ 각 Story에 충분한 컨텍스트 포함
□ Acceptance Criteria가 테스트 가능함
□ 기술 가이드 포함 (파일 목록, 코드 패턴)
□ 테스트 시나리오 포함
```

### 구현 (Dev)
```
□ 모든 Acceptance Criteria 충족
□ 아키텍처 패턴 준수
□ 디자인 토큰 사용 (하드코딩 없음)
□ 테스트 코드 작성됨
□ 테스트 통과 확인
□ Dev Notes 작성됨
```

### 코드 리뷰 (QA)
```
□ AC 검증 완료
□ 코드 품질 검토 완료
□ 보안 검토 완료
□ 테스트 검증 완료
□ QA Notes 작성됨
```

### Story 완료
```
□ Story 상태가 "Done"으로 업데이트됨
□ sprint-status.yaml 업데이트됨
```

---

## MVP 완료 체크리스트

### 기능 완료
```
□ 모든 P0 Story 완료
□ 모든 P1 Story 완료 (또는 의도적 제외)
□ 통합 테스트 통과
```

### 문서 완료
```
□ README.md 최신 상태
□ 설치/실행 가이드 포함
□ 환경 변수 목록 문서화
□ API 문서 (필요시)
```

### 배포 준비
```
□ 환경 설정 완료 (Production)
□ 시크릿/API 키 설정
□ 데이터베이스 마이그레이션 준비
□ 모니터링/로깅 설정
```

### 품질 보증
```
□ 보안 취약점 스캔 완료
□ 성능 테스트 완료 (필요시)
□ 크로스 브라우저 테스트 (필요시)
□ 모바일 반응형 테스트
```

---

## Quick Reference: Phase 전환 조건

| From | To | 전환 조건 |
|------|-----|----------|
| Phase 1 | Phase 2 | clarified-requirements.md 완료 |
| Phase 2 | Phase 3 | prd.md + (frontend-spec.md) 완료 |
| Phase 3 | Phase 4 | architecture.md 완료 |
| Phase 4 | 완료 | 모든 Story Done + QA Pass |

---

## 트랙별 필수 Phase

| Phase | Quick Flow | BMad Method | Enterprise |
|-------|------------|-------------|------------|
| Phase 0 | - | - | Brownfield만 |
| Phase 1 | ⚡ 간소화 | ✅ 필수 | ✅ 필수 |
| Phase 2 | ⚡ 간소화 | ✅ 필수 | ✅ 필수 |
| Phase 3 | ❌ 생략 | ✅ 필수 | ✅ 필수 |
| Phase 4 | ✅ 필수 | ✅ 필수 | ✅ 필수 |
