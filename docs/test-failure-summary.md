# 테스트 실패 분석 및 TDD 액션 플랜

**분석 일시**: 2026-01-16 01:20
**전체 테스트**: 337개
**통과**: ~9개 (2.7%)
**실패**: ~328개 (97.3%)

---

## 🚨 Critical Issues (P0 - 즉시 수정 필요)

### Issue #1: Login Page 404 Error
**영향도**: HIGH - Mock Exam 전체 차단 (62 tests)

**증상**:
```
TimeoutError: page.fill: Timeout 15000ms exceeded.
waiting for locator('[name="email"]')

at page.goto('${FRONTEND_URL}/login')
```

**원인**:
- `/login` 경로가 404 또는 다른 페이지로 리다이렉트
- Email input 필드가 존재하지 않거나 다른 selector 사용

**해결책**:
1. Routes 확인: `config/routes.rb`에서 `/login` 경로 확인
2. Devise 설정 확인: `get 'login', to: 'devise/sessions#new'` 존재 여부
3. View 파일 확인: `app/views/devise/sessions/new.html.erb`에 `[name="email"]` 존재 확인

**수정 예상 시간**: 10분

---

### Issue #2: Password Complexity Selector (Auth Test 004)
**영향도**: MEDIUM - 1개 테스트 실패

**증상**:
```
Error: strict mode violation: locator('text=/복잡도|complexity/') resolved to 5 elements
```

**원인**:
- Password complexity validation이 5개 메시지 생성:
  1. Alert paragraph
  2. "대문자 포함" 메시지
  3. "소문자 포함" 메시지
  4. "특수문자 포함" 메시지
  5. Error text paragraph

**해결책**:
```typescript
// Before
await expect(page.locator('text=/복잡도|complexity/')).toBeVisible();

// After
await expect(page.locator('text=/복잡도|complexity/').first()).toBeVisible();
```

**파일**: `tests/e2e/bmad-auth-comprehensive.spec.ts:97`

**수정 예상 시간**: 2분

---

## ⚠️ Major Issues (P1 - 단기 수정)

### Issue #3: 비밀번호 확인 불일치 메시지 (Auth Test 005)
**메시지**: "비밀번호가 일치하지 않습니다" 표시되지 않음

**해결책**:
- Devise 한글화 확인: `config/locales/devise.ko.yml`
- View에서 validation error 표시 확인

---

### Issue #4: 이메일/약관 검증 (Auth Tests 006-015)
**패턴**: 다양한 validation 메시지가 기대한 대로 표시되지 않음

**공통 원인**:
1. Devise 에러 메시지가 영어로 표시 (한글 locale 미적용)
2. Validation logic이 development 환경에서만 비활성화
3. Custom validation이 구현되지 않음

**해결책**:
- `config/application.rb`에 `config.i18n.default_locale = :ko` 확인
- Devise initializer에서 locale 설정
- Production-like validation 활성화

---

### Issue #5: 로그인 성공 후 리다이렉트 (Auth Test 016)
**메시지**: Login success test fails

**예상 원인**:
- `/dashboard` 경로가 존재하지 않음
- Session이 제대로 생성되지 않음
- 리다이렉트 로직 오류

**해결책**:
1. `config/routes.rb`에서 `resources :dashboard` 확인
2. `DashboardController#index` 구현 확인
3. Devise `after_sign_in_path` 설정 확인

---

## 🟡 Minor Issues (P2 - 중기 수정)

### Issue #6: Knowledge Graph 전체 실패 (30/30)
**원인**: API endpoints 또는 view 미구현

**해결 우선순위**: Stage 2 + 3 구현 완료 후

---

### Issue #7: Performance Tests (24/27 fail)
**원인**: 성능 임계값 또는 기능 미구현

**해결 우선순위**: Stage 4 구현 시

---

### Issue #8: Security Tests (30/30 fail)
**원인**: Security features 미구현

**해결 우선순위**: Stage 5 구현 시

---

## 📋 TDD Action Plan

### Phase 1: P0 Fixes (20분)
1. **Login Page Fix** (10분)
   ```bash
   # 1. Routes 확인
   grep -n "login" rails-api/config/routes.rb

   # 2. View 확인
   cat rails-api/app/views/devise/sessions/new.html.erb | grep "email"

   # 3. 수정 후 테스트
   npx playwright test tests/e2e/bmad-auth-comprehensive.spec.ts --grep "016\."
   ```

2. **Selector Fix** (2분)
   - `tests/e2e/bmad-auth-comprehensive.spec.ts:97` 수정
   - `.first()` 추가

3. **테스트 재실행** (8분)
   ```bash
   npx playwright test tests/e2e/bmad-auth-comprehensive.spec.ts --grep "001\.|002\.|003\.|004\.|016\.|017\.|018\." --workers=4
   ```

**예상 결과**: 8/30 → 10/30 통과 (33%)

---

### Phase 2: P1 Fixes (1시간)
1. **Devise 한글화** (20분)
   - `config/locales/devise.ko.yml` 생성/확인
   - `config/application.rb` locale 설정
   - Tests 005-015 재실행

2. **Dashboard Route** (15분)
   - `config/routes.rb`에 dashboard 추가
   - `DashboardController#index` 구현
   - Test 016 재실행

3. **Validation Logic** (25분)
   - SQL Injection 방어 (006)
   - XSS 방어 (007)
   - Email format validation (008)

**예상 결과**: 10/30 → 18/30 통과 (60%)

---

### Phase 3: Mock Exam Unblock (30분)
1. **Login 수정 검증**
2. **Mock Exam Tests 재실행**:
   ```bash
   npx playwright test tests/e2e/bmad-mock-exam.spec.ts --workers=4 --max-failures=5
   ```

**예상 결과**: 0/62 → 15/62 통과 (24%)

---

### Phase 4: Stage 2 + 3 Tests (이미 구현됨)
1. **Routes 업데이트** (5분)
2. **Tests 재실행**:
   ```bash
   npx playwright test tests/e2e/bmad-study-materials.spec.ts --workers=2
   npx playwright test tests/e2e/bmad-knowledge-graph.spec.ts --workers=2
   ```

**예상 결과**:
- Study Materials: 0/40 → 25/40 (62%)
- Knowledge Graph: 0/30 → 18/30 (60%)

---

## 🎯 Expected Final Results

| Phase | 시간 | 통과 | 전체 | 비율 |
|-------|------|------|------|------|
| **Current** | - | 9 | 337 | 2.7% |
| After P0 | 20분 | 25 | 337 | 7.4% |
| After P1 | 1h20 | 50 | 337 | 14.8% |
| After P2 | 2h | 108 | 337 | 32.0% |
| After P3+4 | 3h | 185 | 337 | **54.9%** |

---

## 🚀 Immediate Next Steps

### 1. Fix Login Page (NOW)
```bash
# Check routes
grep -A5 -B5 "login\|signin" rails-api/config/routes.rb

# Check view
ls -la rails-api/app/views/devise/sessions/

# Test manually
curl -I http://localhost:3000/login
```

### 2. Fix Selector (NOW)
```bash
# Edit test file
code tests/e2e/bmad-auth-comprehensive.spec.ts +97
```

### 3. Run Focused Tests
```bash
# Test only P0 issues
npx playwright test tests/e2e/bmad-auth-comprehensive.spec.ts \
  --grep "001\.|002\.|003\.|004\.|016\.|017\.|018\." \
  --workers=3 \
  --reporter=list
```

---

## 📊 Test Coverage by Stage

| Stage | 테스트 수 | 통과 | 실패 | 비율 | 상태 |
|-------|-----------|------|------|------|------|
| Auth (001-030) | 30 | 6 | 24 | 20% | 🟡 P0/P1 수정 필요 |
| Mock Exam (091-150) | 62 | 0 | 62 | 0% | 🔴 Login 차단 |
| Knowledge Graph (151-180) | 30 | 0 | 30 | 0% | 🟡 Stage 3 구현됨 |
| Performance (221-250) | 27 | 3 | 24 | 11% | 🟠 Stage 4 미구현 |
| Security (251-280) | 30 | 0 | 30 | 0% | 🟠 Stage 5 미구현 |
| Upload (051-090) | 40 | ? | ? | ? | 🟢 Stage 2 구현됨 |
| Payment (PAY-001~012) | 10 | 3 | 7 | 30% | 🟠 Partial |
| Others | 108 | ? | ? | ? | - |
| **TOTAL** | **337** | **~9** | **~328** | **2.7%** | - |

---

**다음 액션**: P0 이슈 수정 → Auth 테스트 통과 → Mock Exam 언블록 → Stage 2/3 검증

**목표**: 3시간 내 **54.9%** 테스트 통과율 달성
