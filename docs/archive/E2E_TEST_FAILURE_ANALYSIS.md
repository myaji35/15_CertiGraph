# E2E 테스트 실패 분석 보고서

**작성일**: 2026-01-15
**프로젝트**: CertiGraph (AI 자격증 마스터)
**테스트 프레임워크**: Playwright (Node.js)
**테스트 환경**: `SKIP_SERVER=1` (외부 Rails 서버 필요)

---

## 📊 테스트 결과 요약

### ❌ 전체 실패율: 96.67% (29/30 failed)

| 카테고리 | 총 테스트 | 통과 | 실패 | 통과율 |
|---------|----------|------|------|--------|
| 1.1 회원가입 | 15 | 1 | 14 | 6.67% |
| 1.2 로그인 | 15 | 0 | 15 | 0% |
| **합계** | **30** | **1** | **29** | **3.33%** |

**참고**: 전체 BMad comprehensive auth tests는 320개이며, 현재 첫 30개만 실행됨

---

## 🔴 주요 실패 원인

### 1. 회원가입 리다이렉션 실패 (Critical)
**영향받는 테스트**: 001, 012-015
**에러 메시지**:
```
Expected pattern: /dashboard|welcome/
Received string:  "http://localhost:3000/"
```

**원인 분석**:
- 회원가입 form submit은 성공적으로 처리됨
- DB에 사용자 생성됨 (중복 이메일 테스트가 가능한 것으로 추정)
- 하지만 성공 후 리다이렉션이 root path `/`로 이동
- 예상: `/dashboard` 또는 `/welcome` 페이지로 이동해야 함

**Rails 컨트롤러 이슈**:
```ruby
# app/controllers/users/registrations_controller.rb
def after_sign_up_path_for(resource)
  # 현재: root_path 또는 리다이렉션 설정 없음
  # 필요: dashboard_path 또는 welcome_path
end
```

**수정 필요 파일**:
- `app/controllers/users/registrations_controller.rb`
- `config/routes.rb` (dashboard 또는 welcome 라우트 확인)

---

### 2. Validation 에러 메시지 미표시 (High Priority)
**영향받는 테스트**: 002-011, 017-018

#### Test 002: 중복 이메일 에러
**기대**: `이미 사용 중인 이메일` 또는 `Email already exists` 메시지 표시
**실제**: 에러 메시지 표시 안됨 (5초 timeout)

#### Test 003: 약한 비밀번호 에러
**기대**: `비밀번호는 최소 8자` 또는 `Password must be at least 8` 메시지
**실제**: 에러 메시지 표시 안됨

#### Test 004: 비밀번호 복잡도 에러
**기대**: `복잡도`, `대문자` 등의 메시지
**실제**: 에러 메시지 표시 안됨

#### Test 005: 비밀번호 확인 불일치
**기대**: `비밀번호가 일치하지 않습니다` 메시지
**실제**: 에러 메시지 표시 안됨

**원인 분석**:
1. **Rails flash 메시지가 렌더링 안됨**
   - Devise 기본 flash 메시지는 `flash[:alert]`, `flash[:notice]` 사용
   - View 템플릿에서 flash 메시지 출력 코드 누락 가능

2. **Inline validation 미구현**
   - 프론트엔드 JavaScript validation 없음
   - Rails model validation만 있고 에러 메시지가 view에 전달 안됨

3. **Devise i18n 설정 누락**
   - `config/locales/devise.ko.yml` 한글 메시지 설정 필요
   - `config/application.rb`에서 `config.i18n.default_locale = :ko` 설정 필요

**수정 필요 파일**:
```ruby
# app/views/layouts/application.html.erb
<% if flash[:alert] %>
  <div class="alert alert-danger"><%= flash[:alert] %></div>
<% end %>
<% if flash[:notice] %>
  <div class="alert alert-success"><%= flash[:notice] %></div>
<% end %>

# app/views/devise/registrations/new.html.erb
<%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
  <%= render "devise/shared/error_messages", resource: resource %>
  <!-- 폼 필드들 -->
<% end %>

# config/locales/devise.ko.yml
ko:
  devise:
    failure:
      invalid: "이메일 또는 비밀번호가 올바르지 않습니다."
    registrations:
      signed_up: "회원가입이 완료되었습니다."
  errors:
    messages:
      taken: "이미 사용 중인 이메일입니다."
      too_short: "비밀번호는 최소 %{count}자 이상이어야 합니다."
```

---

### 3. 보안 기능 미구현 (Medium Priority)
**영향받는 테스트**: 006-007 (SQL Injection, XSS)

#### Test 006: SQL Injection 차단
**기대**: SQL injection 시도 시 에러 또는 거부
**실제**: 에러 메시지 표시 안됨

**원인 분석**:
- Rails는 기본적으로 SQL injection 방어함 (parameterized queries)
- 하지만 에러 메시지가 사용자에게 표시 안됨
- 테스트는 악의적 입력을 "무시하고 에러 표시"를 기대

#### Test 007: XSS 차단
**기대**: `<script>` 태그 입력 시 sanitize 또는 에러
**실제**: 에러 메시지 표시 안됨

**원인 분석**:
- Rails는 기본적으로 XSS 방어함 (HTML escaping)
- 하지만 입력 검증 및 에러 메시지가 없음
- 프론트엔드에서 특수문자 입력 제한 필요

**수정 필요**:
```ruby
# app/models/user.rb
validate :email_format

private

def email_format
  if email =~ /<script>|<\/script>|'|"|\-\-/i
    errors.add(:email, "잘못된 형식의 이메일입니다")
  end
end
```

---

### 4. 이메일 형식 검증 실패 (Medium Priority)
**영향받는 테스트**: 008

**기대**: 특수문자, 공백 포함 이메일 거부
**실제**: 에러 메시지 표시 안됨 (16.5초 timeout)

**원인 분석**:
- Devise 기본 이메일 검증은 단순함 (`/@/` 포함 여부만 확인)
- 더 엄격한 이메일 형식 검증 필요

**수정 필요**:
```ruby
# app/models/user.rb
validates :email,
  format: {
    with: URI::MailTo::EMAIL_REGEXP,
    message: "올바른 이메일 형식이 아닙니다"
  }
```

---

### 5. 약관 동의 체크 실패 (Low Priority)
**영향받는 테스트**: 009, 011
**통과한 테스트**: 010 ✅

#### Test 009: 서비스 약관 동의 필수 (실패)
**기대**: 약관 미동의 시 회원가입 거부
**실제**: 에러 메시지 표시 안됨

#### Test 010: 개인정보처리방침 동의 필수 (통과) ✅
**성공 이유**: 이 테스트만 정상 동작

#### Test 011: 마케팅 수신 동의 선택 (실패)
**기대**: 선택적 동의 처리
**실제**: 에러 메시지 표시 안됨

**원인 분석**:
- 약관 동의 체크박스가 DB 스키마에 없거나 validation 없음
- Test 010이 통과한 이유 불명확 (재현 필요)

**수정 필요**:
```ruby
# db/migrate/add_agreements_to_users.rb
add_column :users, :terms_agreed, :boolean, default: false
add_column :users, :privacy_agreed, :boolean, default: false
add_column :users, :marketing_agreed, :boolean, default: false

# app/models/user.rb
validates :terms_agreed, acceptance: true
validates :privacy_agreed, acceptance: true

# app/views/devise/registrations/new.html.erb
<%= f.check_box :terms_agreed %>
<%= f.label :terms_agreed, "서비스 약관에 동의합니다 (필수)" %>
```

---

### 6. 로그인 기능 전체 실패 (Critical)
**영향받는 테스트**: 016-030 (15개 테스트)

#### Test 016: 유효한 자격증명으로 로그인 성공
**에러**: 16.1초 timeout (상세 에러 메시지 미표시)

#### Test 017: 잘못된 이메일로 로그인 실패
**에러**: 16.1초 timeout

#### Test 018: 잘못된 비밀번호로 로그인 실패
**에러**: 16.7초 timeout

#### Test 019-030: 고급 로그인 기능
- 계정 잠금 (5회 실패)
- Remember Me 기능
- 자동 로그아웃 (30분 비활동)
- 다중 디바이스 로그인
- 세션 만료
- CSRF 토큰 검증
- 로그인 히스토리
- 이상 로그인 감지
- 2FA 인증
- IP 차단
- 브루트포스 방어

**원인 분석**:
1. **로그인 페이지 접근 문제**: `/signin` 또는 `/login` 라우트 미설정
2. **Devise 세션 컨트롤러 미구현**: 기본 Devise 컨트롤러만 사용
3. **고급 보안 기능 미구현**: Epic 14 기능들 (2FA, 계정 잠금, 히스토리 등)

**수정 우선순위**:
1. ✅ **P0 (즉시)**: 기본 로그인 성공 (016-018)
2. 🔲 **P1 (중요)**: Remember Me, 세션 만료 (020, 023)
3. 🔲 **P2 (향후)**: 보안 기능 (019, 024-030)

---

## 🎯 실패 원인 분류

### A. 프론트엔드 이슈 (View/Template)
1. **Flash 메시지 렌더링 누락** (모든 validation 에러)
   - 파일: `app/views/layouts/application.html.erb`
   - 수정: flash 메시지 출력 코드 추가

2. **Error partial 누락** (Devise 폼 에러)
   - 파일: `app/views/devise/shared/_error_messages.html.erb`
   - 수정: Devise 기본 partial 추가

3. **약관 동의 체크박스 누락** (009, 011)
   - 파일: `app/views/devise/registrations/new.html.erb`
   - 수정: 약관 체크박스 폼 필드 추가

### B. 백엔드 이슈 (Controller/Model)
1. **회원가입 후 리다이렉션 오류** (001)
   - 파일: `app/controllers/users/registrations_controller.rb`
   - 수정: `after_sign_up_path_for` 메서드 구현

2. **로그인 컨트롤러 미구현** (016-030)
   - 파일: `app/controllers/users/sessions_controller.rb`
   - 수정: Devise sessions controller 커스터마이징

3. **약관 동의 validation 없음** (009, 011)
   - 파일: `app/models/user.rb`
   - 수정: `validates :terms_agreed, acceptance: true`

### C. 설정 이슈 (Config/Localization)
1. **한글 에러 메시지 없음** (모든 validation)
   - 파일: `config/locales/devise.ko.yml`
   - 수정: Devise 한글 locale 파일 추가

2. **라우트 미설정** (로그인 페이지)
   - 파일: `config/routes.rb`
   - 수정: `/dashboard`, `/welcome` 라우트 추가

### D. 기능 미구현 (Epic 1, 14)
1. **2FA 인증** (027-028)
   - Epic 14 기능
   - 미구현 상태

2. **계정 잠금/보안** (019, 024-030)
   - Epic 14 기능
   - 미구현 상태

---

## 🔧 수정 우선순위 (P0 → P2)

### P0 (Critical - 즉시 수정 필요)
이슈 ID | 내용 | 영향받는 테스트 | 예상 소요 시간
--------|------|----------------|---------------
P0-1 | 회원가입 후 리다이렉션 수정 | 001 | 30분
P0-2 | Flash 메시지 렌더링 추가 | 002-011 | 1시간
P0-3 | Devise error partial 추가 | 002-011 | 30분
P0-4 | 로그인 기본 기능 구현 | 016-018 | 2시간

**P0 합계**: 4시간 (6개 테스트 → 18개 테스트 수정 가능)

### P1 (High Priority - 금주 내 수정)
이슈 ID | 내용 | 영향받는 테스트 | 예상 소요 시간
--------|------|----------------|---------------
P1-1 | 한글 locale 설정 | 002-011 | 1시간
P1-2 | 이메일 형식 검증 강화 | 008 | 30분
P1-3 | 약관 동의 필드 추가 | 009, 011 | 1.5시간
P1-4 | Remember Me 기능 | 020 | 1시간
P1-5 | 세션 만료 처리 | 023 | 1시간

**P1 합계**: 5시간 (4개 테스트 추가 수정)

### P2 (Medium Priority - 향후 구현)
이슈 ID | 내용 | 영향받는 테스트 | 예상 소요 시간
--------|------|----------------|---------------
P2-1 | 계정 잠금 (5회 실패) | 019 | 2시간
P2-2 | 2FA 인증 | 027-028 | 4시간
P2-3 | 로그인 히스토리 | 025 | 2시간
P2-4 | 이상 로그인 감지 | 026 | 3시간
P2-5 | IP 차단/브루트포스 방어 | 029-030 | 3시간

**P2 합계**: 14시간 (Epic 14 기능, 7개 테스트)

---

## 📋 수정 체크리스트

### Step 1: P0 수정 (4시간)
- [ ] `app/controllers/users/registrations_controller.rb` 수정
  ```ruby
  def after_sign_up_path_for(resource)
    dashboard_path
  end
  ```
- [ ] `app/views/layouts/application.html.erb` 수정
  ```erb
  <%= render 'shared/flash_messages' %>
  ```
- [ ] `app/views/shared/_flash_messages.html.erb` 생성
  ```erb
  <% flash.each do |type, message| %>
    <div class="alert alert-<%= type %>"><%= message %></div>
  <% end %>
  ```
- [ ] `app/views/devise/shared/_error_messages.html.erb` 생성 (Devise 기본)
- [ ] `app/controllers/users/sessions_controller.rb` 생성
  ```ruby
  class Users::SessionsController < Devise::SessionsController
    def after_sign_in_path_for(resource)
      dashboard_path
    end
  end
  ```

### Step 2: P1 수정 (5시간)
- [ ] `config/locales/devise.ko.yml` 생성 (Devise i18n)
- [ ] `config/application.rb` 수정
  ```ruby
  config.i18n.default_locale = :ko
  ```
- [ ] `app/models/user.rb` 이메일 검증 강화
- [ ] User 마이그레이션: 약관 동의 필드 추가
- [ ] `app/views/devise/registrations/new.html.erb` 약관 체크박스 추가

### Step 3: P2 수정 (14시간 - Epic 14)
- [ ] 계정 잠금 기능 (`lockable` Devise module)
- [ ] 2FA 인증 (`devise-two-factor` gem)
- [ ] 로그인 히스토리 (LoginHistory 모델)
- [ ] 이상 로그인 감지 (IP/UA 변경 감지)
- [ ] IP 차단 리스트 (BlockedIP 모델)
- [ ] 브루트포스 방어 (Rack::Attack gem)

---

## 🚀 다음 단계

### 즉시 실행 (P0)
1. ✅ 백엔드 테스트 완료 확인 (39/39 passed)
2. 🔄 E2E 테스트 실패 분석 완료 (현재 문서)
3. ⏭️ P0 이슈 수정 시작
   - 회원가입 리다이렉션 수정
   - Flash 메시지 렌더링 추가
   - 로그인 기본 기능 구현

### 테스트 재실행 계획
```bash
# P0 수정 후
npx playwright test tests/e2e/bmad-auth-comprehensive.spec.ts \
  --grep "001|002|003|004|005|016|017|018" \
  --reporter=list

# P1 수정 후
npx playwright test tests/e2e/bmad-auth-comprehensive.spec.ts \
  --grep "008|009|011|020|023" \
  --reporter=list

# 전체 재테스트
npx playwright test tests/e2e/bmad-auth-comprehensive.spec.ts \
  --reporter=list
```

---

## 📊 예상 개선 효과

### P0 수정 후 (4시간)
- 통과율: 3.33% (1/30) → **60%** (18/30)
- 주요 개선: 회원가입 기본 흐름, 로그인 기본 흐름

### P0 + P1 수정 후 (9시간)
- 통과율: 60% (18/30) → **73%** (22/30)
- 주요 개선: 에러 메시지, 약관 동의, 세션 관리

### P0 + P1 + P2 수정 후 (23시간)
- 통과율: 73% (22/30) → **97%** (29/30)
- 주요 개선: Epic 14 보안 기능 완전 구현

---

## 📝 참고 사항

### SKIP_SERVER=1 환경 변수
- 현재 설정: 외부 Rails 서버 필요
- 테스트 실행 전: `rails server -p 3000` 실행 필요
- 또는 `playwright.config.ts`에서 `webServer` 설정 추가

### 320개 전체 테스트
- 현재 실행: 30/320 (1.1 회원가입 + 1.2 로그인)
- 미실행: 290개 테스트
  - 1.3 비밀번호 재설정
  - 1.4 이메일 인증
  - 1.5 OAuth (Google, Kakao)
  - 2. 파일 업로드 (Epic 2)
  - 3. AI 연동 (Epic 3)
  - 4-17. 기타 Epic 기능들

### 스크린샷 및 트레이스
- 위치: `test-results/`
- 각 실패 테스트마다:
  - Screenshot (PNG)
  - Video (WebM)
  - Trace (ZIP - `npx playwright show-trace`)
  - Error Context (MD)

---

**작성자**: Claude (AI Assistant)
**테스트 프레임워크**: Playwright v1.49.0
**Rails 버전**: 7.2.3
**보고서 버전**: 1.0
