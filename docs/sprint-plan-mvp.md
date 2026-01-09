# CertiGraph MVP Sprint Plan

**Project:** CertiGraph (AI 자격증 마스터)
**Duration:** 8 Weeks (2026-01-08 ~ 2026-03-05)
**Team:** 1-person full-stack
**Target:** 2025년 사회복지사 1급 시험 대비 서비스 출시

---

## 🎯 MVP Success Criteria

### Must Have (P0)
- ✅ User authentication (Clerk)
- ✅ VIP pass system
- ⚠️ PDF upload and question extraction
- ⚠️ CBT test engine with randomization
- ⚠️ Basic dashboard

### Nice to Have (P1)
- ⭕ Payment integration
- ⭕ Advanced analytics
- ⭕ Email notifications

### Deferred to Phase 2
- ❌ Vector search (Pinecone)
- ❌ Knowledge Graph (Neo4j)
- ❌ GraphRAG analysis
- ❌ AI recommendations

---

## 📅 Sprint Timeline

### **Sprint 1: Foundation & VIP** (Week 1-2: Jan 8-21)

#### Goals
- ✅ Complete authentication system
- ✅ Implement VIP pass functionality
- 🎯 Fix PDF processing pipeline

#### Stories
| Story | Description | Status | Priority |
|-------|-------------|--------|----------|
| 1.1-1.6 | Auth & Foundation | ✅ DONE | - |
| 5.0-5.0B | VIP System | ✅ DONE | - |
| 2.4 (Fix) | PDF Upload Pipeline | 🚧 IN PROGRESS | P0 |
| 2.5 | Upstage OCR Integration | ❌ NOT STARTED | P0 |

#### Key Deliverables
- Working authentication flow
- VIP users can access all features
- PDF upload to GCP Cloud Storage
- Upstage API connected

---

### **Sprint 2: Content Processing** (Week 3-4: Jan 22 - Feb 4)

#### Goals
- Complete PDF processing pipeline
- Extract and store questions
- Basic CRUD for study materials

#### Stories
| Story | Description | Status | Priority |
|-------|-------------|--------|----------|
| 2.5 | Upstage OCR Integration | ⏳ PLANNED | P0 |
| 2.6 | Question Extraction | ⏳ PLANNED | P0 |
| 2.1-2.3 | Study Set Management | ✅ DONE | - |

#### Key Deliverables
- PDFs parsed into questions
- Questions stored in Cloud SQL
- Study sets fully functional

#### Technical Tasks
```python
# Priority implementation
1. services/pdf_processor.py
2. services/upstage_client.py
3. services/question_extractor.py
4. Background job for processing
```

---

### **Sprint 3: Test Engine Core** (Week 5-6: Feb 5-18)

#### Goals
- Complete CBT test engine
- Implement option randomization
- Basic scoring system

#### Stories
| Story | Description | Status | Priority |
|-------|-------------|--------|----------|
| 3.1 | Test Configuration Modal | ⏳ PLANNED | P0 |
| 3.2 | Test Session API | ⏳ PLANNED | P0 |
| 3.3 | CBT Interface | ⏳ PLANNED | P0 |
| 3.4 | Answer Submission | ⏳ PLANNED | P0 |
| 3.5 | Results Page | ⏳ PLANNED | P0 |

#### Key Deliverables
- Users can take tests
- Fisher-Yates shuffle implemented
- Scoring and results display

#### Frontend Components
```tsx
// Priority components
1. TestConfigModal.tsx
2. TestQuestion.tsx
3. TestTimer.tsx
4. TestResults.tsx
```

---

### **Sprint 4: Dashboard & Polish** (Week 7-8: Feb 19 - Mar 5)

#### Goals
- Basic statistics dashboard
- Bug fixes and testing
- Optional: Payment integration

#### Stories
| Story | Description | Status | Priority |
|-------|-------------|--------|----------|
| 4.1 | Statistics API | ⏳ PLANNED | P0 |
| 4.2 | Dashboard UI | 🚧 PARTIAL | P0 |
| 5.1 | Payment Integration | ⏳ OPTIONAL | P1 |

#### Key Deliverables
- Dashboard showing progress
- All critical bugs fixed
- Production deployment ready

---

## 🚨 Critical Path

### Week 1-2 Must Complete
1. **Upstage OCR Integration** - Without this, no questions
2. **Question Extraction** - Core value proposition

### Week 3-4 Must Complete
1. **Question Storage** - Enable test taking
2. **Study Material Status** - User feedback

### Week 5-6 Must Complete
1. **Test Engine** - Main user feature
2. **Option Randomization** - Key differentiator

### Week 7-8 Must Complete
1. **Dashboard Stats** - User retention
2. **Production Deploy** - Go live

---

## 📊 Progress Tracking

### Current Status (Jan 8, 2026)

| Component | Progress | Blockers |
|-----------|----------|----------|
| Authentication | 100% ✅ | None |
| VIP System | 100% ✅ | None |
| Study Sets | 80% 🟡 | PDF processing |
| PDF Processing | 20% 🔴 | Upstage integration |
| Test Engine | 0% 🔴 | Needs questions |
| Dashboard | 30% 🟠 | Needs data |
| Payment | 0% ⚪ | Optional |

### Overall MVP Progress: **52%**

---

## 🔥 Risk Mitigation

### Risk 1: Upstage API Accuracy
- **Mitigation:** Test with 10 real PDFs this week
- **Fallback:** Google Document AI
- **Decision Date:** Jan 15

### Risk 2: Timeline Slippage
- **Mitigation:** Defer payment to post-launch
- **Fallback:** Soft launch with VIP only
- **Decision Date:** Feb 15

### Risk 3: Test Engine Complexity
- **Mitigation:** Start simple, iterate
- **Fallback:** Basic Q&A without timer
- **Decision Date:** Feb 10

---

## 📋 Daily Priorities

### This Week (Jan 8-14)

**Wednesday (Jan 8)**
- [x] Architecture alignment
- [x] Epic document update
- [ ] Start Upstage integration

**Thursday (Jan 9)**
- [ ] Complete Upstage OCR service
- [ ] Test with sample PDF
- [ ] Error handling

**Friday (Jan 10)**
- [ ] Question extraction logic
- [ ] Database schema for questions
- [ ] Background job setup

**Next Week (Jan 15-21)**
- [ ] Complete PDF processing
- [ ] Start test engine UI
- [ ] Basic statistics API

---

## 🚀 Launch Checklist

### Pre-Launch (Week 8)
- [ ] All P0 stories complete
- [ ] Production environment ready
- [ ] Domain configured
- [ ] SSL certificates
- [ ] Monitoring setup

### Launch Day
- [ ] Database migrated
- [ ] Environment variables set
- [ ] Health checks passing
- [ ] VIP users notified
- [ ] Soft launch with 10 users

### Post-Launch (Week 9+)
- [ ] Monitor performance
- [ ] Gather feedback
- [ ] Fix critical bugs
- [ ] Plan Phase 2

---

## 📞 Communication Plan

### Stakeholder Updates
- **Weekly:** Progress report every Monday
- **Blockers:** Immediate escalation
- **Decisions:** Document in this file

### Success Metrics
- 10 VIP users testing (Week 1)
- 100 questions extracted (Week 2)
- 50 tests taken (Week 6)
- 500 signups (Month 1)

---

## 🎉 Definition of Done

### MVP is complete when:
1. ✅ VIP users can use all features
2. ⚠️ PDFs convert to questions reliably
3. ⚠️ Tests work with randomization
4. ⚠️ Basic stats are visible
5. ⭕ Payment works (optional)

### Current Blockers
1. **Upstage API integration** - Start immediately
2. **Question extraction** - Depends on #1
3. **Test engine** - Depends on #2

---

**Document Version:** 1.0
**Created:** 2026-01-08
**Last Updated:** 2026-01-08
**Next Review:** Daily standup

## Next Actions
1. 🔴 **IMMEDIATE:** Implement Upstage OCR service
2. 🔴 **TODAY:** Test with real PDF
3. 🟡 **THIS WEEK:** Complete question extraction