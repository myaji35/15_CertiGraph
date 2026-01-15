# BMad Method v6 Orchestration Plan - ExamsGraph

**Date:** 2026-01-14
**Project:** ExamsGraph (AI 자격증 마스터)
**Status:** Phase 3 → Phase 4 Transition
**Track:** BMad Method (Full Planning)

---

## Executive Summary

### Current Project State

**Rails Application Implemented (v1.0):**
- Rails 7.2.2 with Ruby 3.3.0 ✅
- Devise Authentication (Email + Google OAuth) ✅
- SQLite3 Database ✅
- Turbo + Stimulus + Tailwind CSS 2.x ✅
- PDF Parser Service (Local pdf-reader gem) ✅
- Study Sets CRUD ✅
- Exam Sessions (Mock Exam, Practice, Wrong Answer Review) ✅
- Ultra Modern UI (Glass morphism, 3D effects) ✅

**Missing PRD Features:**
- ❌ Payment System (Toss Payments - 10,000 KRW Season Pass)
- ❌ Knowledge Graph (Neo4j or SQLite JSON-based)
- ❌ GraphRAG-based Wrong Answer Analysis
- ❌ 3D Brain Map Visualization (Three.js)
- ❌ Background Job Processing (Sidekiq/Solid Queue)
- ❌ OpenAI API Integration (GPT-4o, Embeddings)

---

## 1. Project Scale & Track Decision

### Complexity Assessment

**Current Codebase:**
- 13 Models (User, StudySet, StudyMaterial, Question, ExamSession, etc.)
- 13 Controllers (including API v1 namespace)
- 4 Service Objects (PdfParser, JwtService, QNetApi, TestScoring)
- Complete Devise authentication flow
- Basic UI/UX framework

**Remaining Work:**
- Payment integration (~2 stories)
- AI/ML pipeline (PDF → Embeddings → Graph) (~4 stories)
- GraphRAG analysis (~2 stories)
- 3D Visualization (~2 stories)
- Background processing infrastructure (~1 story)

**Total Remaining Stories:** ~11-15 stories

### Track Selection: **BMad Method** ✅

**Justification:**
- ✅ 11-15 remaining stories (BMad Method target: 4-15 stories)
- ✅ New AI/ML modules (complex architecture)
- ✅ Payment system integration (requires careful planning)
- ✅ Knowledge Graph infrastructure (architectural decision needed)

**Not Quick Flow:** Too many complex stories
**Not Enterprise:** No compliance/security audit requirements

---

## 2. Field Type Analysis

### Brownfield Project (Hybrid)

**Rationale:**
- ✅ Rails 7.2.2 app exists with authentication & basic CRUD
- ✅ Database schema established
- ✅ UI framework in place
- ❌ No AI/ML pipeline exists (Greenfield for this component)

**Phase 0 (Discovery):** **OPTIONAL BUT RECOMMENDED**

**Recommended Actions:**
1. Document existing Rails architecture
2. Analyze current UI patterns
3. Map existing database schema
4. Identify integration points for AI pipeline

---

## 3. Current BMM Phase Status

### Phase 1: Analysis ✅ **COMPLETED**

**Artifacts:**
- ✅ `prd.md` (v1.2 - Last Updated: 2025-12-06)
- ✅ `docs/prd-validation-report-2025-12-06.md` (90% validation score)

**Quality Assessment:**
- PRD is comprehensive with 9 user stories
- All FR (Functional Requirements) mapped: FR-1 to FR-8
- NFR (Non-Functional Requirements) defined
- Clear MVP scope with in/out boundaries

### Phase 2: Planning ✅ **COMPLETED**

**Artifacts:**
- ✅ `docs/epics.md` (5 Epics, 21+ Stories)
- ✅ UX Design: `docs/rails-examsgraph-design-plan.md`
- ✅ Design System: `docs/design-system.md`

**Epic Structure:**
1. Epic 1: Foundation & Authentication ✅ (Implemented)
2. Epic 2: Study Set & Material Management ✅ (Implemented)
3. Epic 3: CBT Test Engine ✅ (Partially Implemented)
4. Epic 4: Analysis & Dashboard ❌ (Not Implemented)
5. Epic 5: Payment & Subscription ❌ (Not Implemented)

### Phase 3: Solutioning ✅ **COMPLETED**

**Artifacts:**
- ✅ `docs/architecture.md` (Original Next.js + FastAPI)
- ✅ `docs/architecture-rails.md` (Rails-specific, 100 lines)
- ✅ `docs/rails-implementation-plan.md`

**Architecture Status:**
- Rails architecture document exists but needs expansion
- Service layer patterns defined
- No detailed AI/ML pipeline architecture
- Missing: Background job flow, GraphRAG implementation details

### Phase 4: Implementation 🟡 **IN PROGRESS**

**Current Status:**
- Sprint artifacts: `docs/sprint-artifacts/tech-spec-mock-exam.md`
- Core features implemented (~60% of MVP)
- No sprint planning document
- No story tracking system

---

## 4. Gap Analysis: PRD vs. Implementation

### Implemented Features (Phase 1 MVP)

| Feature | PRD Requirement | Implementation Status | Files |
|---------|----------------|----------------------|-------|
| **Authentication** | FR-8: Email + Social Login | ✅ Devise + Google OAuth | `app/models/user.rb`, `devise/` |
| **Study Set CRUD** | FR-1: Study Set Management | ✅ Complete | `app/controllers/study_sets_controller.rb` |
| **PDF Upload** | FR-1: PDF Upload | ✅ Active Storage | `app/models/study_material.rb` |
| **PDF Parsing** | FR-2: Question Extraction | ✅ Local pdf-reader | `app/services/pdf_parser_service.rb` |
| **CBT Exam** | FR-5: Mock Exam | ✅ ExamSession | `app/controllers/exam_sessions_controller.rb` |
| **Wrong Answer Tracking** | FR-6: Wrong Answer Note | ✅ WrongAnswer model | `app/models/wrong_answer.rb` |
| **Dashboard** | FR-7: Basic Dashboard | ✅ Dashboard page | `app/controllers/dashboard_controller.rb` |

### Missing Critical Features (Phase 1 MVP)

| Feature | PRD Requirement | Priority | Complexity | Estimated Stories |
|---------|----------------|----------|------------|------------------|
| **Payment System** | FR-7: Toss Payments (10,000원) | P0 | Medium | 2 stories |
| **AI Embedding** | FR-3: OpenAI Embeddings | P0 | High | 2 stories |
| **Knowledge Graph** | FR-4: Neo4j or SQLite JSON | P0 | High | 3 stories |
| **GraphRAG Analysis** | FR-6: AI-based Weak Point Detection | P0 | Very High | 2 stories |
| **Background Jobs** | NFR: Async PDF Processing | P0 | Medium | 1 story |
| **3D Visualization** | Phase 3: Three.js Brain Map | P2 | Very High | 2 stories |

**Total Missing Stories:** 12 stories (10 P0, 2 P2)

---

## 5. BMad Phase Execution Plan

### Phase 3.5: Architecture Enhancement (Recommended)

**Goal:** Fill architectural gaps before implementation sprint

**Tasks:**
1. **Expand Architecture Document** (2 hours)
   - Detail AI/ML pipeline (PDF → Upstage → OpenAI → SQLite VSS)
   - Background job flow (Sidekiq vs Solid Queue decision)
   - GraphRAG service architecture
   - Payment integration flow (Toss Payments)

2. **Create Service Layer Design** (1 hour)
   - `EmbeddingService` (OpenAI text-embedding-3-small)
   - `GraphRagService` (SQLite JSON-based Knowledge Graph)
   - `PaymentService` (Toss Payments API wrapper)
   - `WeakPointAnalysisService` (GraphRAG + LLM)

3. **Database Schema Review** (30 minutes)
   - Add `embeddings` JSON column to `questions` table
   - Add `concept_graph` JSON column to `study_sets` table
   - Add `payment_status` and `valid_until` to `users` table

**Output:** `docs/architecture-rails-complete.md`

### Phase 4: Implementation Sprint Planning

**Sprint Structure:** 3 Sprints (2 weeks total)

#### Sprint 1: Payment & Infrastructure (Week 1, Days 1-3)

**Stories:**
1. **STORY-4.1:** Toss Payments Integration
   - Payment modal UI
   - Checkout flow (Turbo Frame)
   - Webhook handling
   - User role upgrade (free → paid)

2. **STORY-4.2:** Background Job Infrastructure
   - Solid Queue setup (Rails 7.2+ default)
   - ProcessPdfJob refactoring
   - Progress tracking with Turbo Streams

**Acceptance Criteria:**
- User can purchase 10,000 KRW Season Pass
- Payment status updates in real-time
- PDF processing happens asynchronously

#### Sprint 2: AI/ML Pipeline (Week 1, Days 4-7)

**Stories:**
3. **STORY-4.3:** OpenAI API Integration
   - API client setup with HTTParty
   - Embedding generation service
   - Rate limiting and error handling

4. **STORY-4.4:** SQLite VSS Setup
   - sqlite-vss extension installation
   - Embedding storage in JSON column
   - Vector similarity search queries

5. **STORY-4.5:** Knowledge Graph Construction
   - LLM-based concept extraction (GPT-4o-mini)
   - Concept graph JSON storage
   - Subject → Chapter → Key Concept hierarchy

**Acceptance Criteria:**
- Questions have embeddings generated
- Concept graph stored in `study_sets.concept_graph`
- Similar question retrieval works

#### Sprint 3: GraphRAG & Visualization (Week 2)

**Stories:**
6. **STORY-4.6:** GraphRAG Weak Point Analysis
   - GraphRAG service implementation
   - LLM prompt engineering (GPT-4o)
   - Weak concept detection algorithm

7. **STORY-4.7:** Enhanced Wrong Answer Analysis
   - GraphRAG integration with wrong answers
   - AI-generated explanations
   - "Concept Gap vs Careless Mistake" tagging

8. **STORY-4.8:** (Optional P2) 3D Brain Map Visualization
   - Three.js via importmap
   - Stimulus controller for graph rendering
   - Node interaction (click → drill mode)

**Acceptance Criteria:**
- Wrong answer analysis shows "weak concepts"
- AI explanation appears in Turbo Frame
- (Optional) 3D graph renders in dashboard

---

## 6. Implementation Workflow

### Story Development Process

```
For each story:
1. SM creates story file: `stories/STORY-4.{X}.md`
2. Dev implements: `/bmad:bmm:agents:dev`
3. QA reviews: `/bmad:bmm:workflows:code-review`
4. Update sprint status: `docs/sprint-status.yaml`
```

### Recommended Commands

**Start Sprint Planning:**
```
/bmad:bmm:workflows:sprint-planning
```

**Create Story:**
```
/bmad:bmm:workflows:create-story
```

**Implement Story:**
```
/bmad:bmm:workflows:dev-story
```

**Code Review:**
```
/bmad:bmm:workflows:code-review
```

**Check Status:**
```
/bmad:bmm:workflows:workflow-status
```

---

## 7. Next Steps (Immediate Actions)

### Step 1: Architecture Enhancement (Today)

**Action:** Expand `docs/architecture-rails.md` with:
- AI/ML pipeline architecture
- Service layer design patterns
- Background job flow
- Payment integration architecture

**Command:**
```
/bmad:bmm:agents:architect
```

**Prompt:**
"Based on PRD requirements and current Rails implementation, expand architecture-rails.md to include:
1. AI/ML pipeline (Upstage → OpenAI → SQLite VSS)
2. GraphRAG service architecture
3. Background job processing flow
4. Toss Payments integration
5. Service layer class diagram"

### Step 2: Sprint Planning (Today)

**Action:** Create sprint plan with 8 stories

**Command:**
```
/bmad:bmm:workflows:sprint-planning
```

**Expected Output:**
- `docs/sprint-status.yaml`
- `stories/STORY-4.1.md` to `STORY-4.8.md`

### Step 3: Implementation (Tomorrow)

**Action:** Start with STORY-4.1 (Payment)

**Command:**
```
/bmad:bmm:workflows:dev-story STORY-4.1
```

---

## 8. Success Metrics

### Phase 4 Completion Criteria

**Technical Metrics:**
- [ ] All 10 P0 stories completed and reviewed
- [ ] Payment system functional (test transaction successful)
- [ ] AI embeddings generated for sample questions
- [ ] Knowledge graph constructed for 1 study set
- [ ] GraphRAG analysis returns weak concepts
- [ ] Background jobs process PDFs asynchronously

**Quality Metrics:**
- [ ] All stories pass code review
- [ ] Test coverage > 70% for new services
- [ ] No security vulnerabilities (Brakeman scan)
- [ ] Performance: PDF processing < 3 min for 50 pages

**PRD Alignment:**
- [ ] All FR-1 to FR-8 implemented
- [ ] MVP scope 100% complete
- [ ] Ready for beta launch

---

## 9. Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| **R1:** OpenAI API costs exceed budget | Medium | High | Use GPT-4o-mini for concept extraction, cache embeddings |
| **R2:** SQLite VSS performance issues | Medium | Medium | Implement pagination, consider PostgreSQL if needed |
| **R3:** Toss Payments integration complexity | Low | High | Use official SDK, test in sandbox thoroughly |
| **R4:** Knowledge Graph construction accuracy | High | High | Iterative prompt engineering, human validation |
| **R5:** Timeline slippage (2 weeks → 3 weeks) | Medium | Medium | Descope 3D visualization to Phase 2 if needed |

---

## 10. BMad Agent Roles Summary

| Agent | Phase | Responsibility | Next Action |
|-------|-------|---------------|-------------|
| **Analyst** | 1 | Requirements analysis | ✅ Complete |
| **PM** | 2 | PRD & Epic creation | ✅ Complete |
| **UX Designer** | 2 | Frontend spec | ✅ Complete |
| **Architect** | 3 | System design | 🟡 Needs expansion |
| **SM** | 4 | Sprint planning & story creation | ⏳ Next |
| **Dev** | 4 | Story implementation | ⏳ After SM |
| **QA** | 4 | Code review | ⏳ After Dev |
| **TEA** | Any | Technical Q&A | Available |

---

## 11. Workflow Status Update

**Update `docs/bmm-workflow-status.yaml`:**

```yaml
workflow_status:
  # Phase 1: Planning
  prd: "prd.md"
  validate-prd: "docs/prd-validation-report-2025-12-06.md"
  create-ux-design: "docs/design-system.md"

  # Phase 2: Solutioning
  create-architecture: "docs/architecture-rails.md"
  create-epics-and-stories: "docs/epics.md"
  test-design: recommended
  validate-architecture: optional
  implementation-readiness: required  # ← TO DO

  # Phase 3: Implementation
  sprint-planning: required  # ← NEXT STEP
  dev-story: in_progress  # ← AFTER SPRINT PLANNING
```

---

## Appendix: Command Quick Reference

```bash
# Check current status
/bmad:bmm:workflows:workflow-status

# Architecture expansion
/bmad:bmm:agents:architect

# Sprint planning
/bmad:bmm:workflows:sprint-planning

# Create individual story
/bmad:bmm:workflows:create-story

# Implement story
/bmad:bmm:workflows:dev-story STORY-4.1

# Code review
/bmad:bmm:workflows:code-review

# Technical questions
/bmad:bmm:agents:tea
```

---

**End of Orchestration Plan**

**Next Command to Execute:**
```
/bmad:bmm:agents:architect
```

**Goal:** Expand `docs/architecture-rails.md` with AI/ML pipeline and service layer architecture before beginning Sprint Planning.
