# Epic별 미구현 기능 상세 리포트
**CertiGraph (AI 자격증 마스터)**
**생성일**: 2026-01-16
**기준**: 테스트 커버리지 + 구현 상태 분석

---

## 📊 전체 현황 요약

| 지표 | 값 |
|------|-----|
| **총 Epic 수** | 18개 |
| **완료 (90%+)** | 5개 (27.8%) ⭐ |
| **진행중 (40-89%)** | 4개 (22.2%) 🚧 |
| **미구현 (<40%)** | 9개 (50%) 🔴 |
| **전체 테스트** | 337개 |
| **테스트 통과** | ~15-20개 (4-6%) |
| **테스트 실패** | ~317-322개 (94-96%) |

---

## 🎯 Epic별 미구현 기능 상세

### ✅ Epic 1: User Authentication (사용자 인증)
**구현률**: 70% → **80%** (이번 세션에서 개선)
**테스트**: 30개 중 4개 통과 (13.3%)

#### ✅ 구현 완료
- ✅ Devise database_authenticatable 활성화
- ✅ Email/Password 회원가입/로그인
- ✅ Sessions controller (2FA 지원)
- ✅ Registrations controller
- ✅ 비밀번호 재설정
- ✅ 세션 관리
- ✅ User 모델 (security fields, login tracking)

#### ❌ 미구현 기능
1. **Validation 에러 메시지 표시** 🔴 P1
   - 비밀번호 확인 불일치 메시지 미표시 (Test 005)
   - SQL Injection 차단 메시지 미표시 (Test 006)
   - XSS 스크립트 차단 메시지 미표시 (Test 007)
   - 이메일 형식 검증 메시지 미표시 (Test 008)
   - 서비스 약관 동의 필수 메시지 미표시 (Test 009)

2. **고급 인증 기능** 🔴 P2
   - Google OAuth 통합 (OAuth2 callback 존재하나 프론트 미연동)
   - Naver OAuth 통합 (provider 설정됨, 테스트 필요)
   - 2FA 검증 페이지 (백엔드 완료, 프론트 미구현)
   - Email 확인 (confirmable 활성화, 메일러 미테스트)

3. **계정 관리** 🔴 P1
   - Profile 페이지 (controller 존재, view 미구현)
   - Avatar 업로드 UI
   - 비밀번호 변경 페이지
   - 계정 탈퇴 기능

#### 관련 파일
- ✅ `app/models/user.rb`
- ✅ `app/controllers/users/sessions_controller.rb`
- ✅ `app/controllers/users/registrations_controller.rb`
- ✅ `app/controllers/users/omniauth_callbacks_controller.rb`
- ⚠️ `app/views/devise/sessions/new.html.erb` (메시지 표시 개선 필요)
- ⚠️ `app/views/devise/registrations/new.html.erb` (validation 메시지)

---

### 🚧 Epic 2: PDF Upload & Storage
**구현률**: 80%
**테스트**: 42개 중 0개 통과 (0%) - OAuth 인증 블로킹

#### ✅ 구현 완료
- ✅ Active Storage 설정
- ✅ StudyMaterial 모델
- ✅ 파일 업로드 API
- ✅ S3 설정 (환경변수 기반)
- ✅ 파일 메타데이터 저장

#### ❌ 미구현 기능
1. **파일 업로드 기능** 🔴 P0
   - PDF 업로드 UI (테스트 051-054 실패)
   - 대용량 파일 처리 (100MB+ 거부 로직)
   - Direct Upload (Active Storage Direct Upload)
   - Chunked Upload (대용량 파일용)
   - 업로드 진행률 표시

2. **파일 검증** 🔴 P0
   - 파일 타입 검증 강화 (현재 기본만)
   - 중복 파일 감지 및 처리
   - 암호화된 PDF 처리
   - 손상된 파일 감지

3. **파일 관리** 🔴 P1
   - 파일 목록 보기
   - 파일 삭제
   - 파일 다운로드
   - 파일 메타데이터 편집

#### 테스트 시나리오 (미통과)
- 051. PDF 업로드 - 정상 파일
- 052. PDF 업로드 - 대용량 파일 거부 (100MB 초과)
- 053. PDF 업로드 - 잘못된 파일 형식 거부
- 054. PDF 업로드 - 중복 파일 처리
- 055. PDF 업로드 - 암호화된 PDF 처리
- ... (37개 추가 시나리오)

#### 관련 파일
- ✅ `app/models/study_material.rb`
- ✅ `app/controllers/study_materials_controller.rb`
- ⚠️ `app/services/chunked_upload_service.rb` (생성됨, 미연동)
- ⚠️ `app/services/direct_upload_service.rb` (생성됨, 미연동)
- ⚠️ `app/views/study_materials/*` (UI 미구현)

---

### 🔴 Epic 3: PDF Processing (OCR)
**구현률**: 95%
**테스트**: 미구현 (Epic 3 전용 테스트 없음, Epic 2에 통합)

#### ✅ 구현 완료
- ✅ PdfProcessingService (Upstage OCR)
- ✅ ImageExtractionService
- ✅ ProcessPdfJob
- ✅ 마크다운 변환
- ✅ 이미지 캡셔닝 (GPT-4o)
- ✅ 에러 복구 (5회 재시도)

#### ❌ 미구현 기능
1. **성능 최적화** 🔴 P2
   - 100MB+ 대용량 파일 처리
   - 병렬 이미지 처리
   - 스트리밍 OCR

2. **진행 상황 UI** 🔴 P1
   - 실시간 진행률 표시
   - 처리 상태 폴링 API 연동
   - 에러 발생 시 사용자 알림

#### 관련 파일
- ✅ `app/services/pdf_processing_service.rb`
- ✅ `app/services/image_extraction_service.rb`
- ✅ `app/jobs/process_pdf_job.rb`

---

### 🔴 Epic 4: Question Extraction
**구현률**: 40%
**테스트**: 미구현

#### ✅ 구현 완료
- ✅ Question 모델
- ✅ Option 모델
- ✅ 기본 CRUD

#### ❌ 미구현 기능
1. **AI 문제 추출** 🔴 P0
   - GPT-4o 기반 문제 추출
   - 지문-문제 연결
   - 보기 파싱
   - 해설 추출
   - 난이도 판정

2. **질문 관리** 🔴 P1
   - 문제 편집 UI
   - 문제 검색
   - 문제 필터링
   - 문제 통계

#### 관련 파일
- ✅ `app/models/question.rb`
- ✅ `app/models/option.rb`
- ⚠️ `app/services/ai_question_extraction_service.rb` (생성됨, 미완성)

---

### 🔴 Epic 5: Content Structuring (콘텐츠 구조화)
**구현률**: 35%
**테스트**: 미구현

#### ✅ 구현 완료
- ✅ Tags 모델
- ✅ Taggings 모델 (polymorphic)
- ✅ 기본 태깅 시스템

#### ❌ 미구현 기능
1. **자동 분류** 🔴 P0
   - AI 기반 콘텐츠 분류
   - 자동 태깅
   - 메타데이터 추출

2. **콘텐츠 구조** 🔴 P1
   - Passages (지문) 구조화
   - Passages - Questions 연결
   - 계층 구조 UI

#### 관련 파일
- ✅ `app/models/tag.rb`
- ✅ `app/models/tagging.rb`
- ⚠️ `app/services/auto_tagging_service.rb` (생성됨, 미테스트)
- ⚠️ `app/models/passage.rb` (생성됨, 미연동)

---

### ⭐ Epic 6: Knowledge Graph Creation
**구현률**: 95%
**테스트**: 33개 중 0개 통과 (0%) - OAuth 블로킹

#### ✅ 구현 완료
- ✅ KnowledgeNode 모델
- ✅ KnowledgeEdge 모델
- ✅ KnowledgeGraphService
- ✅ 그래프 알고리즘 (BFS)
- ✅ JSON 내보내기

#### ❌ 미구현 기능
1. **UI 연동** 🔴 P0
   - Knowledge Graph 시각화 페이지
   - 그래프 탐색 인터페이스
   - 노드 상세 정보 표시

2. **고급 기능** 🔴 P2
   - Neo4j 마이그레이션 (현재 PostgreSQL JSON)
   - 실시간 업데이트
   - 협업 필터링

#### 테스트 시나리오 (미통과, 인증 블로킹)
- 모든 33개 테스트 OAuth 인증 실패로 미실행

#### 관련 파일
- ✅ `app/models/knowledge_node.rb`
- ✅ `app/models/knowledge_edge.rb`
- ✅ `app/services/knowledge_graph_service.rb`
- ✅ `app/controllers/knowledge_graph_controller.rb`
- ⚠️ View 없음

---

### 🔴 Epic 7: Concept Extraction (개념 추출)
**구현률**: 10%
**테스트**: 미구현

#### ✅ 구현 완료
- ✅ QuestionConcept 모델 (연결 테이블)
- ✅ ConceptSynonym 모델

#### ❌ 미구현 기능
1. **개념 추출** 🔴 P0
   - NLP 파이프라인
   - AI 개념 추출
   - 개념 정규화
   - 동의어/유의어 처리

2. **개념 관계** 🔴 P1
   - 개념 중요도 산정
   - 개념 클러스터링
   - 개념 추천

#### 관련 파일
- ✅ `app/models/question_concept.rb`
- ✅ `app/models/concept_synonym.rb`
- ⚠️ `app/services/concept_extraction_service.rb` (생성됨, 미완성)
- ⚠️ `app/services/concept_normalization_service.rb` (생성됨, 미완성)

---

### 🔴 Epic 8: Prerequisite Mapping (선수 지식 맵핑)
**구현률**: 5%
**테스트**: 미구현

#### ✅ 구현 완료
- ✅ KnowledgeEdge prerequisite 관계 정의

#### ❌ 미구현 기능
1. **선수 지식 분석** 🔴 P0
   - AI 선수 지식 분석
   - 학습 경로 생성
   - 난이도 측정
   - 의존성 그래프

2. **학습 추천** 🔴 P1
   - 최적 학습 순서
   - 개인화된 경로
   - 진도율 기반 추천

#### 관련 파일
- ⚠️ `app/services/prerequisite_analysis_service.rb` (생성됨, 미완성)

---

### 🚧 Epic 9: CBT Test Mode (컴퓨터 기반 시험)
**구현률**: 60%
**테스트**: ~62개 (Mock Exam 통합)

#### ✅ 구현 완료
- ✅ TestSession 모델
- ✅ ExamSession 모델
- ✅ 시험 세션 생성/관리
- ✅ 시간 제한 기능
- ✅ 답안 제출 처리

#### ❌ 미구현 기능
1. **CBT UI** 🔴 P0
   - 실제 CBT 인터페이스
   - 키보드 단축키
   - 문제 북마크
   - 시험 일시정지/재개
   - 문제 내비게이션

2. **시험 기능** 🔴 P1
   - 시험 결과 상세 분석
   - 오답 노트
   - 문제 리뷰
   - 채점 알고리즘

#### 관련 파일
- ✅ `app/models/test_session.rb`
- ✅ `app/models/exam_session.rb`
- ✅ `app/controllers/test_sessions_controller.rb`
- ⚠️ View 기본만 있음 (CBT UI 미구현)

---

### ⭐ Epic 10: Answer Randomization (답안 무작위화)
**구현률**: 70%
**테스트**: Epic 9와 통합

#### ✅ 구현 완료
- ✅ Fisher-Yates 알고리즘
- ✅ 보기 순서 무작위화
- ✅ 문제 순서 셔플
- ✅ RandomizationStat 모델

#### ❌ 미구현 기능
1. **통계 및 검증** 🔴 P2
   - 무작위화 품질 검증
   - 통계 대시보드
   - 패턴 감지

#### 관련 파일
- ✅ `app/services/answer_randomizer.rb`
- ✅ `app/services/randomization_analyzer.rb`
- ✅ `app/models/randomization_stat.rb`

---

### 🔴 Epic 11: Security (보안)
**구현률**: 30%
**테스트**: 미구현 (Security spec 존재)

#### ✅ 구현 완료
- ✅ 기본 CORS 설정
- ✅ Devise security (lockable, timeoutable)
- ✅ 2FA 모델 (otp_secret_key)

#### ❌ 미구현 기능
1. **2FA 구현** 🔴 P1
   - 2FA 활성화 UI
   - QR 코드 생성
   - Backup codes
   - 2FA 검증 페이지

2. **보안 강화** 🔴 P1
   - Rate limiting
   - IP 화이트리스트
   - API 키 관리
   - 감사 로그

#### 관련 파일
- ✅ `app/models/user.rb` (2FA fields 있음)
- ⚠️ `app/services/two_factor_service.rb` (생성됨, UI 미연동)
- ⚠️ `app/controllers/users/two_factor_controller.rb` (생성됨, 미테스트)

---

### ⭐ Epic 12: Weakness Analysis (약점 분석)
**구현률**: 90%
**테스트**: 미구현

#### ✅ 구현 완료
- ✅ ErrorAnalysisService
- ✅ WeaknessAnalysisController
- ✅ GraphRAG 통합
- ✅ 오류 분류 (실수 vs 개념 부족)
- ✅ 패턴 감지

#### ❌ 미구현 기능
1. **ML 기반 분석** 🔴 P2
   - ML 모델 학습
   - 패턴 예측
   - A/B 테스트 프레임워크

2. **UI 연동** 🔴 P1
   - 약점 대시보드
   - 시각화
   - 추천 학습 경로 표시

#### 관련 파일
- ✅ `app/services/error_analysis_service.rb`
- ✅ `app/services/advanced_weakness_analyzer.rb`
- ✅ `app/controllers/weakness_analysis_controller.rb`

---

### 🔴 Epic 13: Smart Recommendations (스마트 추천)
**구현률**: 40%
**테스트**: 미구현

#### ✅ 구현 완료
- ✅ RecommendationService
- ✅ 기본 추천 엔진

#### ❌ 미구현 기능
1. **추천 알고리즘** 🔴 P0
   - Collaborative filtering
   - Content-based filtering
   - Hybrid 추천
   - 개인화 추천

2. **추천 UI** 🔴 P1
   - 추천 대시보드
   - 추천 이유 설명
   - 추천 피드백

#### 관련 파일
- ✅ `app/services/recommendation_service.rb`
- ⚠️ `app/services/collaborative_filtering_service.rb` (생성됨, 미완성)
- ⚠️ `app/services/content_based_filtering_service.rb` (생성됨, 미완성)

---

### ⭐ Epic 14: 3D Knowledge Map
**구현률**: 90%
**테스트**: 미구현

#### ✅ 구현 완료
- ✅ Three.js 시스템
- ✅ 3D 그래프 생성
- ✅ 색상 코딩
- ✅ 인터랙티브 탐색

#### ❌ 미구현 기능
1. **성능 최적화** 🔴 P2
   - 1000+ 노드 최적화
   - LOD (Level of Detail)
   - WebGL 최적화

2. **고급 기능** 🔴 P3
   - VR/AR 지원
   - 멀티플레이어

#### 관련 파일
- ✅ `app/services/three_d_graph_service.rb`
- ✅ `app/controllers/knowledge_visualization_controller.rb`

---

### 🚧 Epic 15: Progress Dashboard (진도 대시보드)
**구현률**: 85%
**테스트**: 일부 통합 (Dashboard stats)

#### ✅ 구현 완료
- ✅ DashboardController
- ✅ ProgressAnalyticsService
- ✅ 학습 통계
- ✅ 성취도 차트

#### ❌ 미구현 기능
1. **차트 통합** 🔴 P1
   - Chart.js 완전 통합
   - 실시간 데이터 업데이트
   - 커스터마이징

2. **위젯 시스템** 🔴 P2
   - 커스텀 대시보드
   - 위젯 추가/제거
   - 레이아웃 저장

#### 관련 파일
- ✅ `app/controllers/dashboard_controller.rb`
- ✅ `app/services/progress_analytics_service.rb`
- ⚠️ `app/models/dashboard_widget.rb` (생성됨, 미연동)

---

### ⭐ Epic 16: Payment System (결제 시스템)
**구현률**: 95%
**테스트**: 36개 (Payment spec)

#### ✅ 구현 완료
- ✅ Payment 모델
- ✅ Subscription 모델
- ✅ StripeService
- ✅ Webhook 처리
- ✅ VIP 패스

#### ❌ 미구현 기능
1. **프로덕션 설정** 🔴 P1
   - Webhook 프로덕션 설정
   - 에러 처리 강화

2. **대안 결제** 🔴 P2
   - 토스페이먼츠 통합
   - 카카오페이
   - 네이버페이

#### 테스트 시나리오 (대부분 미통과)
- Payment checkout flow
- Subscription management
- Webhook processing

#### 관련 파일
- ✅ `app/models/payment.rb`
- ✅ `app/models/subscription.rb`
- ✅ `app/services/stripe_service.rb`
- ✅ `app/controllers/payments_controller.rb`

---

### 🔴 Epic 17: Marketplace (마켓플레이스)
**구현률**: 40%
**테스트**: 미구현

#### ✅ 구현 완료
- ✅ StudyMaterial marketplace fields
- ✅ Purchase 모델
- ✅ Review 모델

#### ❌ 미구현 기능
1. **마켓플레이스 UI** 🔴 P0
   - 콘텐츠 목록
   - 검색/필터
   - 상세 페이지
   - 구매 플로우

2. **리뷰 시스템** 🔴 P1
   - 리뷰 작성
   - 리뷰 투표
   - 리뷰 신고

#### 관련 파일
- ✅ `app/models/purchase.rb`
- ✅ `app/models/review.rb`
- ⚠️ `app/controllers/marketplace_controller.rb` (생성됨, 미완성)

---

### ⭐ Epic 18: Certification Information Hub (자격증 정보 허브)
**구현률**: 95%
**테스트**: 일부 API 테스트

#### ✅ 구현 완료
- ✅ Certification 모델 (5개 자격증)
- ✅ ExamSchedule 모델 (114개 일정)
- ✅ CertificationsController
- ✅ ExamSchedulesController
- ✅ 이메일 알림
- ✅ 시드 데이터

#### ❌ 미구현 기능
1. **라우팅 문제** 🔴 P1
   - `/certifications/upcoming` (404)
   - `/certifications/open_registrations` (404)
   - `/certifications/:id/years` (404)

2. **프론트엔드 UI** 🔴 P1
   - 자격증 목록 페이지
   - 시험 일정 캘린더
   - 알림 설정 UI

#### 관련 파일
- ✅ `app/models/certification.rb`
- ✅ `app/models/exam_schedule.rb`
- ✅ `app/controllers/certifications_controller.rb`
- ⚠️ View 없음

---

## 🎯 우선순위별 구현 권장사항

### 🚨 P0 (Critical) - 즉시 구현 필요

1. **Authentication Validation Messages** (Epic 1)
   - 파일: `app/views/devise/registrations/new.html.erb`
   - 작업: 5개 validation 메시지 표시 추가
   - 예상 시간: 1-2시간

2. **PDF Upload UI** (Epic 2)
   - 파일: Study Materials views
   - 작업: 파일 업로드 폼 + 진행률 표시
   - 예상 시간: 4-6시간

3. **CBT Test UI** (Epic 9)
   - 파일: Test Sessions views
   - 작업: CBT 인터페이스 구현
   - 예상 시간: 8-12시간

4. **Knowledge Graph Visualization** (Epic 6)
   - 파일: Knowledge Visualization views
   - 작업: Three.js 연동 + 인터페이스
   - 예상 시간: 6-8시간

### 🔥 P1 (High) - 단기 구현 필요

1. **Profile Management** (Epic 1)
   - 예상 시간: 4-6시간

2. **Question Extraction AI** (Epic 4)
   - 예상 시간: 8-10시간

3. **2FA UI** (Epic 11)
   - 예상 시간: 4-6시간

4. **Certification Routes Fix** (Epic 18)
   - 예상 시간: 1-2시간

### ⚠️ P2 (Medium) - 중기 구현 필요

1. **OAuth Integration** (Epic 1)
   - 예상 시간: 6-8시간

2. **Marketplace UI** (Epic 17)
   - 예상 시간: 12-16시간

3. **Performance Optimization** (Epic 3, 14)
   - 예상 시간: 8-12시간

### 🔵 P3 (Low) - 장기 개선 사항

1. **VR/AR Support** (Epic 14)
   - 예상 시간: 40+ 시간

2. **Alternative Payments** (Epic 16)
   - 예상 시간: 16-20시간

---

## 📈 테스트 커버리지 개선 로드맵

### Phase 1: 인증 문제 해결 (완료)
- ✅ Email/Password 인증 활성화
- ✅ Routes 수정
- ✅ Controllers 업데이트
- **결과**: 4/30 테스트 통과 (13.3%)

### Phase 2: Validation 메시지 개선 (1-2일)
- 목표: Epic 1 테스트 통과율 60%+
- 예상 테스트 통과: +8-10개

### Phase 3: UI 구현 (1주)
- PDF Upload UI
- CBT UI
- Knowledge Graph UI
- 목표: Epic 2, 9 테스트 통과율 40%+
- 예상 테스트 통과: +50-70개

### Phase 4: 기능 완성 (2-3주)
- AI 문제 추출
- 추천 시스템
- 약점 분석 UI
- 목표: 전체 통과율 60%+
- 예상 테스트 통과: +150-200개

---

## 📊 Epic별 완성도 차트

```
Epic 18: ████████████████████ 95%
Epic 16: ████████████████████ 95%
Epic  3: ████████████████████ 95%
Epic  6: ████████████████████ 95%
Epic 14: ███████████████████░ 90%
Epic 12: ███████████████████░ 90%
Epic 15: ██████████████████░░ 85%
Epic  1: ████████████████░░░░ 80%
Epic  2: ████████████████░░░░ 80%
Epic 10: ███████████████░░░░░ 70%
Epic  9: █████████████░░░░░░░ 60%
Epic 17: █████████░░░░░░░░░░░ 40%
Epic 13: █████████░░░░░░░░░░░ 40%
Epic  4: █████████░░░░░░░░░░░ 40%
Epic  5: ████████░░░░░░░░░░░░ 35%
Epic 11: ███████░░░░░░░░░░░░░ 30%
Epic  7: ███░░░░░░░░░░░░░░░░░ 10%
Epic  8: ██░░░░░░░░░░░░░░░░░░  5%
```

---

## 🔗 관련 문서

- `/docs/epic-completion-master-report.md` - 전체 Epic 완성도 리포트
- `/docs/epic-implementation-status.md` - 구현 상태 상세
- `/docs/tdd.md` - TDD 가이드
- `/docs/p0-fix-completion-report.md` - P0 수정 완료 리포트

---

**생성**: 2026-01-16 05:58 KST
**다음 액션**: P0 Validation 메시지 구현 → P0 PDF Upload UI → P0 CBT UI
