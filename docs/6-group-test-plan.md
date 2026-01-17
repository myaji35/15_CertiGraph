# CertiGraph E2E 테스트 6개 그룹 계획

생성일: 2026-01-16
총 테스트: 337개 → 6개 그룹으로 분류

---

## 그룹 1: 인증 시스템 (Authentication) 🔐
**테스트 수**: ~50개
**우선순위**: P0 (최고 우선순위)

### 포함 파일:
- `bmad-auth-comprehensive.spec.ts` (001-030) - 30개
- `bmad-auth-social-password.spec.ts` (031-050) - ~20개
- `epic01-auth-registration.spec.ts`
- `parallel/01-user-registration.spec.ts`
- `parallel/02-login-flows.spec.ts`

### 테스트 범위:
- 회원가입 (이메일, 소셜 로그인)
- 로그인/로그아웃
- 비밀번호 관리 (변경, 재설정, 복잡도)
- 이메일 인증
- 2FA 인증
- 세션 관리
- 보안 검증 (SQL Injection, XSS)

### 현재 상태:
- ✅ 기본 회원가입/로그인: 동작
- ✅ 비밀번호 복잡도 검증: 구현됨
- ✅ 입력 보안 (SQL/XSS): 구현됨
- ❌ 이메일 발송: 미구현
- ❌ 2FA UI: 미구현
- ❌ 고급 세션 관리: 미구현

---

## 그룹 2: 학습자료 시스템 (Study Materials) 📚
**테스트 수**: ~40개
**우선순위**: P1

### 포함 파일:
- `bmad-study-materials.spec.ts` (051-090)

### 테스트 범위:
- PDF 업로드
- Upstage OCR 통합
- AI 문제 추출
- 학습자료 메타데이터
- 콘텐츠 구조화
- 태그 & 카테고리
- 마켓플레이스 (판매/구매)

### 현재 상태:
- ✅ StudySet 모델: 존재
- ❌ 업로드 페이지: 미구현
- ❌ OCR 통합: 미구현
- ❌ AI 추출: 미구현
- ❌ 마켓플레이스: 미구현

---

## 그룹 3: 모의고사 시스템 (Mock Exam) 📝
**테스트 수**: ~49개
**우선순위**: P1

### 포함 파일:
- `bmad-mock-exam.spec.ts` (091-139)

### 테스트 범위:
- 모의고사 생성 (챕터별, 난이도별)
- 시험 진행 (타이머, 답안 저장)
- 문제 네비게이션 & 북마크
- 시험 제출 & 채점
- 성적 분석 (챕터별, 난이도별)
- 오답노트 (태그, 메모, 복습)
- 실전/학습 모드
- OMR 답안지

### 현재 상태:
- ✅ ExamSession 모델: 존재
- ✅ Question/Option 모델: 존재
- ❌ 시험 생성 로직: 미구현
- ❌ 시험 진행 UI: 미구현
- ❌ 채점 시스템: 미구현
- ❌ 오답노트: 미구현

---

## 그룹 4: 지식 그래프 & 성능 추적 (Knowledge Graph & Performance) 📊
**테스트 수**: ~60개
**우선순위**: P2

### 포함 파일:
- `bmad-knowledge-graph.spec.ts` (151-180) - 30개
- `bmad-performance.spec.ts` (221-250) - 30개

### 테스트 범위:

#### 지식 그래프 (151-180):
- 3D 뇌 맵 시각화 (Three.js)
- 노드 상호작용 (클릭, 줌, 회전)
- 약점 분석 (빨강/초록/회색)
- 선수 지식 관계
- 학습 경로 추천
- 개념 클러스터링

#### 성능 추적 (221-250):
- 학습 대시보드
- 진도율 차트
- 시간 분석
- 강점/약점 리포트
- 학습 기록 히스토리
- 성과 예측 (ML)

### 현재 상태:
- ✅ KnowledgeNode/Edge 모델: 존재
- ✅ UserMastery 모델: 존재
- ❌ Three.js 통합: 미구현
- ❌ 3D 뷰어: 미구현
- ❌ 약점 분석 알고리즘: 미구현
- ❌ 성능 대시보드: 미구현

---

## 그룹 5: 보안 & 결제 (Security & Payment) 🔒💳
**테스트 수**: ~72개
**우선순위**: P2

### 포함 파일:
- `bmad-security.spec.ts` (251-280) - 30개
- `bmad-payment.spec.ts` - ~30개
- `payment/payment-flow.spec.ts` (PAY-001 ~ PAY-012) - 12개

### 테스트 범위:

#### 보안 (251-280):
- Rate limiting (요청 제한)
- API 인증 (JWT, OAuth)
- 권한 관리 (RBAC)
- CORS 설정
- 보안 헤더 (CSP, HSTS)
- 입력 검증 (서버사이드)
- 파일 업로드 보안
- 세션 보안

#### 결제 (PAY-*):
- Stripe/Paypal 통합
- 구독 관리 (월간/연간)
- 결제 이력
- 영수증 발급
- 환불 처리
- 결제 보안 (PCI DSS)

### 현재 상태:
- ✅ 기본 입력 검증: 구현됨
- ✅ Payment 모델: 존재
- ❌ Rate limiting: 미구현
- ❌ API 인증: 기본만
- ❌ Stripe 통합: 미구현
- ❌ 결제 페이지: 미구현

---

## 그룹 6: 통합 테스트 & 기타 (Integration & Others) 🔗
**테스트 수**: ~66개
**우선순위**: P3

### 포함 파일:
- `bmad-integration.spec.ts` (~30개)
- `bmad-full-test.spec.ts` (~20개)
- `bmad-simple-test.spec.ts` (~10개)
- `parallel/03-dashboard-view.spec.ts` (~3개)
- `sequential/critical-user-journey.spec.ts` (~3개)

### 테스트 범위:
- End-to-End 사용자 여정
- 크로스 기능 통합
- 추천 시스템
- 협업 기능
- 알림 시스템
- 대시보드 통합
- 검색 기능
- 데이터 내보내기/가져오기

### 현재 상태:
- ❌ 대부분 미구현
- ❌ 추천 시스템: 미구현
- ❌ 협업 기능: 미구현
- ❌ 알림: 미구현

---

## 그룹별 실행 순서 & 전략

### 1단계: 인증 시스템 (그룹 1) ⭐⭐⭐
**실행 시간**: ~15분
**이유**: 모든 기능의 기반, 최우선 수정 필요

```bash
# 그룹 1 실행
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-auth-comprehensive.spec.ts \
  tests/e2e/bmad-auth-social-password.spec.ts \
  tests/e2e/epic01-auth-registration.spec.ts \
  tests/e2e/parallel/01-user-registration.spec.ts \
  tests/e2e/parallel/02-login-flows.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group1-auth.txt
```

### 2단계: 학습자료 시스템 (그룹 2) ⭐⭐
**실행 시간**: ~12분
**이유**: 핵심 기능, 콘텐츠 생성의 시작점

```bash
# 그룹 2 실행
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-study-materials.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group2-study.txt
```

### 3단계: 모의고사 시스템 (그룹 3) ⭐⭐
**실행 시간**: ~25분
**이유**: 핵심 기능, 학습 경험의 중심

```bash
# 그룹 3 실행
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-mock-exam.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group3-exam.txt
```

### 4단계: 지식 그래프 & 성능 (그룹 4) ⭐
**실행 시간**: ~20분
**이유**: 차별화 기능, 시각화 중심

```bash
# 그룹 4 실행
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-knowledge-graph.spec.ts \
  tests/e2e/bmad-performance.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group4-graph-perf.txt
```

### 5단계: 보안 & 결제 (그룹 5)
**실행 시간**: ~22분
**이유**: 프로덕션 준비 필수 요소

```bash
# 그룹 5 실행
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-security.spec.ts \
  tests/e2e/bmad-payment.spec.ts \
  tests/e2e/payment/payment-flow.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group5-sec-pay.txt
```

### 6단계: 통합 테스트 (그룹 6)
**실행 시간**: ~20분
**이유**: 전체 플로우 검증

```bash
# 그룹 6 실행
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-integration.spec.ts \
  tests/e2e/bmad-full-test.spec.ts \
  tests/e2e/bmad-simple-test.spec.ts \
  tests/e2e/parallel/03-dashboard-view.spec.ts \
  tests/e2e/sequential/critical-user-journey.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group6-integration.txt
```

---

## 전체 6개 그룹 순차 실행

```bash
#!/bin/bash
# 6개 그룹 순차 실행 스크립트

echo "======================================"
echo "6개 그룹 테스트 시작"
echo "======================================"

# 그룹 1: 인증
echo "[1/6] 인증 시스템 테스트..."
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-auth-comprehensive.spec.ts \
  tests/e2e/bmad-auth-social-password.spec.ts \
  tests/e2e/epic01-auth-registration.spec.ts \
  tests/e2e/parallel/01-user-registration.spec.ts \
  tests/e2e/parallel/02-login-flows.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group1-auth.txt
grep "passed" /tmp/group1-auth.txt | tail -1

# 그룹 2: 학습자료
echo "[2/6] 학습자료 시스템 테스트..."
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-study-materials.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group2-study.txt
grep "passed" /tmp/group2-study.txt | tail -1

# 그룹 3: 모의고사
echo "[3/6] 모의고사 시스템 테스트..."
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-mock-exam.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group3-exam.txt
grep "passed" /tmp/group3-exam.txt | tail -1

# 그룹 4: 지식그래프 & 성능
echo "[4/6] 지식 그래프 & 성능 테스트..."
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-knowledge-graph.spec.ts \
  tests/e2e/bmad-performance.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group4-graph-perf.txt
grep "passed" /tmp/group4-graph-perf.txt | tail -1

# 그룹 5: 보안 & 결제
echo "[5/6] 보안 & 결제 테스트..."
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-security.spec.ts \
  tests/e2e/bmad-payment.spec.ts \
  tests/e2e/payment/payment-flow.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group5-sec-pay.txt
grep "passed" /tmp/group5-sec-pay.txt | tail -1

# 그룹 6: 통합
echo "[6/6] 통합 테스트..."
export SKIP_SERVER=1 && npx playwright test \
  tests/e2e/bmad-integration.spec.ts \
  tests/e2e/bmad-full-test.spec.ts \
  tests/e2e/bmad-simple-test.spec.ts \
  tests/e2e/parallel/03-dashboard-view.spec.ts \
  tests/e2e/sequential/critical-user-journey.spec.ts \
  --reporter=list --max-failures=0 2>&1 | tee /tmp/group6-integration.txt
grep "passed" /tmp/group6-integration.txt | tail -1

echo "======================================"
echo "전체 그룹 테스트 완료"
echo "======================================"
echo "결과 파일:"
echo "  - /tmp/group1-auth.txt"
echo "  - /tmp/group2-study.txt"
echo "  - /tmp/group3-exam.txt"
echo "  - /tmp/group4-graph-perf.txt"
echo "  - /tmp/group5-sec-pay.txt"
echo "  - /tmp/group6-integration.txt"
```

---

## 예상 통과율 (현재 기준)

```
그룹 1 (인증):           20-30%  ██░░░░░░░░  기본 기능만 동작
그룹 2 (학습자료):        0-5%   ░░░░░░░░░░  대부분 미구현
그룹 3 (모의고사):        0%     ░░░░░░░░░░  전체 미구현
그룹 4 (지식/성능):       0-5%   ░░░░░░░░░░  모델만 존재
그룹 5 (보안/결제):       5-10%  █░░░░░░░░░  일부 보안만
그룹 6 (통합):            0-3%   ░░░░░░░░░░  통합 미완성
────────────────────────────────────────────
전체 평균:                5-10%
```

---

## 다음 작업 우선순위

### 즉시 수정 (P0)
1. 인증 로그인 성공 케이스 (테스트 016)
2. 비밀번호 복잡도 selector 수정 (테스트 004)
3. 에러 메시지 한글화 (테스트 005-008)

### 단기 구현 (P1)
4. 모의고사 시스템 전체
5. 학습자료 업로드 시스템
6. 이메일 발송 기능

### 중기 구현 (P2)
7. 지식 그래프 3D 시각화
8. 2FA UI 구현
9. 성능 대시보드

### 장기 구현 (P3)
10. 결제 시스템 통합
11. 추천 시스템
12. 협업 기능
