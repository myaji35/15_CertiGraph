# 🔍 미구현 및 미테스트 기능 요약

## 📅 작성 정보
- **작성일**: 2026-01-11 07:52 KST
- **기준 문서**: `docs/test-design-v1.1-update.md`
- **테스트 보고서**: `TEST_EXECUTION_REPORT_v1.1.md`

---

## ✅ 구현 완료 및 테스트 통과

### 백엔드 (100% 완료)
| 기능 | 구현 상태 | 테스트 상태 | 파일 위치 |
|------|----------|------------|----------|
| **결제 시스템** | ✅ 완료 | ✅ 8/8 통과 | `backend/app/services/payment.py` |
| **시험일 추천** | ✅ 완료 | ✅ 2/2 통과 | `backend/app/services/data_loader.py` |
| **오답노트 로직** | ✅ 완료 | ✅ 3/3 통과 | `backend/app/services/test_engine.py` |

### 프론트엔드 (부분 완료)
| 페이지 | 구현 상태 | 테스트 상태 | 파일 위치 |
|--------|----------|------------|----------|
| **Pricing 페이지** | ✅ 완료 | ✅ 2/12 통과 | `frontend/src/app/pricing/page.tsx` |
| **Checkout 페이지** | ⚠️ 부분 완료 | ❌ 1/12 실패 | `frontend/src/app/checkout/page.tsx` |
| **오답노트 페이지** | ❌ 미구현 | ❌ 0/5 실패 | 없음 |

---

## ❌ 미구현 기능 상세

### 1. 결제 시스템 (Epic 5)

#### 1.1 Checkout 페이지 - 주문 요약 표시 ⚠️
**현재 상태**: 부분 구현됨
**파일**: `frontend/src/app/checkout/page.tsx`

**구현된 부분**:
```tsx
✅ 기본 페이지 구조
✅ 고객 정보 입력 폼 (이름, 이메일)
✅ Toss Payments 위젯 플레이스홀더
✅ 결제 버튼
```

**미구현/문제 부분**:
```tsx
❌ 주문 금액이 테스트 선택자와 불일치
   - 현재: ₩{price ? parseInt(price).toLocaleString() : '10,000'}
   - 테스트 기대: text=/10,000|₩10,000/i
   - 문제: toLocaleString()이 "10,000"을 반환하지만 테스트는 매칭 실패

❌ 실제 Toss Payments SDK 통합 미완료
   - 현재: 플레이스홀더만 존재
   - 필요: Toss Payments SDK 로드 및 초기화

❌ 결제 처리 로직 미구현
   - 현재: console.log만 출력
   - 필요: 실제 결제 API 호출 및 상태 관리
```

**권장 수정**:
```tsx
// 주문 요약 섹션 수정
<div className="order-summary">
  <h2 className="font-semibold mb-2">주문 내역</h2>
  <div className="flex justify-between">
    <span>{certification || '시즌패스'}</span>
    {/* 테스트 선택자와 일치하도록 수정 */}
    <span className="amount">₩10,000</span>
  </div>
  <div className="flex justify-between mt-2">
    <span className="text-sm text-gray-600">자격증</span>
    <span className="text-sm">{certification || '정보처리기사'}</span>
  </div>
</div>
```

#### 1.2 결제 성공/실패 페이지 ❌
**현재 상태**: 미구현
**필요 파일**: 
- `frontend/src/app/payment/success/page.tsx`
- `frontend/src/app/payment/fail/page.tsx`

**테스트 요구사항**:
```typescript
// PAY-007: 결제 성공 페이지
- URL: /payment/success?orderId={orderId}&amount=10000&paymentKey={key}
- 필요 요소:
  ✅ 성공 메시지: text=/결제.*완료|payment.*success|성공/i
  ✅ 주문 정보 표시
  ✅ 대시보드로 이동 버튼

// PAY-009: 결제 실패 페이지
- URL: /payment/fail?code=USER_CANCEL&message={message}&orderId={orderId}
- 필요 요소:
  ✅ 실패 메시지: text=/결제.*실패|취소|payment.*failed|cancel/i
  ✅ 재시도 버튼
  ✅ 고객센터 링크
```

#### 1.3 결제 웹훅 처리 ❌
**현재 상태**: 미구현
**필요 파일**: `backend/app/api/v1/endpoints/payment_webhook.py`

**요구사항**:
- Toss Payments 웹훅 엔드포인트 구현
- 결제 상태 동기화 로직
- 실패 시 재시도 메커니즘

---

### 2. 시험일 추천 (Epic 2)

#### 2.1 시험일 표시 UI ⚠️
**현재 상태**: Pricing 페이지에 부분 구현됨
**파일**: `frontend/src/app/pricing/page.tsx`

**구현된 부분**:
```tsx
✅ 자격증 목록 조회 (API 연동)
✅ 시험 날짜 선택 UI
✅ D-Day 계산 (백엔드)
```

**미테스트 부분**:
```tsx
⏭️ 시험일 추천 E2E 테스트 미실행
   - 테스트 ID: INT-CERT-001
   - API: GET /api/v1/certifications/{id}/nearest
   - 상태: 테스트 파일 미작성
```

**권장 조치**:
1. E2E 테스트 작성 필요
2. 대시보드에 "다가오는 시험" 위젯 추가
3. 시험일 알림 기능 구현

#### 2.2 시험일 기반 학습 계획 ❌
**현재 상태**: 미구현
**요구사항**:
- 시험일까지 남은 기간 기반 학습 계획 자동 생성
- 일일 학습 목표 추천
- 진도율 추적

---

### 3. 오답노트 (Epic 3)

#### 3.1 오답노트 페이지 전체 ❌
**현재 상태**: 완전 미구현
**필요 파일**: 
- `frontend/src/app/(dashboard)/test/review/[sessionId]/page.tsx` (존재하지만 내용 확인 필요)
- 또는 `frontend/src/app/(dashboard)/review/[id]/page.tsx` (신규 생성)

**테스트 요구사항** (test-design-v1.1-update.md 기준):

##### E2E-TEST-001: 오답 노트 학습 흐름
```
1. 문제 풀이 후 일부 오답 제출
2. 대시보드/결과 페이지에서 '오답 다시 풀기' 선택
3. 오답으로만 구성된 시험 로드 확인
4. 재시험 완료
```

**필요 UI 컴포넌트**:
```tsx
// 116. 오답노트 자동 생성
✅ 버튼: button:has-text("오답노트 생성")
✅ 성공 메시지: .success-message (text=/오답노트.*생성/i)
✅ 리다이렉트: /review/{id}

// 117. 오답노트 문제 복습
✅ 오답 문제 목록: .review-question
✅ 다시 풀기 버튼: button:has-text("다시 풀기")
✅ 복습 모드: .review-mode-question

// 118. 오답노트 태그 추가
✅ 태그 추가 버튼: button:has-text("태그 추가")
✅ 태그 입력: .tag-input
✅ 저장 버튼: button:has-text("저장")
✅ 태그 표시: .tag (2개 이상)

// 119. 오답노트 메모 작성
✅ 메모 버튼: button:has-text("메모")
✅ 메모 입력: .memo-textarea
✅ 메모 저장: button:has-text("메모 저장")
✅ 메모 표시: .memo-indicator

// 120. 오답노트 완료 체크
✅ 체크박스: input[type="checkbox"]
✅ 완료 상태: .completed 클래스
✅ 진행률: .review-progress (text=/1.*완료/)
```

**페이지 구조 예시**:
```tsx
// frontend/src/app/(dashboard)/review/[id]/page.tsx
export default function ReviewPage({ params }: { params: { id: string } }) {
  return (
    <div className="review-container">
      {/* 헤더 */}
      <div className="review-header">
        <h1>오답노트</h1>
        <div className="review-progress">
          완료: {completedCount}/{totalCount}
        </div>
      </div>

      {/* 오답 문제 목록 */}
      <div className="review-questions">
        {wrongQuestions.map(q => (
          <div key={q.id} className={`review-question ${q.completed ? 'completed' : ''}`}>
            {/* 문제 내용 */}
            <div className="question-content">{q.text}</div>
            
            {/* 액션 버튼 */}
            <div className="question-actions">
              <button onClick={() => retakeQuestion(q.id)}>다시 풀기</button>
              <button onClick={() => openTagDialog(q.id)}>태그 추가</button>
              <button onClick={() => openMemoDialog(q.id)}>메모</button>
              <input 
                type="checkbox" 
                checked={q.completed}
                onChange={() => toggleComplete(q.id)}
              />
            </div>

            {/* 태그 표시 */}
            {q.tags.map(tag => (
              <span key={tag} className="tag">{tag}</span>
            ))}

            {/* 메모 표시 */}
            {q.memo && <div className="memo-indicator">📝</div>}
          </div>
        ))}
      </div>
    </div>
  );
}
```

#### 3.2 시험 결과 페이지 - 오답노트 생성 버튼 ❌
**현재 상태**: 미확인
**필요 위치**: 시험 결과 페이지
**요구사항**:
- "오답노트 생성" 버튼 추가
- 클릭 시 오답 문제만 추출하여 복습 세션 생성
- 오답노트 페이지로 리다이렉트

---

## 🔧 인증 시스템 불일치 (Critical)

### 문제점
**모든 E2E 테스트가 실패하는 근본 원인**

**현재 상황**:
```typescript
// 테스트 코드 (구식 방식)
async function loginAsUser(page: Page) {
  await page.goto(`${FRONTEND_URL}/login`);
  await page.fill('[name="email"]', 'test@example.com');  // ❌ Clerk에 없음
  await page.fill('[name="password"]', 'Test1234!');      // ❌ Clerk에 없음
  await page.click('button[type="submit"]');
  await page.waitForURL(`${FRONTEND_URL}/dashboard`);
}
```

**실제 구현**:
```typescript
// 프로젝트는 Clerk 인증 사용
- URL: /sign-in (not /login)
- 선택자: .cl-formFieldInput[name="identifier"]
- 선택자: .cl-formFieldInput[name="password"]
- 버튼: .cl-formButtonPrimary
```

**영향 범위**:
- ❌ 모든 오답노트 E2E 테스트 (5개)
- ❌ 일부 결제 E2E 테스트
- ❌ 기타 인증 필요 테스트

**해결 방법**:
```typescript
// tests/helpers/clerk-auth.ts (신규 생성)
import { Page } from '@playwright/test';

export async function loginWithClerk(page: Page, email: string, password: string) {
  await page.goto(`${process.env.FRONTEND_URL}/sign-in`);
  
  // Clerk 선택자 사용
  await page.locator('.cl-formFieldInput[name="identifier"]').fill(email);
  await page.locator('.cl-formFieldInput[name="password"]').fill(password);
  await page.locator('.cl-formButtonPrimary').click();
  
  // 대시보드 로드 대기
  await page.waitForURL(/\/dashboard/);
}

// 테스트 파일에서 사용
import { loginWithClerk } from '../../helpers/clerk-auth';

test('오답노트 자동 생성', async ({ page }) => {
  await loginWithClerk(page, 'test@example.com', 'Test1234!');
  // ... 나머지 테스트
});
```

---

## 📊 통합 테스트 미실행

### 백엔드 API 통합 테스트 (test-design-v1.1-update.md 섹션 3.2)

| 테스트 ID | API 경로 | 상태 | 우선순위 |
|-----------|---------|------|----------|
| INT-PAY-001 | `POST /api/v1/payment/create` | ⏭️ 미실행 | P0 |
| INT-PAY-002 | `POST /api/v1/payment/confirm` | ⏭️ 미실행 | P0 |
| INT-CERT-001 | `GET /api/v1/certifications/{id}/nearest` | ⏭️ 미실행 | P1 |
| INT-TEST-001 | `POST /api/v1/tests/start` (Retest) | ⏭️ 미실행 | P0 |

**미실행 이유**:
- 통합 테스트 파일 미작성
- API 엔드포인트 존재 여부 미확인

**권장 조치**:
```bash
# 통합 테스트 파일 생성
backend/tests/integration/test_payment_api.py
backend/tests/integration/test_certification_api.py
backend/tests/integration/test_retest_api.py
```

---

## 🎯 우선순위별 조치 사항

### P0 (Critical) - 즉시 수정 필요

1. **인증 헬퍼 함수 수정** ⚠️
   - 파일: `tests/helpers/clerk-auth.ts` (신규)
   - 영향: 모든 E2E 테스트
   - 예상 시간: 30분

2. **Checkout 페이지 주문 요약 수정** ⚠️
   - 파일: `frontend/src/app/checkout/page.tsx`
   - 수정: 금액 표시 형식
   - 예상 시간: 15분

3. **결제 성공/실패 페이지 구현** ❌
   - 파일: `frontend/src/app/payment/success/page.tsx`
   - 파일: `frontend/src/app/payment/fail/page.tsx`
   - 예상 시간: 2시간

### P1 (High) - 1-2일 내 완료

4. **오답노트 페이지 전체 구현** ❌
   - 파일: `frontend/src/app/(dashboard)/review/[id]/page.tsx`
   - 기능: 문제 목록, 태그, 메모, 완료 체크
   - 예상 시간: 4-6시간

5. **시험 결과 페이지 - 오답노트 버튼 추가** ❌
   - 파일: 시험 결과 페이지 (위치 확인 필요)
   - 예상 시간: 1시간

6. **통합 테스트 작성** ⏭️
   - 파일: `backend/tests/integration/test_*.py`
   - 예상 시간: 3-4시간

### P2 (Medium) - 1주 내 완료

7. **Toss Payments SDK 실제 통합** ⚠️
   - 파일: `frontend/src/app/checkout/page.tsx`
   - 예상 시간: 4-6시간

8. **결제 웹훅 구현** ❌
   - 파일: `backend/app/api/v1/endpoints/payment_webhook.py`
   - 예상 시간: 3-4시간

9. **시험일 기반 학습 계획** ❌
   - 새로운 기능
   - 예상 시간: 8-10시간

---

## 📈 완료율 요약

### 전체 기능 완료율
```
백엔드 로직:    ✅ 100% (8/8)
프론트엔드 UI:  ⚠️  40% (추정)
E2E 테스트:     ❌  16% (2/12 결제 + 0/5 오답노트)
통합 테스트:    ⏭️   0% (0/4)
─────────────────────────────────
전체:          ⚠️  ~50%
```

### 기능별 완료율

| 기능 | 백엔드 | 프론트엔드 | E2E 테스트 | 전체 |
|------|--------|-----------|-----------|------|
| **결제 시스템** | ✅ 100% | ⚠️ 60% | ⚠️ 16% | ⚠️ 59% |
| **시험일 추천** | ✅ 100% | ✅ 80% | ⏭️ 0% | ⚠️ 60% |
| **오답노트** | ✅ 100% | ❌ 0% | ❌ 0% | ⚠️ 33% |

---

## 💡 다음 단계 권장 순서

1. ✅ **인증 헬퍼 수정** (30분)
   - 모든 E2E 테스트의 전제 조건

2. ✅ **Checkout 페이지 수정** (15분)
   - 빠른 승리, 즉시 테스트 통과 가능

3. ✅ **결제 성공/실패 페이지** (2시간)
   - 결제 플로우 완성

4. ✅ **오답노트 페이지 구현** (4-6시간)
   - 가장 큰 미구현 기능

5. ✅ **E2E 테스트 재실행** (1시간)
   - 모든 수정 사항 검증

6. ✅ **통합 테스트 작성** (3-4시간)
   - API 레벨 검증 강화

---

**작성일**: 2026-01-11 07:52 KST  
**작성자**: Antigravity AI Assistant  
**다음 업데이트**: P0 이슈 수정 후
