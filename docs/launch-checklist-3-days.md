# 즉시 출고 체크리스트 (3일 계획)
**CertiGraph MVP Launch Checklist**
**작성일**: 2026-01-18
**목표**: 2026-01-21 소프트 런치

---

## 📅 Day 1: 필수 기능 보완 (6시간)

### ✅ Task 1.1: 관리자 Question 관리 인터페이스 (3시간)

**목표**: 관리자가 문제를 직접 입력/편집할 수 있는 인터페이스

#### 구현 사항:
- [ ] 1.1.1 Admin 네임스페이스 생성
  ```bash
  rails generate controller Admin::Questions index new create edit update destroy
  ```

- [ ] 1.1.2 Question 입력 폼 구현
  - 문제 내용 (textarea)
  - 보기 4-5개 (동적 추가)
  - 정답 선택 (radio)
  - 난이도 선택 (dropdown)
  - 주제/장 입력

- [ ] 1.1.3 Question 목록 페이지
  - Study Material별 필터
  - 검색 기능
  - 페이지네이션

- [ ] 1.1.4 CSV Bulk Import (선택)
  ```ruby
  # CSV 형식: content, option_1, option_2, option_3, option_4, answer, difficulty, topic
  ```

**예상 시간**: 3시간
**우선순위**: P0

---

### ✅ Task 1.2: PDF 업로드 비활성화 (30분)

**목표**: MVP에서 PDF 업로드 기능을 일시적으로 비활성화

#### 구현 사항:
- [ ] 1.2.1 StudyMaterialsController 수정
  ```ruby
  def create
    @study_material = @study_set.study_materials.build(study_material_params)
    @study_material.status = 'manual' # 새 상태 추가

    # PDF processing 비활성화
    # if @study_material.pdf_file.attached?
    #   ProcessPdfJob.perform_later(@study_material.id)
    # end

    if @study_material.save
      redirect_to @study_material, notice: '학습 자료가 생성되었습니다. 문제를 추가해주세요.'
    end
  end
  ```

- [ ] 1.2.2 Upload UI 숨기기
  - `app/views/study_materials/new.html.erb`에서 PDF 업로드 필드 주석처리
  - 안내 메시지 추가: "베타 기간 동안 관리자가 문제를 추가합니다"

- [ ] 1.2.3 Routes 정리
  ```ruby
  # Temporarily disable PDF processing routes
  # post 'process', to: 'study_materials#process_pdf'
  ```

**예상 시간**: 30분
**우선순위**: P0

---

### ✅ Task 1.3: Validation 에러 메시지 개선 (1시간)

**목표**: Epic 1 P1 이슈 해결 - 사용자에게 명확한 에러 메시지 표시

#### 구현 사항:
- [ ] 1.3.1 회원가입 폼 개선
  ```erb
  <!-- app/views/devise/registrations/new.html.erb -->
  <%= form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>
    <%= render "devise/shared/error_messages", resource: resource %>

    <!-- 각 필드에 에러 메시지 표시 -->
    <div class="field">
      <%= f.label :email %>
      <%= f.email_field :email, autofocus: true, class: "form-control" %>
      <% if resource.errors[:email].any? %>
        <span class="text-red-600 text-sm"><%= resource.errors[:email].first %></span>
      <% end %>
    </div>
  <% end %>
  ```

- [ ] 1.3.2 Flash 메시지 스타일링
  - Tailwind CSS 적용
  - 성공/경고/에러 구분

- [ ] 1.3.3 서비스 약관 동의 필수화
  ```ruby
  # User model
  validates :terms_agreement, acceptance: true, message: "서비스 약관에 동의해주세요"
  ```

**예상 시간**: 1시간
**우선순위**: P1

---

### ✅ Task 1.4: 데이터 검증 (30분)

**목표**: 기존 150문제가 정상 작동하는지 확인

#### 검증 사항:
- [ ] 1.4.1 150문제 데이터 확인
  ```bash
  rails console
  > Question.count  # 150
  > Question.where(validation_status: 'validated').count
  > Question.where(options: nil).count  # 0이어야 함
  > Question.where(answer: nil).count  # 0이어야 함
  ```

- [ ] 1.4.2 손상된 데이터 정리
  ```ruby
  # 보기가 없는 문제 삭제
  Question.where(options: nil).destroy_all

  # 정답이 없는 문제 삭제
  Question.where(answer: nil).destroy_all
  ```

- [ ] 1.4.3 Study Set 검증
  ```ruby
  StudySet.all.each do |ss|
    puts "#{ss.title}: #{ss.questions.count} questions"
  end
  ```

**예상 시간**: 30분
**우선순위**: P0

---

## 📅 Day 2: UI/UX 개선 (6시간)

### ✅ Task 2.1: Landing Page 구현 (2시간)

**목표**: 비로그인 사용자를 위한 소개 페이지

#### 구현 사항:
- [ ] 2.1.1 Home Controller 생성
  ```bash
  rails generate controller Home index
  ```

- [ ] 2.1.2 Landing Page 디자인
  ```erb
  <!-- app/views/home/index.html.erb -->
  <div class="hero">
    <h1>AI 자격증 마스터</h1>
    <p>사회복지사 1급 실전 문제 150개로 시작하세요</p>

    <div class="features">
      <div>✅ 실전 CBT 시험 환경</div>
      <div>✅ 오답 기반 맞춤 재시험</div>
      <div>✅ 상세한 학습 통계</div>
    </div>

    <%= link_to "무료 회원가입", new_user_registration_path, class: "btn-primary" %>
    <%= link_to "데모 시험 체험", demo_exam_path, class: "btn-secondary" %>
  </div>
  ```

- [ ] 2.1.3 Routes 설정
  ```ruby
  root 'home#index'
  get 'demo', to: 'exams#demo', as: 'demo_exam'
  ```

**예상 시간**: 2시간
**우선순위**: P1

---

### ✅ Task 2.2: Onboarding Flow (2시간)

**목표**: 첫 사용자에게 서비스 사용법 안내

#### 구현 사항:
- [ ] 2.2.1 첫 로그인 감지
  ```ruby
  # ApplicationController
  after_action :check_first_login

  def check_first_login
    if current_user && current_user.sign_in_count == 1
      redirect_to onboarding_path
    end
  end
  ```

- [ ] 2.2.2 Onboarding 페이지
  - Step 1: 서비스 소개
  - Step 2: Study Set 선택 가이드
  - Step 3: 첫 시험 시작
  - Step 4: Dashboard 소개

- [ ] 2.2.3 Stimulus Controller (선택)
  ```javascript
  // app/javascript/controllers/onboarding_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    connect() {
      // Show tooltip on important buttons
    }
  }
  ```

**예상 시간**: 2시간
**우선순위**: P2

---

### ✅ Task 2.3: Error Handling & Empty States (2시간)

**목표**: 예외 상황에 대한 사용자 친화적 처리

#### 구현 사항:
- [ ] 2.3.1 404/500 에러 페이지
  ```erb
  <!-- public/404.html -->
  <!-- public/500.html -->
  ```

- [ ] 2.3.2 빈 상태 UI
  ```erb
  <!-- app/views/study_sets/index.html.erb -->
  <% if @study_sets.empty? %>
    <div class="empty-state">
      <p>아직 학습 세트가 없습니다</p>
      <%= link_to "첫 시험 시작하기", available_study_sets_path %>
    </div>
  <% end %>
  ```

- [ ] 2.3.3 문제 없는 Study Set 처리
  ```ruby
  # exam_sessions_controller.rb
  def create
    unless @study_set.questions.exists?
      redirect_to @study_set, alert: '이 학습 세트에는 아직 문제가 없습니다. 다른 세트를 선택해주세요.'
      return
    end
  end
  ```

**예상 시간**: 2시간
**우선순위**: P1

---

## 📅 Day 3: 테스트 & 배포 (6시간)

### ✅ Task 3.1: End-to-End 테스트 (2시간)

**목표**: 전체 사용자 플로우 검증

#### 테스트 시나리오:
- [ ] 3.1.1 회원가입 플로우
  ```
  1. Landing Page 방문
  2. "회원가입" 클릭
  3. 이메일/비밀번호 입력
  4. 서비스 약관 동의
  5. 회원가입 완료 → Dashboard로 이동
  ```

- [ ] 3.1.2 시험 응시 플로우
  ```
  1. Dashboard에서 "모의고사 시작" 클릭
  2. Study Set 선택
  3. 문제 수 선택 (10문제)
  4. 시험 시작
  5. 10문제 모두 답안 제출
  6. 시험 완료
  7. 결과 페이지 확인 (점수, 정답/오답)
  ```

- [ ] 3.1.3 오답노트 플로우
  ```
  1. 결과 페이지에서 "오답 다시 풀기" 클릭
  2. 오답 문제만 출제 확인
  3. 재시험 완료
  4. 개선된 점수 확인
  ```

- [ ] 3.1.4 Dashboard 확인
  ```
  1. 학습 통계 표시 확인
  2. 차트 렌더링 확인 (Chart.js)
  3. 최근 시험 목록 확인
  ```

**테스트 도구**:
```bash
# Playwright E2E 테스트
npx playwright test tests/e2e/mvp-launch.spec.ts --headed

# 또는 수동 테스트
```

**예상 시간**: 2시간
**우선순위**: P0

---

### ✅ Task 3.2: 데이터베이스 마이그레이션 (2시간)

**목표**: SQLite → PostgreSQL 전환 (프로덕션 준비)

#### 구현 사항:
- [ ] 3.2.1 PostgreSQL 설치 및 설정
  ```bash
  # macOS
  brew install postgresql@16
  brew services start postgresql@16

  # Create database
  createdb certigraph_production
  ```

- [ ] 3.2.2 database.yml 수정
  ```yaml
  production:
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    database: certigraph_production
    username: <%= ENV['DATABASE_USERNAME'] %>
    password: <%= ENV['DATABASE_PASSWORD'] %>
    host: <%= ENV['DATABASE_HOST'] %>
  ```

- [ ] 3.2.3 데이터 마이그레이션
  ```bash
  # SQLite → PostgreSQL 데이터 이전
  RAILS_ENV=production rails db:create
  RAILS_ENV=production rails db:migrate

  # Seed data
  RAILS_ENV=production rails db:seed
  ```

- [ ] 3.2.4 pg gem 추가
  ```ruby
  # Gemfile
  gem 'pg', '~> 1.5'
  ```

**예상 시간**: 2시간
**우선순위**: P0 (프로덕션 필수)

---

### ✅ Task 3.3: 배포 (2시간)

**목표**: 프로덕션 서버에 배포

#### 배포 플랫폼 선택:
**Option A: Railway (추천)**
- 무료 티어: $5 크레딧/월
- PostgreSQL 포함
- 간단한 배포

**Option B: Fly.io**
- 무료 티어 존재
- 더 많은 제어

**Option C: Heroku**
- 유료 ($7/월)
- 검증된 플랫폼

#### Railway 배포 단계:
- [ ] 3.3.1 Railway 계정 생성
  ```bash
  npm install -g @railway/cli
  railway login
  ```

- [ ] 3.3.2 프로젝트 초기화
  ```bash
  railway init
  railway link
  ```

- [ ] 3.3.3 환경변수 설정
  ```bash
  railway variables set RAILS_ENV=production
  railway variables set RAILS_MASTER_KEY=$(cat config/master.key)
  railway variables set DATABASE_URL=<PostgreSQL URL>
  ```

- [ ] 3.3.4 배포 실행
  ```bash
  railway up
  railway run rails db:migrate
  railway run rails db:seed
  ```

- [ ] 3.3.5 도메인 설정
  ```
  Custom domain: certigraph.railway.app → certigraph.com
  ```

**예상 시간**: 2시간
**우선순위**: P0

---

## 📊 Launch Criteria (Go/No-Go)

### ✅ Must Pass (모두 체크되어야 출시)
- [ ] 회원가입/로그인 정상 작동
- [ ] 최소 100문제 보유 (현재 150)
- [ ] Mock Exam 전체 플로우 작동
- [ ] 채점 및 결과 페이지 표시
- [ ] Dashboard 통계 표시
- [ ] 모바일 반응형 (기본 확인)
- [ ] 프로덕션 서버 배포 완료
- [ ] SSL 인증서 적용 (Railway 자동)

### ⚠️ Nice to Have (선택)
- [ ] Onboarding 플로우
- [ ] Landing Page 디자인 완성
- [ ] Chart.js 차트 표시
- [ ] CSV Bulk Import

---

## 🚀 Launch Day Checklist (D-Day)

### Launch 3시간 전
- [ ] 프로덕션 서버 상태 확인
- [ ] 데이터베이스 백업
- [ ] 로그 모니터링 준비
- [ ] Sentry/에러 트래킹 확인 (선택)

### Launch 1시간 전
- [ ] 최종 E2E 테스트 (프로덕션 환경)
- [ ] Performance 확인 (Lighthouse)
- [ ] SEO 기본 설정 확인

### Launch 순간
- [ ] Soft Launch 안내 (VIP 10명)
- [ ] 피드백 채널 오픈 (이메일/Discord)
- [ ] 실시간 모니터링 시작

### Launch 후 24시간
- [ ] 사용자 피드백 수집
- [ ] 에러 로그 확인
- [ ] 핫픽스 준비

---

## 🎯 Success Metrics (첫 주)

### 사용자 지표
- 회원가입: **50명+** (목표)
- 시험 완료: **100회+**
- 평균 학습 시간: **30분+**
- 재방문율: **40%+**

### 기술 지표
- 서버 응답 시간: **< 500ms**
- 에러율: **< 1%**
- 가동 시간: **99%+**

### 피드백 수집
- 설문조사 응답: **20명+**
- NPS 점수: **6점+** (10점 만점)

---

## 📞 긴급 연락망

### 기술 이슈
- 서버 다운: Railway 대시보드 확인
- 데이터베이스 오류: PostgreSQL 로그
- 애플리케이션 에러: Rails 로그

### 비즈니스 이슈
- 사용자 문의: support@certigraph.com
- 버그 리포트: GitHub Issues

---

## ✅ 체크리스트 요약

**Day 1 (6시간)**:
- [ ] 관리자 Question 인터페이스 (3h)
- [ ] PDF 업로드 비활성화 (0.5h)
- [ ] Validation 에러 메시지 (1h)
- [ ] 데이터 검증 (0.5h)

**Day 2 (6시간)**:
- [ ] Landing Page (2h)
- [ ] Onboarding Flow (2h)
- [ ] Error Handling (2h)

**Day 3 (6시간)**:
- [ ] E2E 테스트 (2h)
- [ ] PostgreSQL 마이그레이션 (2h)
- [ ] 프로덕션 배포 (2h)

**Total**: 18시간 (3일 × 6시간)

---

**작성자**: KPM Orchestrator
**검토자**: [Project Owner]
**최종 업데이트**: 2026-01-18
