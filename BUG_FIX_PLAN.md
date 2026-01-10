# 🐛 테스트 실패 분석 및 버그 수정 계획

## 📊 테스트 실행 결과

### 실행 정보
- **실행 일시**: 2026-01-11 07:08:23 KST
- **테스트 그룹**: independent-e2e
- **총 테스트**: 98개
- **Worker**: 8개 병렬

### 실패 요약
- **실패 테스트**: 5개 (조기 종료)
- **실패 원인**: `TimeoutError: page.goto: Timeout 30000ms exceeded`
- **영향받은 테스트**:
  1. 151. 지식 그래프 자동 생성
  2. 154. 선수 지식 체인 분석
  3. 153. 개념 관계 매핑
  4. (추가 2개)

## 🔍 근본 원인 분석

### Issue #1: 페이지 로딩 타임아웃

#### 증상
```
TimeoutError: page.goto: Timeout 30000ms exceeded.
Call log:
  - navigating to "http://localhost:3030/", waiting until "load"
```

#### 원인 분석
1. **프론트엔드 서버 응답 지연**
   - 포트 3030에서 실행 중인 서버가 느리게 응답
   - 초기 페이지 로드가 30초를 초과

2. **네비게이션 타임아웃 설정 부족**
   - 현재 설정: 30초
   - 필요: 60초 이상 (복잡한 React 앱)

3. **beforeEach에서 매번 페이지 로드**
   - 모든 테스트마다 홈페이지로 이동
   - 불필요한 반복 로딩

#### 영향도
- **심각도**: 🔴 High
- **영향 범위**: 모든 E2E 테스트
- **차단 여부**: Yes (테스트 진행 불가)

## 🛠️ 수정 계획

### Fix #1: 네비게이션 타임아웃 증가

#### 수정 위치
`playwright.config.ts`

#### 수정 내용
```typescript
use: {
  // 기존
  navigationTimeout: 30 * 1000,  // 30초
  
  // 수정
  navigationTimeout: 60 * 1000,  // 60초로 증가
}
```

#### 우선순위
🔴 P0 - 즉시 수정 필요

---

### Fix #2: 페이지 로드 대기 전략 개선

#### 수정 위치
`tests/e2e/bmad-knowledge-graph.spec.ts`

#### 현재 코드
```typescript
test.beforeEach(async ({ page }) => {
  await page.goto(FRONTEND_URL);
});
```

#### 수정 코드
```typescript
test.beforeEach(async ({ page }) => {
  await page.goto(FRONTEND_URL, {
    waitUntil: 'networkidle',  // 네트워크가 안정될 때까지 대기
    timeout: 60000,             // 60초 타임아웃
  });
  
  // 추가: 페이지가 완전히 로드되었는지 확인
  await page.waitForLoadState('domcontentloaded');
});
```

#### 우선순위
🔴 P0 - 즉시 수정 필요

---

### Fix #3: 프론트엔드 서버 성능 확인

#### 확인 사항
1. 서버가 정상적으로 실행 중인지 확인
2. 포트 3030 접근 가능 여부
3. 빌드 최적화 상태

#### 조치 방법
```bash
# 서버 상태 확인
lsof -ti:3030

# 서버 재시작 (필요시)
cd frontend
npm run dev
```

#### 우선순위
🟡 P1 - 수정 후 확인

---

### Fix #4: 테스트 격리 개선

#### 문제
- 8개 worker가 동시에 같은 페이지 접근
- 서버 부하 증가 가능성

#### 해결 방안
```typescript
// playwright.config.ts
{
  name: 'independent-e2e',
  workers: 4,  // 8개 → 4개로 감소
  fullyParallel: true,
}
```

#### 우선순위
🟢 P2 - 성능 최적화

---

## 📋 수정 체크리스트

### 즉시 수정 (P0)
- [ ] Fix #1: navigationTimeout 60초로 증가
- [ ] Fix #2: page.goto 옵션 개선
- [ ] 수정 사항 커밋

### 검증 단계 (P1)
- [ ] Fix #3: 프론트엔드 서버 상태 확인
- [ ] 실패한 테스트만 재실행
- [ ] 결과 확인

### 최적화 (P2)
- [ ] Fix #4: Worker 수 조정
- [ ] 전체 테스트 재실행
- [ ] 성능 측정

## 🔄 재테스트 계획

### 1단계: 빠른 수정 및 검증
```bash
# 수정 후 실패한 테스트만 재실행
npx playwright test --last-failed
```

### 2단계: 전체 회귀 테스트
```bash
# 모든 테스트 재실행
npm run test:all
```

### 3단계: 안정성 확인
```bash
# 동일 테스트 3회 반복
npx playwright test --project=independent-e2e --repeat-each=3
```

## 📈 예상 결과

### 수정 전
- ❌ 5개 테스트 실패 (타임아웃)
- ⏱️ 조기 종료

### 수정 후 (예상)
- ✅ 모든 테스트 통과
- ⏱️ 예상 시간: 10-15분
- 🎯 성공률: 95%+ 목표

## 🎯 다음 단계

1. ✅ **즉시**: Fix #1, #2 적용
2. 🔄 **재테스트**: 실패한 테스트 재실행
3. 📊 **분석**: 결과 확인 및 추가 이슈 식별
4. 🚀 **진행**: 다음 테스트 그룹 실행

---

**업데이트 예정**: 수정 적용 후 결과 업데이트
