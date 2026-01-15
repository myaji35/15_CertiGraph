# BMad Method Orchestration Playbook - ExamsGraph

**Quick Start Guide for Continuing Implementation**

---

## Current Project State (2026-01-14)

### Phase Status: 3 → 4 Transition (60% Complete)

```
✅ Phase 1: Analysis (DONE)
✅ Phase 2: Planning (DONE)
✅ Phase 3: Solutioning (NEEDS EXPANSION)
🟡 Phase 4: Implementation (IN PROGRESS - 60%)
```

### What's Working

- Rails 7.2.2 app with authentication (Devise + Google OAuth)
- Study Set CRUD with modern UI
- PDF parsing with local pdf-reader gem
- Mock exam sessions with timer
- Wrong answer tracking

### What's Missing (Critical for MVP Launch)

1. Payment System (Toss Payments - 10,000 KRW)
2. AI/ML Pipeline (OpenAI embeddings + Knowledge Graph)
3. GraphRAG Analysis (AI-powered weak point detection)
4. Background Job Processing
5. 3D Visualization (Optional Phase 2)

---

## Orchestration Playbook: 3 Simple Steps

### Step 1: Expand Architecture (TODAY - 2 hours)

**Why:** AI/ML pipeline architecture is incomplete. Need detailed service design.

**Command:**
```bash
/bmad:bmm:agents:architect
```

**What to Tell the Architect Agent:**
```
프로젝트 컨텍스트:
- 현재 Rails 7.2.2 앱 구현 완료 (60% MVP)
- PRD: /prd.md 참조
- 현재 아키텍처: /docs/architecture-rails.md (100 lines, 확장 필요)

요청사항:
1. AI/ML 파이프라인 아키텍처 상세화
   - PDF → Upstage API → OpenAI Embeddings → SQLite VSS
   - GraphRAG 서비스 설계 (SQLite JSON-based Knowledge Graph)
   - LLM 프롬프트 패턴

2. 서비스 레이어 설계 (7-10 services)
   - EmbeddingService (OpenAI API)
   - KnowledgeGraphService (Concept extraction)
   - GraphRagService (Weak point analysis)
   - PaymentService (Toss Payments)
   - WeakPointAnalysisService (AI-powered)

3. Background Job Flow
   - Solid Queue setup
   - ProcessPdfJob → GenerateEmbeddingsJob → BuildGraphJob

4. 데이터베이스 스키마 추가
   - questions.embeddings (JSON)
   - study_sets.concept_graph (JSON)
   - users.payment_status, valid_until

출력: /docs/architecture-rails-complete.md (300+ lines)
```

**Expected Output:**
- `docs/architecture-rails-complete.md` (comprehensive)
- Service layer class diagrams
- AI/ML pipeline flow diagrams
- Database schema updates

**Success Criteria:**
- [ ] 7-10 service objects defined with methods
- [ ] Background job flow documented
- [ ] Payment integration architecture complete
- [ ] GraphRAG service design with prompt patterns

---

### Step 2: Sprint Planning (TODAY - 1 hour)

**Why:** Need to create 12 implementation stories with clear acceptance criteria.

**Command:**
```bash
/bmad:bmm:workflows:sprint-planning
```

**What the Workflow Will Do:**
1. Read PRD, Architecture, Epics
2. Analyze missing features (40% remaining)
3. Generate `docs/sprint-status.yaml`
4. Create 12 story files: `stories/STORY-4.1.md` to `STORY-4.12.md`

**Expected Story Structure:**

```markdown
# STORY-4.1: Toss Payments Integration

## Epic
Epic 5: Payment & Subscription

## User Story
As a user, I want to purchase a 10,000 KRW Season Pass so that I can access all features until my exam date.

## Acceptance Criteria
- [ ] Payment modal UI with Toss Payments widget
- [ ] Checkout flow using Turbo Frame
- [ ] Webhook endpoint for payment confirmation
- [ ] User role upgrade (free → paid)
- [ ] Test transaction successful in sandbox

## Technical Tasks
1. Install toss-payments gem or use HTTParty
2. Create PaymentService
3. Add payment_status to users table
4. Implement webhook endpoint
5. Add payment UI to dashboard

## Files to Create/Modify
- app/services/payment_service.rb
- app/controllers/payments_controller.rb
- app/views/payments/checkout.html.erb
- db/migrate/xxx_add_payment_to_users.rb

## Dependencies
None (can start immediately)

## Estimated Time
2-3 days
```

**Success Criteria:**
- [ ] 12 stories created with detailed acceptance criteria
- [ ] Stories prioritized (P0 first)
- [ ] Dependencies mapped
- [ ] Sprint timeline: 2 weeks

---

### Step 3: Iterative Story Implementation (NEXT 2 WEEKS)

**Why:** Build missing features one story at a time with code reviews.

#### Story Implementation Loop

```
For each story (STORY-4.1 → STORY-4.12):

1. Create Tech Spec (if complex)
   Command: /bmad:bmm:workflows:create-tech-spec
   Output: docs/sprint-artifacts/tech-spec-{feature}.md

2. Implement Story
   Command: /bmad:bmm:workflows:dev-story STORY-4.X
   Agent: Dev
   Output: Working code + tests

3. Code Review
   Command: /bmad:bmm:workflows:code-review STORY-4.X
   Agent: QA
   Output: Review report + fixes

4. Mark Complete & Move to Next
   Update: docs/sprint-status.yaml
```

#### Recommended Story Order

**Sprint 1: Infrastructure (Week 1, Days 1-3)**
1. STORY-4.1: Toss Payments Integration
2. STORY-4.2: Background Job Infrastructure (Solid Queue)

**Sprint 2: AI/ML Pipeline (Week 1, Days 4-7)**
3. STORY-4.3: OpenAI API Integration (HTTParty client)
4. STORY-4.4: SQLite VSS Setup (Vector search)
5. STORY-4.5: Knowledge Graph Construction (LLM-based)

**Sprint 3: GraphRAG & Polish (Week 2)**
6. STORY-4.6: GraphRAG Weak Point Analysis
7. STORY-4.7: Enhanced Wrong Answer Analysis
8. STORY-4.8: Integration Testing & Bug Fixes
9. STORY-4.9: Performance Optimization
10. STORY-4.10: Error Handling & Logging
11. STORY-4.11: Security Audit (Brakeman)
12. STORY-4.12: (Optional) 3D Visualization Prototype

---

## Daily Workflow Commands

### Check Current Status
```bash
/bmad:bmm:workflows:workflow-status
```

### Implement Next Story
```bash
# Example: Implementing payment system
/bmad:bmm:workflows:dev-story STORY-4.1
```

### Get Technical Help
```bash
/bmad:bmm:agents:tea

# Example question:
"What's the best way to integrate Toss Payments API in Rails 7.2?
Should I use a gem or HTTParty?"
```

### Review Completed Story
```bash
/bmad:bmm:workflows:code-review STORY-4.1
```

### Handle Blockers
```bash
/bmad:bmm:workflows:correct-course

# When:
- Story scope changes
- Technical blocker found
- Dependency issue discovered
```

---

## Critical Success Factors

### 1. Follow the BMad Process (Don't Skip Steps)

❌ **Don't:**
- Jump directly to coding without architecture expansion
- Skip sprint planning and wing it
- Implement without story files
- Skip code reviews

✅ **Do:**
- Complete architecture enhancement first
- Create all story files before implementation
- Follow dev-story → code-review loop
- Update sprint-status.yaml after each story

### 2. Maintain Context Engineering

**Every story should reference:**
- PRD requirements (FR-X)
- Architecture decisions
- Existing codebase patterns
- Related files to modify

**Use this prompt pattern:**
```
Context:
- PRD FR-X: {requirement}
- Architecture: {service design}
- Existing Pattern: {code example}

Implementation:
{detailed instructions}

Validation:
{acceptance criteria}
```

### 3. Prioritize P0 Features

**P0 Features (Must Have for MVP):**
1. Payment System (Revenue blocker)
2. Background Jobs (Performance blocker)
3. OpenAI Embeddings (Core value prop)
4. Knowledge Graph (Core value prop)
5. GraphRAG Analysis (Core value prop)

**P1 Features (Nice to Have):**
- Enhanced dashboard analytics
- Email notifications

**P2 Features (Phase 2):**
- 3D Brain Map Visualization
- Mobile app

---

## Troubleshooting Guide

### Issue: "Architecture is too vague for implementation"

**Solution:**
```bash
# Re-run architect agent with more specific requirements
/bmad:bmm:agents:architect

# Prompt: "Expand AI/ML pipeline with code examples and API calls"
```

### Issue: "Story is too large to implement in one go"

**Solution:**
```bash
# Break down into sub-stories
/bmad:bmm:workflows:create-story

# Create STORY-4.1a, STORY-4.1b, STORY-4.1c
```

### Issue: "Code review found major issues"

**Solution:**
```bash
# Don't proceed to next story
# Fix issues first, then re-review
/bmad:bmm:workflows:dev-story STORY-4.X  # Implement fixes
/bmad:bmm:workflows:code-review STORY-4.X  # Re-review
```

### Issue: "OpenAI API costs are too high"

**Solution:**
```bash
/bmad:bmm:agents:tea

# Ask: "How to optimize OpenAI API costs for embeddings?"
# Answer: Use GPT-4o-mini, cache embeddings, batch requests
```

---

## Key Files Reference

### Read Before Starting
1. `/prd.md` - Product requirements (must read)
2. `/docs/architecture-rails.md` - Current architecture
3. `/docs/epics.md` - Epic breakdown
4. `/docs/bmad-orchestration-plan.md` - This plan
5. `/docs/bmad-project-status-summary.md` - Current status

### Generated During Orchestration
1. `/docs/architecture-rails-complete.md` - After Step 1
2. `/docs/sprint-status.yaml` - After Step 2
3. `/stories/STORY-4.*.md` - After Step 2
4. `/docs/sprint-artifacts/tech-spec-*.md` - During Step 3

### Update After Each Story
1. `/docs/sprint-status.yaml` - Mark story complete
2. `/docs/bmm-workflow-status.yaml` - Update completion %

---

## Success Metrics Dashboard

### Track These Daily

**Implementation Progress:**
```
Completed Stories: [  ] / 12
P0 Stories Done:   [  ] / 10
Code Reviews Done: [  ] / 12
Test Coverage:     [  ]%
```

**Quality Gates:**
```
[ ] All stories have acceptance criteria
[ ] All stories pass code review
[ ] Test coverage > 70%
[ ] No security vulnerabilities (Brakeman)
[ ] Performance benchmarks met
```

**PRD Alignment:**
```
[ ] FR-1: PDF Upload ✅
[ ] FR-2: Parsing ✅
[ ] FR-3: Embeddings ⏳
[ ] FR-4: Knowledge Graph ⏳
[ ] FR-5: CBT Exam ✅
[ ] FR-6: GraphRAG ⏳
[ ] FR-7: Payment ⏳
[ ] FR-8: Auth ✅
```

---

## Emergency Contacts (When Stuck)

### Technical Questions
```bash
/bmad:bmm:agents:tea
```

### Scope/Priority Questions
```bash
/bmad:bmm:agents:pm
```

### Architecture Questions
```bash
/bmad:bmm:agents:architect
```

### Implementation Blockers
```bash
/bmad:bmm:workflows:correct-course
```

---

## Final Pre-Launch Checklist

**Before Beta Launch:**
- [ ] All 12 stories implemented
- [ ] Payment system tested with real transaction
- [ ] AI embeddings working for 100+ questions
- [ ] Knowledge graph constructed
- [ ] GraphRAG returns meaningful analysis
- [ ] Test coverage > 70%
- [ ] Security audit passed
- [ ] Performance benchmarks met
- [ ] Error tracking setup (Sentry)
- [ ] Monitoring setup (New Relic or DataDog)

**Launch Readiness Gate:**
- [ ] CEO approval
- [ ] User testing with 5 beta users
- [ ] All P0 features working
- [ ] Rollback plan ready

---

## Next Command to Execute (RIGHT NOW)

```bash
/bmad:bmm:agents:architect
```

**Goal:** Expand architecture document with AI/ML pipeline architecture.

**After Architecture Enhancement:**
```bash
/bmad:bmm:workflows:sprint-planning
```

**After Sprint Planning:**
```bash
/bmad:bmm:workflows:dev-story STORY-4.1
```

---

**Good luck with your orchestration! Follow the BMad Method and you'll ship a high-quality MVP.** 🚀

---

**End of Playbook**
