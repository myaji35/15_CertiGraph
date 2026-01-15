# ExamsGraph Project Status - BMad Method Overview

**Date:** 2026-01-14
**Project:** ExamsGraph (AI 자격증 마스터)
**Current Phase:** Phase 3 → Phase 4 Transition
**Completion:** 60% of MVP

---

## Project Journey Visualization

```
[Phase 1: Analysis] ━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✅ COMPLETED
    └─ PRD v1.2
    └─ PRD Validation (90% score)

[Phase 2: Planning] ━━━━━━━━━━━━━━━━━━━━━━━━━━━ ✅ COMPLETED
    └─ Epic Breakdown (5 epics, 21+ stories)
    └─ UX Design System
    └─ Implementation Readiness Report

[Phase 3: Solutioning] ━━━━━━━━━━━━━━━━━━━━━━━━ ✅ COMPLETED
    └─ Architecture Document (Rails)
    └─ Test Scenarios

    ⚠️  NEEDS EXPANSION: AI/ML Pipeline Architecture

[Phase 4: Implementation] ━━━━━━━━━━━━ 🟡 60% COMPLETE
    ├─ Epic 1: Authentication ━━━━━━━━━━━━━━━━━━━ ✅ DONE
    ├─ Epic 2: Study Set Management ━━━━━━━━━━━━━ ✅ DONE
    ├─ Epic 3: CBT Test Engine ━━━━━━━━━━━━━━━━━ 🟡 80% DONE
    ├─ Epic 4: Analysis & Dashboard ━━━━━━━━━━━━ ❌ 0% (AI/ML)
    └─ Epic 5: Payment & Subscription ━━━━━━━━━━ ❌ 0%
```

---

## Feature Implementation Matrix

### ✅ Implemented (60% of MVP)

| Feature | PRD Ref | Status | Quality |
|---------|---------|--------|---------|
| User Authentication | FR-8 | ✅ Devise + Google OAuth | Production Ready |
| Study Set CRUD | FR-1 | ✅ Full CRUD with UI | Production Ready |
| PDF Upload | FR-1 | ✅ Active Storage | Production Ready |
| PDF Parsing | FR-2 | ✅ Local pdf-reader gem | Beta (needs refinement) |
| Mock Exam (CBT) | FR-5 | ✅ ExamSession with timer | Production Ready |
| Wrong Answer Tracking | FR-6 | ✅ WrongAnswer model | Beta (no AI analysis) |
| Basic Dashboard | FR-7 | ✅ Study progress view | Beta |

### ❌ Missing Critical Features (40% remaining)

| Feature | PRD Ref | Priority | Complexity | Estimated Dev Time |
|---------|---------|----------|------------|-------------------|
| **Payment System** | FR-7 | P0 | Medium | 2-3 days |
| **OpenAI Embeddings** | FR-3 | P0 | High | 2 days |
| **Knowledge Graph** | FR-4 | P0 | High | 3-4 days |
| **GraphRAG Analysis** | FR-6 | P0 | Very High | 3 days |
| **Background Jobs** | NFR | P0 | Medium | 1 day |
| **3D Brain Map** | Phase 3 | P2 | Very High | 4-5 days |

**Total Remaining:** 11-17 days (2-3 weeks)

---

## Technical Debt & Gaps

### Architecture Gaps

1. **AI/ML Pipeline Architecture** (High Priority)
   - Current: Only PDF parsing exists
   - Needed: Upstage API → OpenAI Embeddings → SQLite VSS flow
   - Needed: GraphRAG service design
   - Needed: LLM prompt engineering patterns

2. **Background Job Infrastructure** (High Priority)
   - Current: Synchronous PDF processing
   - Needed: Solid Queue or Sidekiq setup
   - Needed: Progress tracking with Turbo Streams

3. **Payment Integration** (High Priority)
   - Current: No payment system
   - Needed: Toss Payments API integration
   - Needed: Webhook handling for payment status

### Code Quality Issues

1. **PDF Parser Accuracy** (Medium Priority)
   - Current implementation: Basic regex patterns
   - Issue: May fail on complex table structures
   - Recommendation: Test with 10+ real exam PDFs

2. **Test Coverage** (Low Priority)
   - Current: Playwright E2E tests exist
   - Missing: Unit tests for services
   - Goal: 70% coverage before launch

3. **Error Handling** (Medium Priority)
   - Current: Basic Rails error pages
   - Needed: User-friendly error messages
   - Needed: Sentry or error tracking integration

---

## BMad Method Recommendations

### Immediate Next Steps (This Week)

#### Step 1: Architecture Enhancement (Today - 2 hours)

**Command:**
```
/bmad:bmm:agents:architect
```

**Tasks:**
- Expand `docs/architecture-rails.md` to 300+ lines
- Add AI/ML pipeline architecture diagram
- Define all service objects (7-10 services)
- Document background job flows
- Payment integration architecture

**Output:** `docs/architecture-rails-complete.md`

#### Step 2: Sprint Planning (Today - 1 hour)

**Command:**
```
/bmad:bmm:workflows:sprint-planning
```

**Tasks:**
- Create `docs/sprint-status.yaml`
- Generate 12 story files: `stories/STORY-4.1.md` to `STORY-4.12.md`
- Assign priorities and dependencies

**Output:** Sprint backlog ready for implementation

#### Step 3: Story Implementation (Tomorrow onwards)

**Command for each story:**
```
/bmad:bmm:workflows:dev-story STORY-4.{X}
```

**Recommended Order:**
1. STORY-4.1: Payment System (unblocks revenue)
2. STORY-4.2: Background Jobs (infrastructure)
3. STORY-4.3: OpenAI API Integration (core AI)
4. STORY-4.4: SQLite VSS Setup (vector search)
5. STORY-4.5: Knowledge Graph (concept extraction)
6. STORY-4.6: GraphRAG Analysis (weak point detection)
7. STORY-4.7: Enhanced Wrong Answer Analysis
8. STORY-4.8: (Optional) 3D Visualization

---

## Risk Assessment

### High Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **OpenAI API costs exceed budget** | Revenue loss | Use GPT-4o-mini, implement caching |
| **Knowledge Graph accuracy issues** | User dissatisfaction | Iterative prompt engineering, A/B testing |
| **Timeline slippage (2 weeks → 4 weeks)** | Launch delay | Descope 3D visualization to Phase 2 |

### Medium Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Toss Payments integration complexity** | Payment failure | Use official SDK, sandbox testing |
| **SQLite VSS performance at scale** | Slow search | Implement pagination, consider PostgreSQL |
| **PDF parsing accuracy on edge cases** | Data quality | Test with 20+ real PDFs, manual review |

---

## Success Criteria for Phase 4 Completion

### Technical Checklist

- [ ] All 12 stories implemented and code-reviewed
- [ ] Payment system functional (test transaction successful)
- [ ] AI embeddings generated for 100+ sample questions
- [ ] Knowledge graph constructed for 1 complete study set
- [ ] GraphRAG analysis returns meaningful weak concepts
- [ ] Background jobs process PDFs < 3 min for 50 pages
- [ ] Test coverage > 70% for new services
- [ ] No security vulnerabilities (Brakeman scan clean)

### PRD Alignment Checklist

- [ ] FR-1: PDF Upload & Parsing ✅
- [ ] FR-2: Intelligent Chunking ✅
- [ ] FR-3: Embeddings (OpenAI) ⏳
- [ ] FR-4: Knowledge Graph ⏳
- [ ] FR-5: CBT Exam ✅
- [ ] FR-6: GraphRAG Analysis ⏳
- [ ] FR-7: Payment System ⏳
- [ ] FR-8: Authentication ✅

### User Validation Checklist

- [ ] User can sign up and purchase Season Pass
- [ ] User can upload PDF and see questions extracted
- [ ] User can take mock exam with randomized options
- [ ] Wrong answer analysis shows "weak concepts"
- [ ] Dashboard displays learning progress
- [ ] AI-generated explanations are accurate

---

## Project Timeline

### Completed (Week -4 to Week -1)

- Week -4: Phase 1 (Analysis) - PRD creation
- Week -3: Phase 2 (Planning) - Epic breakdown
- Week -2: Phase 3 (Solutioning) - Architecture design
- Week -1: Phase 4 (Implementation) - Epic 1-3 (60% MVP)

### Remaining (Week 0 to Week 2)

- **Week 0, Day 1 (Today):** Architecture enhancement + Sprint planning
- **Week 0, Day 2-3:** Payment system + Background jobs
- **Week 1, Day 1-3:** AI/ML pipeline (Embeddings + Graph)
- **Week 1, Day 4-5:** GraphRAG analysis
- **Week 2, Day 1-2:** Integration testing + Bug fixes
- **Week 2, Day 3:** Beta launch prep

**Target Launch Date:** Week 2, Day 4 (2026-01-28)

---

## BMad Agent Status

| Agent | Last Used | Next Use | Status |
|-------|-----------|----------|--------|
| Analyst | Week -4 | - | ✅ Complete |
| PM | Week -3 | - | ✅ Complete |
| UX Designer | Week -2 | - | ✅ Complete |
| Architect | Week -2 | Today | 🟡 Needs Update |
| SM | Not yet | Today | ⏳ Ready to Start |
| Dev | Week -1 | Tomorrow | 🟡 In Progress |
| QA | Not yet | After Dev | ⏳ Standby |
| TEA | Anytime | On Demand | ✅ Available |

---

## Key Files Reference

### Planning Documents
- `/prd.md` - Product Requirements v1.2
- `/docs/epics.md` - Epic breakdown (5 epics)
- `/docs/design-system.md` - UI/UX design system

### Architecture Documents
- `/docs/architecture-rails.md` - Current (needs expansion)
- `/docs/implementation-readiness-report-2025-01-05.md` - Readiness assessment

### Implementation Artifacts
- `/rails-api/` - Rails 7.2.2 application
- `/rails-api/app/services/` - Service objects
- `/rails-api/app/models/` - 13 Active Record models

### Workflow Tracking
- `/docs/bmm-workflow-status.yaml` - BMad workflow status
- `/docs/bmad-orchestration-plan.md` - This orchestration plan

---

## Contact & Support

**Project Owner:** CEO Seungsik Kang
**Development Method:** BMad Method v6 (AI-Driven Agile)
**Next Checkpoint:** After Sprint Planning (2026-01-14 EOD)

---

**End of Status Summary**

**Next Command:**
```
/bmad:bmm:agents:architect
```

**Goal:** Expand Rails architecture document with AI/ML pipeline before sprint planning.
