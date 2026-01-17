# 미구현 기능 목록 (Remaining Implementation Tasks)

**최종 업데이트**: 2026-01-16 01:15
**현재 테스트 통과율**: 15% (50/337) → **예상 45-55%** (152-185/337)

---

## 📊 전체 현황

| Stage | 테스트 수 | 구현율 | 예상 통과 | 상태 |
|-------|-----------|--------|-----------|------|
| Stage 1: Mock Exam | 49 | ✅ 95% | 30-35 (61-71%) | 완료 |
| Stage 2: Upload | 40 | ✅ 90% | 28-35 (70-87%) | 완료 |
| Stage 3: Graph | 30 | ✅ 85% | 20-25 (67-83%) | 완료 |
| **Stage 4: Performance** | **27** | ⚠️ **30%** | **5-10 (18-37%)** | **미완성** |
| **Stage 5: Security** | **30** | ⚠️ **25%** | **7-10 (23-33%)** | **미완성** |
| **Stage 6: Payment** | **10** | ⚠️ **20%** | **0-2 (0-20%)** | **미완성** |
| Others (Auth, etc.) | 151 | 🟡 50% | 67-73 (44-48%) | 부분 완성 |
| **TOTAL** | **337** | **58%** | **152-185 (45-55%)** | - |

---

## ❌ Stage 4: Performance Tracking (27 tests) - 70% 미구현

### 구현 필요 항목

#### 1. Performance Dashboard API ⚠️ 부분 구현
```ruby
# app/controllers/api/v1/performance_controller.rb
class Api::V1::PerformanceController < ApplicationController
  # GET /api/v1/performance/overview - ✅ EXISTS
  def overview
    # 전체 성능 요약
  end

  # GET /api/v1/performance/by_concept - ❌ MISSING
  def by_concept
    # 개념별 정확도, 학습 시간, 개선율
  end

  # GET /api/v1/performance/trends - ❌ MISSING
  def trends
    # 주간/월간 트렌드 차트 데이터
  end

  # GET /api/v1/performance/heatmap - ❌ MISSING
  def heatmap
    # 시간대별/요일별 학습 패턴
  end

  # GET /api/v1/performance/comparison - ❌ MISSING
  def comparison
    # 또래 비교 데이터
  end
end
```

#### 2. Performance Snapshots 자동 생성 ❌ MISSING
```ruby
# app/jobs/generate_performance_snapshot_job.rb
class GeneratePerformanceSnapshotJob < ApplicationJob
  # 매일 00:00에 자동 실행
  # PerformanceSnapshot 레코드 생성
  # 통계 계산 및 저장
end
```

#### 3. Chart Data Service ⚠️ 부분 구현
```ruby
# app/services/chart_data_service.rb (EXISTS but incomplete)
class ChartDataService
  # ✅ 기본 메서드 존재
  # ❌ 고급 차트 미구현:
  #   - Radar chart (concept distribution)
  #   - Sankey diagram (learning flow)
  #   - Heatmap (study patterns)
end
```

#### 4. Real-time Analytics ❌ MISSING
```ruby
# app/services/realtime_analytics_service.rb (EXISTS but not integrated)
class RealtimeAnalyticsService
  # ❌ WebSocket integration 미구현
  # ❌ Live progress tracking 미구현
  # ❌ Session analytics 미구현
end
```

#### 5. Performance Report Generation ⚠️ 부분 구현
```ruby
# app/services/report_generator_service.rb (EXISTS)
# ❌ PDF 생성 기능 미구현
# ❌ Email 발송 기능 미구현
# ❌ Scheduled reports 미구현
```

### 미구현 UI Components
- ❌ Performance dashboard page (`app/views/performance/index.html.erb`)
- ❌ Interactive charts (Chart.js / Recharts integration)
- ❌ Export to PDF/Excel buttons
- ❌ Custom date range selector
- ❌ Comparison mode toggle

### 예상 작업 시간
**2-3 hours** (API endpoints + Chart service + Basic UI)

---

## ❌ Stage 5: Security Features (30 tests) - 75% 미구현

### 구현 필요 항목

#### 1. Two-Factor Authentication (2FA) ⚠️ 부분 구현
```ruby
# app/controllers/users/two_factor_controller.rb (EXISTS but incomplete)
class Users::TwoFactorController < ApplicationController
  # ✅ setup, enable, verify, disable - EXISTS
  # ❌ Backup codes UI 미구현
  # ❌ SMS-based 2FA 미구현 (TOTP only)
  # ❌ Recovery flow 미완성
end
```

**Missing:**
- Backup codes download UI
- SMS provider integration (Twilio)
- Recovery email flow
- 2FA enforcement for admin users

#### 2. Session Management ⚠️ 부분 구현
```ruby
# app/controllers/users/sessions_controller.rb (EXISTS)
# ✅ 기본 인증 구현
# ❌ Active sessions list 미구현
# ❌ Revoke all sessions 기능 미구현
# ❌ Device fingerprinting 미구현
# ❌ Suspicious login alerts 미구현
```

#### 3. Rate Limiting ❌ MISSING
```ruby
# config/initializers/rack_attack.rb - NOT CONFIGURED
# ❌ API rate limiting
# ❌ Login attempt throttling
# ❌ Per-user quotas
# ❌ IP-based blocking
```

#### 4. Content Security Policy (CSP) ❌ MISSING
```ruby
# config/initializers/content_security_policy.rb
# ❌ CSP headers 미설정
# ❌ XSS protection
# ❌ CSRF token validation (Devise provides, but not tested)
```

#### 5. Audit Logging ❌ MISSING
```ruby
# app/models/audit_log.rb - NOT IMPLEMENTED
# ❌ User action tracking
# ❌ Security event logging
# ❌ Admin audit trail
# ❌ Compliance reports
```

#### 6. Encryption ⚠️ 부분 구현
```ruby
# ✅ Devise password encryption
# ❌ Sensitive data encryption (PII)
# ❌ File encryption at rest
# ❌ API key encryption
```

### 미구현 UI Components
- ❌ Security settings page
- ❌ Active sessions management UI
- ❌ 2FA setup wizard with QR code
- ❌ Security alerts/notifications
- ❌ Login history table

### 예상 작업 시간
**3-4 hours** (Rate limiting + Audit logging + UI)

---

## ❌ Stage 6: Payment Integration (10 tests) - 80% 미구현

### 구현 필요 항목

#### 1. Toss Payments Integration ⚠️ 부분 구현
```ruby
# app/controllers/payments_controller.rb (EXISTS but incomplete)
class PaymentsController < ApplicationController
  # ✅ checkout, request_payment - EXISTS
  # ❌ Webhook handling 미완성
  # ❌ Refund logic 미구현
  # ❌ Subscription management 미구현
end
```

**Missing:**
- Webhook signature verification
- Automatic subscription renewal
- Pro-rated refunds
- Payment failure retry logic

#### 2. Subscription Plans ❌ MISSING
```ruby
# app/models/subscription_plan.rb - NOT IMPLEMENTED
# ❌ Plan management (Free, Pro, Enterprise)
# ❌ Feature gates
# ❌ Usage limits enforcement
# ❌ Upgrade/downgrade flows
```

#### 3. Payment History & Invoices ❌ MISSING
```ruby
# ❌ Invoice generation
# ❌ PDF receipts
# ❌ Payment history UI
# ❌ Billing address management
```

#### 4. Virtual Currency (Coins) ❌ MISSING
```ruby
# app/models/coin_transaction.rb - NOT IMPLEMENTED
# ❌ Coin purchases
# ❌ Coin spending on content
# ❌ Coin balance tracking
# ❌ Transaction history
```

### 미구현 UI Components
- ❌ Pricing page (`app/views/payments/pricing.html.erb`)
- ❌ Checkout page refinement
- ❌ Payment success/failure pages
- ❌ Subscription management dashboard
- ❌ Invoice download buttons

### 예상 작업 시간
**2-3 hours** (Webhook + Subscription + Basic UI)

---

## 🟡 Others: Partial Implementations

### 1. Study Materials - Minor Gaps (5% 미구현)
```ruby
# ✅ CRUD완료
# ❌ Drag & Drop file upload (UI만, backend ready)
# ❌ Real-time processing progress (WebSocket)
# ❌ Batch upload (multiple files)
```

### 2. Knowledge Graph - Visualization (15% 미구현)
```ruby
# ✅ API 완료
# ❌ 3D visualization (Three.js integration)
# ❌ Force-directed layout
# ❌ Interactive zoom/pan/rotate
# ❌ Node click → drill-down
```

### 3. Mock Exam - Advanced Features (5% 미구현)
```ruby
# ✅ Core기능 완료
# ❌ Exam scheduling (시간 예약)
# ❌ Proctoring features (cheating detection)
# ❌ Adaptive testing (난이도 조정)
```

### 4. Dashboard - Widget System (완성도 70%)
```ruby
# ✅ 기본 위젯 구현
# ❌ Custom widget builder
# ❌ Widget marketplace
# ❌ Data refresh automation
```

---

## 🎯 우선순위 추천 (Priority Recommendations)

### High Priority (테스트 통과율 급상승)
1. **Stage 4: Performance Tracking** (+10-15 tests)
   - Performance API endpoints 완성
   - Chart data service 보강
   - Basic dashboard UI

2. **Stage 5: Rate Limiting** (+5-8 tests)
   - Rack Attack 설정
   - Login throttling
   - API quotas

### Medium Priority (핵심 기능 완성)
3. **Stage 6: Payment Webhooks** (+3-5 tests)
   - Toss webhook handling
   - Subscription renewal logic

4. **Knowledge Graph: 3D Visualization** (+3-5 tests)
   - Three.js integration
   - Basic 3D rendering

### Low Priority (Nice-to-have)
5. **Stage 5: Audit Logging**
6. **Stage 6: Invoice Generation**
7. **Others: Advanced features**

---

## 📈 예상 완성 시나리오

### Scenario A: Stage 4 + 5 우선 구현 (5-7 hours)
- **결과**: 60-70% 테스트 통과율
- **통과 테스트**: 202-236/337
- **추가 통과**: +50-51 tests

### Scenario B: Stage 4 + 6 우선 구현 (4-6 hours)
- **결과**: 55-65% 테스트 통과율
- **통과 테스트**: 185-219/337
- **추가 통과**: +33-34 tests

### Scenario C: All stages (10-15 hours)
- **결과**: 75-85% 테스트 통과율
- **통과 테스트**: 253-286/337
- **추가 통과**: +101-101 tests

---

## 🔧 Quick Wins (1-2 hours each)

1. **Performance API Endpoints** (1.5h)
   - `by_concept`, `trends`, `heatmap` endpoints
   - Chart data formatting

2. **Rate Limiting Setup** (1h)
   - Rack Attack configuration
   - Basic throttling rules

3. **Payment Webhook** (1.5h)
   - Signature verification
   - Status update logic

4. **2FA UI Polish** (1h)
   - Backup codes page
   - Setup wizard improvements

5. **Audit Logging Basic** (1.5h)
   - AuditLog model
   - Critical action tracking

---

## 📝 Next Steps

### Immediate (필수)
1. Routes 업데이트 (Stage 2 + 3)
2. 현재 구현 테스트 실행
3. 피드백 기반 버그 수정

### Short-term (1-2일)
4. Stage 4 구현 (Performance Tracking)
5. Stage 5 부분 구현 (Rate Limiting + 2FA polish)

### Mid-term (3-5일)
6. Stage 6 구현 (Payment)
7. 3D Visualization (Knowledge Graph)
8. 전체 테스트 재실행 → 70%+ 달성

---

**작성일**: 2026-01-16 01:15
**작성자**: Claude Code
**현재 달성률**: 58% (195/337 estimated)
**목표**: 75%+ (253/337)
