# Rails E2E 테스트 가이드

## 개요

이 디렉토리는 Rails 애플리케이션의 **End-to-End (E2E) 테스트**를 포함합니다.
모든 테스트는 **Rails Best Practices**를 기반으로 작성되었으며, 실제 사용자 흐름을 시뮬레이션합니다.

## 테스트 구조

### 1. `rails-e2e-comprehensive.spec.ts`

전체 45개의 E2E 테스트 시나리오를 포함한 종합 테스트 파일입니다.

#### 테스트 카테고리

| 카테고리 | 테스트 수 | 설명 |
|---------|----------|------|
| **Epic 1: 사용자 인증** | 5 | 회원가입, 로그인, 2FA, OAuth |
| **Epic 2: 학습 자료 업로드** | 4 | Study Set 생성, PDF 업로드, 처리 상태 확인 |
| **Epic 3: PDF 문제 추출** | 3 | 자동 추출, 수동 추가, 검증 |
| **Epic 15: 대시보드** | 5 | 대시보드 로드, 통계, 차트, 필터, 내보내기 |
| **Epic 4: 시험 세션** | 3 | 시험 시작, 문제 풀이, 결과 확인 |
| **Epic 9: CBT 모드** | 4 | 일시정지/재개, 북마크, 네비게이션, 자동 저장 |
| **Epic 10: 답안 랜덤화** | 2 | 랜덤화 시험, 통계 확인 |
| **Epic 13: 추천 시스템** | 2 | 학습 경로 추천, 개인화 추천 |
| **Epic 14: 지식 그래프** | 2 | 3D 그래프 로드, 노드 인터랙션 |
| **성능 테스트** | 3 | N+1 방지, select 최적화, 캐싱 효과 |
| **보안 테스트** | 3 | CSRF, SQL Injection, XSS 방지 |
| **프로필 관리** | 4 | 조회, 수정, 아바타 업로드, 비밀번호 변경 |
| **결제 시스템** | 2 | 결제 페이지, 구독 상태 |
| **시험 일정** | 3 | 예정 시험, 달력, 알림 등록 |

**총 45개 테스트**

## Rails Best Practices 검증

이 테스트는 다음 Rails Best Practices 규칙을 검증합니다:

### 1. Database Query Optimization
- ✅ `db-select-specific` - 필요한 컬럼만 선택 (테스트 016, 032)
- ✅ `db-exists-vs-present` - exists? 사용 (테스트 018)
- ✅ `db-counter-cache` - 카운터 캐시 사용

### 2. N+1 Query Prevention
- ✅ `n1-includes` - 연관 데이터 Eager Loading (테스트 008, 013, 031)

### 3. Caching Strategies
- ✅ `cache-fragment` - 프래그먼트 캐싱 (테스트 033)
- ✅ `cache-low-level` - Rails.cache 사용 (테스트 015)
- ✅ `cache-query` - 쿼리 결과 캐싱 (테스트 029)

### 4. ActiveRecord Performance
- ✅ `ar-bulk-insert` - 대량 삽입 최적화 (테스트 007, 018)
- ✅ `ar-readonly` - 읽기 전용 레코드 (테스트 020)
- ✅ `ar-update-columns` - 콜백 스킵 (테스트 021)

### 5. Controller Optimization
- ✅ `controller-strong-params` - Strong Parameters 사용 (모든 폼 제출 테스트)

### 6. Background Jobs
- ✅ `job-sidekiq` - 백그라운드 작업 (테스트 010, 027)
- ✅ `job-idempotent` - 재시도 가능한 작업 (테스트 009)

### 7. Security & Best Practices
- ✅ `security-csrf` - CSRF 보호 (테스트 034)
- ✅ `security-sql-injection` - SQL 인젝션 방지 (테스트 035)
- ✅ `security-sanitize` - XSS 방지 (테스트 036)

## 실행 방법

### 전체 테스트 실행

```bash
# 모든 E2E 테스트 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts

# 헤드리스 모드 OFF (브라우저 표시)
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --headed

# 특정 브라우저에서만 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --project=chromium
```

### 특정 테스트 그룹 실행

```bash
# Epic 1 테스트만 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "Epic 1"

# 성능 테스트만 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "Performance"

# 보안 테스트만 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "Security"

# 대시보드 테스트만 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "Epic 15"
```

### 특정 테스트 케이스 실행

```bash
# 테스트 번호로 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "001\\."
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "013\\."

# 여러 테스트 동시 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "001\\.|002\\.|003\\."
```

### 병렬 실행

```bash
# 4개의 워커로 병렬 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --workers=4

# 최대 속도로 병렬 실행
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --workers=100%
```

### 디버그 모드

```bash
# Playwright Inspector로 디버그
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --debug

# 특정 테스트만 디버그
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "001\\." --debug
```

### 리포터 옵션

```bash
# 리스트 형식 출력
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --reporter=list

# HTML 리포트 생성
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --reporter=html

# JSON 결과 생성
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --reporter=json --output=results.json
```

## 환경 설정

### 1. Rails 서버 실행

테스트 실행 전에 Rails 서버가 실행 중이어야 합니다:

```bash
cd rails-api
bin/rails server -p 3000
```

### 2. 환경 변수 설정

`.env` 파일 또는 환경 변수로 설정:

```bash
export BASE_URL=http://localhost:3000
```

### 3. 테스트 데이터 준비

```bash
# 데이터베이스 초기화
cd rails-api
bin/rails db:reset
bin/rails db:seed
```

## 픽스처 파일

테스트에 필요한 샘플 파일:

- `fixtures/sample-exam.pdf` - PDF 업로드 테스트용
- `fixtures/avatar.jpg` - 아바타 업로드 테스트용

이 파일들이 없으면 해당 테스트는 스킵됩니다.

## 성능 벤치마크

### 예상 성능 지표

| 테스트 | 최대 허용 시간 | 설명 |
|--------|--------------|------|
| 031. 대시보드 로드 | 2초 | N+1 방지 효과 |
| 032. 대량 문제 조회 | 1.5초 | select() 최적화 |
| 033. 캐싱 효과 | 첫 로드 대비 50% 감소 | Fragment 캐싱 |

### 성능 측정 방법

```bash
# 성능 테스트만 실행하고 시간 측정
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --grep "Performance" --reporter=list
```

## 문제 해결

### 1. 테스트 타임아웃

테스트가 타임아웃되는 경우:

```bash
# 타임아웃 시간 증가 (기본 30초)
npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts --timeout=60000
```

### 2. 서버 연결 실패

Rails 서버가 실행 중인지 확인:

```bash
curl http://localhost:3000/up
```

### 3. 데이터베이스 문제

테스트 데이터베이스 리셋:

```bash
cd rails-api
RAILS_ENV=test bin/rails db:reset
```

### 4. 캐시 문제

Rails 캐시 클리어:

```bash
cd rails-api
bin/rails tmp:cache:clear
```

## CI/CD 통합

### GitHub Actions 예시

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3.0
          bundler-cache: true

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: 20

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Setup Database
        run: |
          cd rails-api
          bin/rails db:create db:schema:load

      - name: Start Rails Server
        run: |
          cd rails-api
          bin/rails server -p 3000 &
          sleep 5

      - name: Run E2E Tests
        run: npx playwright test tests/e2e/rails-e2e-comprehensive.spec.ts

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
```

## 테스트 작성 가이드

새로운 E2E 테스트를 추가할 때:

1. **테스트 네이밍**: `XXX. 기능 설명` 형식 사용
2. **Rails Best Practice 주석**: 해당 테스트가 검증하는 규칙 명시
3. **독립성**: 각 테스트는 독립적으로 실행 가능해야 함
4. **클린업**: `beforeEach`로 테스트 환경 초기화

### 예시

```typescript
test('046. 새로운 기능 테스트', async ({ page }) => {
  // Rails Best Practice: n1-includes
  // 설명: 새로운 기능의 N+1 쿼리 방지 검증

  await page.goto(`${BASE_URL}/new-feature`);

  // 테스트 로직...

  await expect(page.locator('[data-testid="result"]')).toBeVisible();
});
```

## 테스트 커버리지

현재 테스트 커버리지:

- **Epic 1 (사용자 인증)**: 100% (5/5 스토리)
- **Epic 2 (학습 자료)**: 80% (4/5 스토리)
- **Epic 3 (문제 추출)**: 75% (3/4 스토리)
- **Epic 4 (시험 세션)**: 75% (3/4 스토리)
- **Epic 9 (CBT 모드)**: 100% (4/4 스토리)
- **Epic 10 (랜덤화)**: 50% (2/4 스토리)
- **Epic 13 (추천)**: 40% (2/5 스토리)
- **Epic 14 (지식 그래프)**: 50% (2/4 스토리)
- **Epic 15 (대시보드)**: 100% (5/5 스토리)

**전체 커버리지**: 약 75%

## 추가 리소스

- [Playwright 공식 문서](https://playwright.dev)
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [Rails Best Practices](https://rails-bestpractices.com)
- [프로젝트 Wiki](../../../docs/)

## 문의 및 기여

테스트 관련 이슈나 개선 사항은 GitHub Issues를 통해 제안해주세요.
