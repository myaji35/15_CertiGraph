# 테스트 설계 문서: v1.1 업데이트 (결제, 시험일 추천, 오답노트)

작성일: 2024-01-04
설계자: AI Agent (Test Architect Persona)
문서 버전: 1.0
관련 Epic: Epic 5 (Payment), Epic 2 (Study Set), Epic 3 (Test Engine)

## 1. 개요 및 범위

본 문서는 v1.1 업데이트에 포함된 다음 핵심 기능에 대한 테스트 설계를 다룹니다.

1.  **결제 시스템 (Epic 5)**: Toss Payments 연동, 결제 모델/리포지토리, 결제 완료 후 상태 업데이트.
2.  **시험일 자동 추천 (Epic 2)**: 자격증 선택 시 가장 가까운 필기 시험일 및 D-Day 추천 로직.
3.  **오답 노트 모드 (Epic 3)**: 과거 틀린 문제만 필터링하여 재시험(Retest) 응시.

## 2. 리스크 평가 (Risk Assessment)

| 리스크 ID | 리스크 영역 | 설명 | 영향도 | 완화 전략 |
|---|---|---|---|---|
| **RISK-PAY-001** | 결제 보안 | 결제 금액 위변조 또는 상태 조작 가능성 | Critical | 결제 승인 API 호출 시 서버 측에서 금액 및 Order ID 재검증 필수 (Toss 권장사항 준수) |
| **RISK-PAY-002** | 데이터 불일치 | PG사 승인은 성공했으나 DB 업데이트 실패 (네트워크 이슈 등) | High | 웹훅(Webhook) 구현 (추후) 또는 클라이언트 실패 시 재시도 로직, 트랜잭션 로그 기록 |
| **RISK-EXAM-001** | 추천 로직 오류 | 과거 날짜나 잘못된 시험 회차 추천 | Medium | `get_upcoming_exams` 로직에서 `today` 기준 필터링 및 정렬 엄격 검증 테스트 |
| **RISK-TEST-001** | 오답 필터링 | 틀린 문제가 없는데 오답 모드 진입 시 빈 화면 노출 | Low | 오답 문제 0개일 때 적절한 에러 메시지 반환 또는 모드 진입 차단 UX |

## 3. 테스트 시나리오 상세

### 3.1 Backend 단위 테스트 (Unit Test)

#### Epic 5: Payment System
| ID | 우선순위 | 테스트 항목 | 설명 | 예상 결과 |
|---|---|---|---|---|
| **BE-UNIT-PAY-001** | P0 | `PaymentService.create_payment` | 결제 요청 객체 생성 및 orderId 형식 검증 | 유효한 payment_key 및 order_id 반환 |
| **BE-UNIT-PAY-002** | P0 | `PaymentRepository.update_user_payment_status` | DB 업데이트 쿼리 생성 및 실행 | `is_paid=True`로 상태 변경 확인 |
| **BE-UNIT-PAY-003** | P1 | `PaymentService.confirm_payment` (Mock) | PG 승인 API 모의 호출 및 성공 처리 | 성공 응답 및 DB 업데이트 호출 확인 |

#### Epic 2: Exam Date Recommendation
| ID | 우선순위 | 테스트 항목 | 설명 | 예상 결과 |
|---|---|---|---|---|
| **BE-UNIT-CERT-001** | P1 | `get_nearest_exam_date` - 다가오는 시험 있음 | 가장 가까운 `ExamType.WRITTEN` 일정 필터링 | 가장 빠른 미래 날짜의 시험 정보 반환 |
| **BE-UNIT-CERT-002** | P2 | `get_nearest_exam_date` - 시험 없음 | 향후 365일 내 시험 없을 경우 처리 | `null` 반환 또는 적절한 메시지 확인 |

#### Epic 3: Retest Mode (Wrong Answers)
| ID | 우선순위 | 테스트 항목 | 설명 | 예상 결과 |
|---|---|---|---|---|
| **BE-UNIT-TEST-001** | P0 | `TestSessionRepository.get_wrong_question_ids` | 사용자의 과거 오답 ID 추출 로직 | 최근 시도 기준 틀린 문제 ID 목록 반환 |
| **BE-UNIT-TEST-002** | P1 | `TestSessionService.start_session` (Wrong Mode) | `WRONG_ONLY` 모드로 세션 생성 시 문제 주입 | 오답 ID들에 해당하는 문제들로만 세션 구성 |

### 3.2 통합 테스트 (Integration Test)

| ID | 우선순위 | API 경로 | 설명 | 검증 포인트 |
|---|---|---|---|---|
| **INT-PAY-001** | P0 | `POST /api/v1/payment/create` | 결제 생성 API 연동 | Toss Client Key 포함된 응답 확인 |
| **INT-PAY-002** | P0 | `POST /api/v1/payment/confirm` | 결제 승인 API 및 DB 업데이트 연동 | 실제/Mock PG 승인 후 유저 권한(`is_paid`) 변경 확인 |
| **INT-CERT-001** | P1 | `GET /api/v1/certifications/{id}/nearest` | 시험일 추천 API 연동 | 실제 데이터(또는 Seed 데이터) 기반 올바른 D-Day 계산 확인 |
| **INT-TEST-001** | P0 | `POST /api/v1/tests/start` (Retest) | 오답 노트 기반 시험 시작 | 이전 세션에서 틀린 문제만 포함된 새 세션 생성 확인 |

### 3.3 E2E 테스트 (User Journey)

| ID | 우선순위 | 시나리오 명 | 설명 |
|---|---|---|---|
| **E2E-PAY-001** | P0 | **시즌패스 결제 및 문제집 생성** | 1. 이용권 페이지 이동 <br> 2. 결제 버튼 클릭 (Toss Mock) <br> 3. 결제 성공 후 리다이렉트 <br> 4. '새 문제집 만들기' 진입 시 이용권 정보 자동 로드 확인 |
| **E2E-TEST-001** | P1 | **오답 노트 학습 흐름** | 1. 문제 풀이 후 일부 오답 제출 <br> 2. 대시보드/결과 페이지에서 '오답 다시 풀기' 선택 <br> 3. 오답으로만 구성된 시험 로드 확인 <br> 4. 재시험 완료 |

## 4. 테스트 데이터 요구사항 (Fixtures)

*   **Mock User**: `is_paid=False` 상태의 초기 유저.
*   **Certification Data**: 2025년/2026년 시험 일정이 포함된 `json` 데이터.
*   **Test History**: 다양한 오답/정답 패턴이 포함된 과거 테스트 세션 데이터 (`user_answers`).

## 5. 실행 계획

1.  **BE Unit Test**: `pytest`를 사용하여 모델 및 서비스 로직 우선 검증.
2.  **Mocking**: Toss Payments API 호출은 외부 의존성이므로 `unittest.mock` 또는 `respx`로 모킹.
3.  **Manual Verification**: 로컬 서버(`localhost:3000`, `8000`) 구동 후 E2E 시나리오 수동 점검 (Toss Test Key 사용).
