# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ExamsGraph** (AI 자격증 마스터) - An AI-powered certification exam study platform that transforms static PDF exam materials into a dynamic learning experience using Knowledge Graph technology to identify and visualize knowledge gaps.

### Project Status
**Phase 1 완료** - Rails 7.2.3 프로덕션 운영 중 (18 Epics 구현 완료)

## Tech Stack (Current Implementation)

### Backend & Frontend (Rails Monolith)
- Ruby 3.3.0 + Rails 7.2.3
- Hotwire: Turbo & Stimulus (SPA-like UX)
- Tailwind CSS 2.0 (tailwindcss-rails)
- Importmap for JavaScript management

### Authentication & Authorization
- Devise (email/password, OAuth)
- devise-two-factor (TOTP with Google Authenticator)
- OAuth: Google, Naver

### Background Jobs & Storage
- Solid Queue (Rails 8 backport)
- Active Storage (file uploads)
- Service Objects pattern

### Databases (Current & Planned)
- **Current**: SQLite (development/test)
- **Planned**: PostgreSQL with pgvector (embeddings)
- **Planned**: Neo4j AuraDB via REST API (Graph DB)
- **Planned**: Redis (caching, sessions)

### AI/ML (via API)
- Upstage Document Parse (OCR)
- OpenAI GPT-4o / GPT-4o-mini (reasoning)
- OpenAI text-embedding-3-small (embeddings)

## KPM Orchestrator - Project Management Framework

This project uses **KPM Orchestrator** for multi-agent project orchestration, strategic decision making, and comprehensive analysis.

### Core Principles
1. **PM은 오케스트레이터** - 직접 실행 대신 위임과 조율
2. **속도 > 완벽** - 빠른 피드백 루프로 점진적 개선
3. **명확한 R&R** - 각 에이전트의 책임 영역 명확화
4. **상태 투명성** - 모든 진행 상황 추적 가능

### PM Quick Commands
- `@status` - Project status overview
- `@risk` - Risk assessment
- `@blocker` - Blocker issues
- `@next` - Next action items
- `@sprint [n]` - Sprint n details
- `@deploy [env]` - Deployment checklist

### Agent Delegation
- `@agent:[ID] [task]` - Delegate to specific agent
- `@parallel:[ID,ID...]` - Parallel execution
- `@sequence:[ID→ID...]` - Sequential execution
- `@review:[ID]` - Review agent output

### 12 Specialized Agents

| ID | Agent | Role | When to Use |
|----|-------|------|-------------|
| SA | Solution Architect | Architecture design, tech stack decisions | Project kickoff, tech decisions |
| RA | Requirements Analyst | Requirements analysis, spec writing | Feature definition, story creation |
| BE | Backend Engineer | API, business logic, server implementation | Backend implementation |
| FE | Frontend Engineer | UI/UX implementation, components | Frontend implementation |
| DBA | Database Architect | Schema design, query optimization | DB design, migrations |
| DO | DevOps Engineer | CI/CD, infrastructure, deployment | Environment setup, deployment |
| QA | QA Engineer | Test strategy, quality assurance | Test writing, validation |
| SEC | Security Specialist | Security review, vulnerability analysis | Security review, auth implementation |
| PERF | Performance Engineer | Performance optimization, profiling | Bottleneck analysis, optimization |
| DOC | Tech Writer | Documentation, API docs | Documentation, maintenance |
| UX | UX Designer | User experience, interface design | UI design, prototyping |
| INT | Integration Specialist | External system integration | API integration, data sync |

**Detailed Agent Guides**: `docs/kpm/references/agents/*.md`

### PM Analysis Capabilities

#### ① 정의 누락 감지 (Missing Definition Detection)
```
@detect:missing [target]
```
Detects ambiguous expressions, undefined terms, missing error handling, etc.

**Checklist**:
- WHO - 행위자/역할 명확?
- WHAT - 대상/객체 정의?
- WHEN - 시점/조건 특정?
- WHERE - 위치/범위 한정?
- HOW - 방법/절차 기술?
- WHY - 목적/이유 설명?
- ERROR - 실패 시 처리 정의?

#### ② 더 나은 기술/방법 제안 (Recommendation Engine)
```
@recommend [area] --context:[current]
```
Suggests optimal technical choices and alternatives based on:
- Performance
- Scalability
- Maintainability
- Security
- Cost
- Team capability
- Time-to-market

#### ③ 엣지 케이스 발견 (Edge Case Discovery)
```
@edge-case [feature]
```
Identifies exception scenarios:
- Boundary values (0, 1, MAX, MAX+1)
- Empty states (null, empty, whitespace)
- Concurrency (race conditions)
- Timing (midnight, leap year, timezone)
- Permissions (unauthorized, expired)
- External failures (API timeout, DB down)
- Data edge cases (special chars, emoji, long text)
- State transitions (duplicate operations)

### Integrated Analysis
```
@analyze [target] --full

Execution order:
1. @detect:missing [target]
2. @recommend [target]
3. @edge-case [target]
4. Generate integrated report
```

### Example Usage

**Architecture Design**:
```
@agent:SA Design authentication system architecture
@analyze "authentication system" --full
```

**Parallel Implementation**:
```
@parallel:BE,FE,DBA Implement user profile feature
@review:BE Review backend implementation
```

**Sequential Workflow**:
```
@sequence:RA→SA→BE Payment system: analysis → design → implementation
```

**Analysis Commands**:
```
@detect:missing "login functionality"
@recommend "database choice" --context:"PostgreSQL vs MongoDB"
@edge-case "checkout process"
```

### Core Workflows

#### 1. Project Kickoff
```
1. @agent:RA Collect and analyze requirements
2. @agent:SA Draft architecture
3. PM: Review and approve
4. @parallel:BE,FE,DBA Environment setup
```

#### 2. Sprint Execution
```
1. PM: Confirm sprint backlog
2. @agent:[assigned] Execute tasks
3. @agent:QA Run tests
4. PM: Sprint review
```

#### 3. Release
```
1. @agent:QA Final testing
2. @agent:SEC Security review
3. @agent:DO Deployment preparation
4. PM: Go/No-Go decision
5. @agent:DO Execute deployment
```

**Detailed Workflows**: `docs/kpm/references/workflows/*.md`

### Quality Gates

| Gate | Criteria |
|------|----------|
| Design Review | SA approval, architecture doc complete |
| Code Complete | Test coverage 80%+, linter passes |
| QA Sign-off | All tests pass, 0 bugs |
| Security Review | SEC approval, 0 vulnerabilities |
| Release Ready | All gates passed |

### Reference Documentation
- **Main Guide**: `docs/kpm/SKILL.md`
- **Agent Details**: `docs/kpm/references/agents/[AGENT_ID].md`
- **Workflows**: `docs/kpm/references/workflows/`
- **Scripts**: `docs/kpm/scripts/`

### Testing Strategy
While KPM focuses on orchestration, testing is handled through:
- **QA Agent**: `@agent:QA` for test strategy and execution
- **Playwright Tests**: Existing `tests/e2e/*` specs remain functional
- **RSpec/Minitest**: Rails native testing (recommended for new tests)

## Core Domain Concepts

### Data Ingestion Pipeline
- PDF upload → Upstage OCR → Markdown conversion
- Image handling: crop + GPT-4o captioning
- Intelligent chunking with "지문 복제" (passage replication) for multi-question contexts

### Knowledge Graph
- Ontology: Subject → Chapter → Key Concept
- LLM extracts concepts and prerequisite relationships from questions
- Used for GraphRAG-based weakness analysis

### Test Engine
- Answer option randomization (anti-memorization)
- GraphRAG reasoning for error analysis
- Distinguishes concept gaps vs careless mistakes

### Visualization
- 3D brain map with React Three Fiber
- Node colors: Green (mastered), Red (weak), Gray (untested)
- Click-to-drill feature for focused practice

## Sprint Artifacts

Development artifacts are stored in `docs/sprint-artifacts/`.

## 코드 수정 프로토콜 (엄격 모드)

**모든 코드 수정 후 아래 절차를 반드시 수행:**

1. `cat [수정한 파일]` 로 변경사항 저장 확인
2. 관련 캐시 디렉토리 전체 삭제
3. 실행 중인 관련 프로세스 모두 종료 (`pkill -f` 또는 `lsof -i:[포트]`)
4. 클린 빌드 실행
5. 서버 새로 시작
6. 테스트 실행

**절대 하지 말 것:**
- 파일 수정 후 바로 "수정 완료"라고 보고하지 말 것
- 캐시 클리어 없이 테스트하지 말 것
- 이전 프로세스가 실행 중인 상태에서 테스트하지 말 것
