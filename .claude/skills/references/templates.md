# BMAD 문서 템플릿 모음

문서 작성 시 해당 섹션의 템플릿을 참조하세요.

---

## 1. workflow-status.yaml

```yaml
# docs/workflow-status.yaml
# 프로젝트 워크플로우 상태 추적

project:
  name: "[프로젝트명]"
  track: "bmad_method"      # quick_flow | bmad_method | enterprise
  field_type: "greenfield"  # greenfield | brownfield
  created_at: "YYYY-MM-DD"
  
phases:
  phase_0:                  # Brownfield만
    status: "skipped"       # skipped | completed
    
  phase_1:
    status: "not_started"   # not_started | in_progress | completed
    workflows:
      - name: "workflow-init"
        status: "not_started"
        completed_at: null
      - name: "clarify-requirements"
        status: "not_started"
        completed_at: null
        
  phase_2:
    status: "not_started"
    workflows:
      - name: "create-prd"
        status: "not_started"
        completed_at: null
      - name: "frontend-spec"
        status: "not_started"
        completed_at: null
        
  phase_3:
    status: "not_started"
    workflows:
      - name: "architecture"
        status: "not_started"
        completed_at: null
        
  phase_4:
    status: "not_started"
    workflows:
      - name: "sprint-planning"
        status: "not_started"
        completed_at: null

current_agent: "analyst"
next_recommended: "*bmad-init"
```

---

## 2. clarified-requirements.md

```markdown
# 확정된 요구사항

## 프로젝트 개요
| 항목 | 내용 |
|------|------|
| **프로젝트명** | [이름] |
| **트랙** | [Quick Flow / BMad Method / Enterprise] |
| **타입** | [Greenfield / Brownfield] |
| **MVP 목표일** | [YYYY-MM-DD] |

---

## 핵심 기능 (Must-Have, P0)

| ID | 기능 | 상세 설명 |
|----|------|----------|
| F01 | [기능명] | [설명] |
| F02 | [기능명] | [설명] |

---

## 중요 기능 (Should-Have, P1)

| ID | 기능 | 상세 설명 |
|----|------|----------|
| F03 | [기능명] | [설명] |

---

## 선택 기능 (Nice-to-Have, P2)

| ID | 기능 | 상세 설명 |
|----|------|----------|
| F04 | [기능명] | [설명] |

---

## 제외 범위 (Out of Scope)

| 기능 | 제외 이유 | 예정 Phase |
|------|----------|-----------|
| [기능] | [이유] | Phase 2 |

---

## 기술적 결정사항

| 항목 | 결정 | 근거 |
|------|------|------|
| 프레임워크 | [결정] | [근거] |
| 데이터베이스 | [결정] | [근거] |
| 인증 방식 | [결정] | [근거] |

---

## 리스크 및 가정

### 리스크
| ID | 리스크 | 확률 | 영향 | 대응 전략 |
|----|--------|------|------|----------|
| R1 | [리스크] | 🟠 Medium | 🔴 High | [대응] |

### 가정
| ID | 가정 | 검증 방법 |
|----|------|----------|
| A1 | [가정] | [검증방법] |

---

## 명확화 Q&A

| # | 질문 | 답변 | 결정일 |
|---|------|------|--------|
| 1 | [질문] | [답변] | YYYY-MM-DD |
```

---

## 3. sprint-status.yaml

```yaml
# docs/sprint-status.yaml
# Sprint 진행 상태 추적

sprint:
  number: 1
  name: "[Sprint 이름]"
  start_date: "YYYY-MM-DD"
  end_date: "YYYY-MM-DD"
  goal: "[Sprint 목표]"

summary:
  total_stories: 0
  completed: 0
  in_progress: 0
  not_started: 0
  blocked: 0
  progress_percent: 0

epics:
  - id: "EPIC-001"
    title: "[Epic 제목]"
    status: "not_started"  # not_started | in_progress | completed
    stories:
      - id: "STORY-001"
        title: "[Story 제목]"
        status: "not_started"  # not_started | in_progress | review | done | blocked
        priority: "P0"
        estimated_hours: 2
        actual_hours: null
        assignee: null
        depends_on: null
        
      - id: "STORY-002"
        title: "[Story 제목]"
        status: "not_started"
        priority: "P0"
        estimated_hours: 3
        actual_hours: null
        assignee: null
        depends_on: "STORY-001"

blockers: []
  # - story_id: "STORY-XXX"
  #   reason: "[차단 이유]"
  #   since: "YYYY-MM-DD"

next_story: "STORY-001"
next_command: "*dev-story STORY-001"
```

---

## 4. Story 파일 템플릿

```markdown
# STORY-XXX: [제목]

## 메타데이터
| 항목 | 값 |
|------|-----|
| **Epic** | EPIC-XXX: [Epic 제목] |
| **우선순위** | P0 / P1 / P2 |
| **예상 시간** | X시간 |
| **선행 Story** | 없음 / STORY-XXX |
| **상태** | Not Started |

---

## 1. 컨텍스트

### 1.1 비즈니스 컨텍스트
[왜 이 기능이 필요한지]

### 1.2 관련 문서
- **PRD**: `docs/prd.md` - Section X.X
- **Architecture**: `docs/architecture.md` - Section X.X
- **Frontend Spec**: `docs/frontend-spec.md` - Section X.X

### 1.3 사용자 스토리
> **AS A** [역할]  
> **I WANT TO** [원하는 것]  
> **SO THAT** [이유/가치]

---

## 2. 요구사항

### 2.1 기능 요구사항
1. [요구사항 1]
2. [요구사항 2]

### 2.2 비기능 요구사항
- [성능, 보안 등]

---

## 3. 기술 가이드

### 3.1 생성/수정할 파일
```
app/
├── controllers/
│   └── [파일명]    # [생성/수정]
├── models/
│   └── [파일명]    # [생성/수정]
└── views/
    └── [폴더]/
        └── [파일명]  # [생성/수정]
```

### 3.2 구현 상세
[구체적인 구현 가이드, 코드 스니펫]

### 3.3 디자인 토큰 적용
[적용해야 할 디자인 토큰 안내]

### 3.4 참고 패턴
[아키텍처 문서의 관련 패턴 참조]

---

## 4. Acceptance Criteria

### AC-1: [조건 제목]
- [ ] [테스트 가능한 조건]
- [ ] [테스트 가능한 조건]

### AC-2: [조건 제목]
- [ ] [테스트 가능한 조건]

---

## 5. 테스트 시나리오

### 5.1 Happy Path
```gherkin
Scenario: [시나리오명]
  Given [전제 조건]
  When [동작]
  Then [예상 결과]
```

### 5.2 Error Cases
```gherkin
Scenario: [에러 시나리오명]
  Given [전제 조건]
  When [잘못된 동작]
  Then [에러 처리 결과]
```

### 5.3 테스트 파일 위치
- `test/controllers/[파일명]_test.rb`
- `test/system/[파일명]_test.rb`

---

## 6. Dev Notes
<!-- 개발자가 구현 후 작성 -->
```
구현일: 
구현자:
소요 시간:
특이사항:
```

---

## 7. QA Notes
<!-- QA가 리뷰 후 작성 -->
```
리뷰일:
리뷰어:
결과: Pass / Fail
피드백:
```
```

---

## 5. ADR (Architecture Decision Record)

```markdown
# ADR-XXX: [결정 제목]

## 메타데이터
| 항목 | 값 |
|------|-----|
| **상태** | Proposed / Accepted / Deprecated / Superseded |
| **작성일** | YYYY-MM-DD |
| **작성자** | [이름] |
| **관련 Story** | STORY-XXX (있으면) |

---

## 컨텍스트
[결정이 필요한 배경과 상황을 설명]

---

## 결정
[내린 결정을 명확하게 서술]

---

## 근거
[결정의 이유를 상세히 설명]

1. [근거 1]
2. [근거 2]
3. [근거 3]

---

## 결과

### 긍정적 영향
- [장점 1]
- [장점 2]

### 부정적 영향 / 트레이드오프
- [단점 1]
- [단점 2]

---

## 고려한 대안

### 대안 1: [대안명]
- **설명**: [대안 설명]
- **장점**: [장점]
- **단점**: [단점]
- **선택하지 않은 이유**: [이유]

### 대안 2: [대안명]
[동일 구조]

---

## 관련 문서
- `docs/architecture.md` Section X
- `docs/prd.md` Section Y
- [외부 참고 링크]

---

## 변경 이력
| 날짜 | 변경 내용 | 작성자 |
|------|----------|--------|
| YYYY-MM-DD | 초안 작성 | [이름] |
```

---

## 6. design-tokens.css

```css
/* === Design Tokens === */
/* BMAD UX Designer가 생성 */

:root {
  /* === Colors === */
  /* Primary */
  --color-primary: #3B82F6;
  --color-primary-dark: #2563EB;
  --color-primary-light: #93C5FD;
  
  /* Semantic */
  --color-success: #10B981;
  --color-error: #EF4444;
  --color-warning: #F59E0B;
  --color-info: #3B82F6;
  
  /* Neutral */
  --color-bg: #FFFFFF;
  --color-bg-secondary: #F9FAFB;
  --color-text: #1F2937;
  --color-text-muted: #6B7280;
  --color-border: #E5E7EB;
  
  /* === Typography === */
  --font-sans: 'Pretendard', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;
  
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
  
  /* === Spacing === */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
  --spacing-2xl: 3rem;
  
  /* === Border Radius === */
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-xl: 1rem;
  --radius-full: 9999px;
  
  /* === Shadows === */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);
  
  /* === Transitions === */
  --transition-fast: 150ms ease;
  --transition-normal: 200ms ease;
  --transition-slow: 300ms ease;
  
  /* === Z-Index === */
  --z-dropdown: 1000;
  --z-modal: 1100;
  --z-toast: 1200;
}
```

---

## 7. CLAUDE.md (프로젝트 학습 파일)

```markdown
# CLAUDE.md

## Project Context

### Overview
- **프로젝트명**: [프로젝트명]
- **기술 스택**: [주요 기술]
- **시작일**: YYYY-MM-DD
- **상태**: Active / Maintenance / Archived

### Key Documents
- PRD: `docs/prd.md`
- Architecture: `docs/architecture.md`
- Frontend Spec: `docs/frontend-spec.md`

---

## Learned Patterns

### 🔐 Security
<!-- 보안 관련 학습 패턴 -->

| ID | 패턴 | 설명 | 발견일 |
|----|------|------|--------|
| SEC-001 | Parameterized Query | SQL Injection 방지를 위해 항상 사용 | YYYY-MM-DD |

### ⚡ Performance
<!-- 성능 관련 학습 패턴 -->

| ID | 패턴 | 설명 | 발견일 |
|----|------|------|--------|
| PERF-001 | N+1 방지 | includes/preload 사용 | YYYY-MM-DD |

### 🎨 Code Quality
<!-- 코드 품질 관련 패턴 -->

| ID | 패턴 | 설명 | 발견일 |
|----|------|------|--------|
| QUAL-001 | Design Token | 색상/간격 하드코딩 금지 | YYYY-MM-DD |

### 🏗️ Architecture
<!-- 아키텍처 관련 패턴 -->

| ID | 패턴 | 설명 | 발견일 |
|----|------|------|--------|
| ARCH-001 | Service Object | 복잡한 비즈니스 로직 분리 | YYYY-MM-DD |

---

## Known Issues

### 🔴 Active Issues
<!-- 현재 활성 이슈 -->

#### [Category] Issue-XXX: [제목]
- **발견일**: YYYY-MM-DD
- **Story**: STORY-XXX
- **심각도**: Critical / High / Medium / Low
- **설명**: [이슈 설명]
- **원인**: [근본 원인]
- **해결책**: [진행 중인 해결 방법]

### ✅ Resolved Issues
<!-- 해결된 이슈 (참고용) -->

#### [Category] Issue-XXX: [제목]
- **발견일**: YYYY-MM-DD
- **해결일**: YYYY-MM-DD
- **Story**: STORY-XXX
- **설명**: [이슈 설명]
- **해결책**: [적용된 해결 방법]
- **전파**: ✅/❌ 다른 프로젝트 반영

---

## Team Conventions

### Code Style
- [컨벤션 1]
- [컨벤션 2]

### Git Workflow
- Branch naming: `feature/STORY-XXX-description`
- Commit format: `[STORY-XXX] Brief description`

### Review Guidelines
- PR 전 self-review 필수
- AC 체크리스트 첨부

---

## Cross-Project Learnings

### 📥 Imported (다른 프로젝트에서 가져옴)
| 출처 | 내용 | 적용일 |
|------|------|--------|
| [프로젝트A] | [학습 내용] | YYYY-MM-DD |

### 📤 Exported (다른 프로젝트로 전파)
| 대상 | 내용 | 전파일 |
|------|------|--------|
| [프로젝트B] | [학습 내용] | YYYY-MM-DD |

---

## Changelog

| 날짜 | 변경 내용 | 작성자 |
|------|----------|--------|
| YYYY-MM-DD | 초기 생성 | BMAD Agent |
```

---

## 8. learnings-export.md (학습 내보내기)

```markdown
# Learnings Export

## Metadata
- **프로젝트**: [프로젝트명]
- **내보내기 날짜**: YYYY-MM-DD
- **내보내기 범위**: All / Critical / [Category]
- **작성자**: BMAD QA Agent

---

## 🔴 Critical Issues (필수 반영)

이 섹션의 내용은 모든 프로젝트에 반영을 권장합니다.

### Issue-XXX: [제목]
```
카테고리: Security / Performance / Quality / Architecture
심각도: Critical
원본 프로젝트: [프로젝트명]
발견일: YYYY-MM-DD

설명:
[상세 설명]

원인:
[근본 원인 분석]

해결책:
[구체적인 해결 방법]

예방책:
[재발 방지 방법]

코드 예시:
[Before]
...

[After]
...
```

---

## 🟠 Best Practices (권장 반영)

### Practice-XXX: [제목]
```
카테고리: [카테고리]
적용 대상: [언어/프레임워크]

설명:
[베스트 프랙티스 설명]

적용 방법:
[구체적인 적용 방법]

효과:
[적용 시 기대 효과]
```

---

## 🟡 Useful Patterns (참고)

### Pattern-XXX: [제목]
```
상황: [이 패턴이 유용한 상황]
해결: [패턴 설명]
예시: [코드 또는 설명]
```

---

## 적용 가이드

### 새 프로젝트에 적용하기

1. **CLAUDE.md 생성/열기**
   ```bash
   # 프로젝트 루트에서
   touch CLAUDE.md
   ```

2. **Critical Issues 복사**
   - `Known Issues > Resolved Issues` 섹션에 추가
   - 프로젝트 컨텍스트에 맞게 수정

3. **Best Practices 적용**
   - `Learned Patterns` 섹션에 추가
   - 코드 리뷰 체크리스트에 반영

4. **검증**
   - `*learn-sync` 실행하여 정합성 확인

### 체크리스트
- [ ] Critical Issues 모두 검토
- [ ] 해당 프로젝트에 적용 가능한 항목 선별
- [ ] CLAUDE.md에 추가
- [ ] 팀에 공유
```
