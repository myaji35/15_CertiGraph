---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - /home/15_CertiGraph/prd.md
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '2025-12-06'
updatedAt: '2026-01-08'
project_name: 'Certi-Graph'
user_name: 'Q123'
date: '2026-01-08'
version: 'v2.0 - Implementation Aligned'
---

# Architecture Decision Document (v2.0)

_Version 2.0: 실제 구현과 정렬된 아키텍처 문서 - 2026년 1월 8일 업데이트_

---

## 변경 이력

### v2.0 (2026-01-08)
- GCP Cloud SQL을 메인 데이터베이스로 변경
- VIP 패스 기능 추가
- 단계적 구현 전략 채택 (MVP → Phase 2)
- API 경로 구조 수정

### v1.0 (2025-12-06)
- 초기 아키텍처 설계

---

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
- FR-1: PDF 업로드 및 OCR 파싱 (Upstage API)
- FR-2: 지능형 청킹 (지문 복제 전략 포함)
- FR-3: Knowledge Graph 구축 (Phase 2로 연기)
- FR-4: CBT 테스트 엔진 (보기 랜덤 셔플링)
- FR-5: GraphRAG 기반 오답 분석 (Phase 2로 연기)
- FR-6: 사용자 인증 (Clerk)
- **FR-7: VIP 패스 시스템** (신규 추가)

**Non-Functional Requirements:**
- 성능: PDF 50p 파싱 3분 이내, 문제 로딩 1초 이내, LCP 2.5초
- 보안: HTTPS, 환경변수 API 키 관리, 최소 개인정보 수집
- 확장성: MVP 100명 동시접속, 1,000명 총 사용자
- 접근성: WCAG AA, 반응형 디자인
- 비용: 인프라 월 30만원, LLM API 월 50만원 제한

**Scale & Complexity:**
- Primary domain: Full-stack (Next.js + FastAPI + GCP Cloud SQL)
- Complexity level: Medium
- Estimated architectural components: 6-8개 (단계적 확장)

### Technical Constraints & Dependencies

| 구분 | 제약/의존성 | 변경사항 |
|------|------------|---------|
| 외부 API | Upstage Document Parse, OpenAI GPT-4o/4o-mini, text-embedding-3-small | 변경 없음 |
| 인프라 | Vercel (Frontend), Clerk (Auth), **GCP Cloud SQL** (Primary DB) | Supabase → GCP 변경 |
| 개발 | 1인 풀스택, 2025년 1월 시험 전 MVP 출시 필수 | 변경 없음 |
| 비용 | GCP 크레딧 활용, Free Tier 적극 활용 | GCP 중심 전략 |

### Cross-Cutting Concerns Identified

1. **인증/인가**: Clerk → 모든 API 엔드포인트 보호 (Next.js 미들웨어 + Backend JWT 검증)
2. **VIP 사용자 관리**: 특별 권한 사용자 하드코딩 지원
3. **LLM 비용 관리**: 캐싱 레이어, 사용량 상한, GPT-4o-mini 우선
4. **에러 처리**: PDF 파싱 실패 시 사용자 알림, 재시도 로직
5. **모니터링**: API 비용 추적, 사용자 행동 분석
6. **데이터 일관성**: 단일 PostgreSQL DB로 단순화

---

## Core Architectural Decisions (v2.0)

### Decision Priority Analysis

**Critical Decisions (Implementation Blocking):**
- **단일 DB 아키텍처 (GCP Cloud SQL PostgreSQL)**
- Clerk 기반 인증 흐름 + VIP 패스 시스템
- REST API 설계 (FastAPI OpenAPI)
- 비동기 처리 패턴 (PDF 파싱, LLM 호출)

**Important Decisions (Shape Architecture):**
- 프론트엔드 상태 관리 (Zustand + React Query)
- UI 컴포넌트 라이브러리 (shadcn/ui)
- 배포 인프라 (Vercel + GCP Cloud Run)

**Deferred Decisions (Phase 2):**
- Pinecone 벡터 DB 통합
- Neo4j 지식 그래프
- GraphRAG 분석 엔진
- Redis 캐싱 레이어

### Data Architecture (v2.0)

| 결정 | 선택 | 버전 | 근거 |
|------|------|------|------|
| **메인 DB** | GCP Cloud SQL (PostgreSQL) | 14.x | GCP 크레딧, 관리 용이성 |
| **벡터 DB** | 연기 (Phase 2: Pinecone) | - | MVP 단순화 |
| **그래프 DB** | 연기 (Phase 2: Neo4j) | - | MVP 단순화 |
| **ORM/Client** | asyncpg + SQLAlchemy | 2.0 | 비동기 지원, 타입 안전성 |
| **캐싱** | 없음 (MVP) | - | Phase 2에서 Redis 고려 |
| **마이그레이션** | Alembic | 최신 | 버전 관리, 롤백 지원 |

**현재 DB 스키마 (GCP Cloud SQL):**
```sql
-- 사용자 관리
users (
    id SERIAL PRIMARY KEY,
    clerk_user_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    is_vip BOOLEAN DEFAULT FALSE,  -- VIP 패스 플래그
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 구독/결제 관리
subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    certification_id VARCHAR(50),
    certification_name VARCHAR(255),
    exam_date DATE,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 학습 세트
study_sets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    certification_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 학습 자료 (PDF)
study_materials (
    id SERIAL PRIMARY KEY,
    study_set_id INTEGER REFERENCES study_sets(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    pdf_url TEXT,
    pdf_hash VARCHAR(64),
    file_size_bytes INTEGER,
    status VARCHAR(50) DEFAULT 'pending',  -- pending, processing, completed, failed
    processing_progress INTEGER DEFAULT 0,
    total_questions INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 문제 (Phase 2에서 벡터 임베딩 추가 예정)
questions (
    id SERIAL PRIMARY KEY,
    material_id INTEGER REFERENCES study_materials(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,  -- {A: "...", B: "...", C: "...", D: "..."}
    correct_answer VARCHAR(1),
    explanation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 테스트 세션
test_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    study_set_id INTEGER REFERENCES study_sets(id),
    score INTEGER,
    total_questions INTEGER,
    status VARCHAR(50) DEFAULT 'in_progress',  -- in_progress, completed, abandoned
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- 사용자 답안
user_answers (
    id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES test_sessions(id) ON DELETE CASCADE,
    question_id INTEGER REFERENCES questions(id),
    selected_option VARCHAR(1),
    is_correct BOOLEAN,
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Phase 2 확장 계획:**
```
Pinecone:
└── questions_vectors (임베딩 + 메타데이터)

Neo4j:
├── (:Concept) - 개념 노드
├── (:Question) - 문제 노드
└── 관계: TESTS, PREREQUISITE, WEAK_AT
```

### Authentication & Security (v2.0)

| 결정 | 선택 | 근거 |
|------|------|------|
| **인증 제공자** | Clerk | 내장 UI 컴포넌트, 10,000 MAU 무료 |
| **세션 관리** | Clerk JWT | 자동 갱신, 안전한 기본값 |
| **VIP 패스** | Clerk ID 하드코딩 | 특별 사용자 즉시 식별 |
| **프론트엔드 보호** | Clerk Middleware | Next.js 미들웨어로 라우트 보호 |
| **API 보호** | FastAPI + Clerk JWT 검증 | python-jose로 JWT 검증 |
| **CORS** | localhost:3030 허용 | 개발 환경 설정 |

**VIP 패스 시스템:**
```python
# backend/app/api/v1/endpoints/subscriptions.py
VIP_CLERK_IDS = [
    "user_36T9Qa8HsuaM1fMjTisw4frRH1Z"  # myaji35@gmail.com
]

# VIP 사용자 특별 권한:
# - 모든 자격증 무제한 접근
# - 결제 없이 모든 기능 사용
# - 특별 UI (보라색 그라데이션, 왕관 아이콘)
```

### API & Communication Patterns (v2.0)

| 결정 | 선택 | 근거 |
|------|------|------|
| **API 스타일** | REST (OpenAPI 3.0) | FastAPI 기본 지원 |
| **API 접두사** | /v1/ (api 없음) | 구현 단순화 |
| **문서화** | FastAPI 자동 생성 (/docs) | 추가 작업 불필요 |
| **에러 처리** | HTTPException + 커스텀 에러 코드 | 일관된 응답 |
| **비동기** | async/await 전면 사용 | 성능 최적화 |

**API 엔드포인트 구조 (v2.0):**
```
/v1/
├── /users/             # 사용자 프로필
├── /subscriptions/     # 구독 관리 (VIP 포함)
│   └── /my-subscriptions
├── /study-sets/        # 학습 세트 CRUD
│   └── /{id}
├── /study-materials/   # PDF 관리
│   ├── /{study_set_id}/upload
│   └── /{material_id}
├── /questions/         # 문제 조회
├── /tests/            # 모의고사
└── /dashboard/        # 대시보드 데이터
```

### Frontend Architecture (v2.0)

| 결정 | 선택 | 근거 |
|------|------|------|
| **프레임워크** | Next.js 14+ (App Router) | 서버 컴포넌트, 최신 기능 |
| **상태 관리** | Zustand | 가볍고 직관적 |
| **서버 상태** | TanStack Query | 캐싱, 자동 갱신 |
| **스타일링** | Tailwind CSS + shadcn/ui | 일관성, 커스터마이징 |
| **폼 처리** | React Hook Form + Zod | 타입 안전 검증 |

**VIP UI 컴포넌트:**
```tsx
// VIP 사용자 전용 UI
<div className="bg-gradient-to-r from-purple-50 to-pink-50
                dark:from-purple-900/20 dark:to-pink-900/20">
  <h3>👑 VIP 무료 이용권</h3>
  {/* 모든 자격증 선택 가능 */}
</div>
```

### Infrastructure & Deployment (v2.0)

| 결정 | 선택 | 비용 |
|------|------|------|
| **Frontend** | Vercel | Free Hobby |
| **Backend** | GCP Cloud Run | Pay-per-use |
| **Database** | GCP Cloud SQL | ~$30/월 |
| **Storage** | GCP Cloud Storage | Pay-per-use |
| **CI/CD** | GitHub Actions | Free |
| **모니터링** | GCP Cloud Monitoring | 기본 무료 |

**GCP 중심 아키텍처:**
```
Frontend (Vercel)
    ↓ HTTPS
Backend (Cloud Run)
    ↓ Private IP
Cloud SQL (PostgreSQL)
    ↓
Cloud Storage (PDFs)
```

### Development Environment (v2.0)

**환경 변수 설정:**
```bash
# Backend (.env)
# 개발 모드
DEV_MODE=false
TEST_MODE=false

# GCP Cloud SQL
USE_CLOUD_SQL=true
CLOUD_SQL_HOST=localhost
CLOUD_SQL_PORT=5433  # Cloud SQL Proxy
CLOUD_SQL_DATABASE=certigraph
CLOUD_SQL_USER=certigraph_user
CLOUD_SQL_PASSWORD=encrypted_password
CLOUD_SQL_CONNECTION_NAME=project:region:instance

# GCP 설정
GCP_PROJECT_ID=postgresql-479201
GCP_REGION=asia-northeast3
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json

# Clerk 인증
CLERK_JWKS_URL=https://domain/.well-known/jwks.json
CLERK_SECRET_KEY=sk_test_xxx

# AI APIs (Phase 2)
ANTHROPIC_API_KEY=sk-ant-xxx
OPENAI_API_KEY=sk-xxx
UPSTAGE_API_KEY=up_xxx

# Frontend (.env.local)
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx
```

### Implementation Patterns & Consistency Rules (v2.0)

**파일 구조 (현재 구현):**
```
backend/
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/
│   │       │   ├── subscriptions.py  # VIP 로직 포함
│   │       │   ├── study_sets.py
│   │       │   ├── study_materials.py
│   │       │   └── questions.py
│   │       ├── deps.py
│   │       └── router.py
│   ├── core/
│   │   ├── config.py  # GCP 설정
│   │   └── security.py
│   ├── models/
│   ├── repositories/
│   │   └── mock_*.py  # 임시 mock 구현
│   └── main.py

frontend/
├── src/
│   ├── app/
│   │   ├── (dashboard)/
│   │   │   ├── study-sets/
│   │   │   │   ├── page.tsx
│   │   │   │   └── new/
│   │   │   │       └── page.tsx  # VIP UI 포함
│   │   │   └── test/
│   │   └── dashboard/
│   │       └── study-sets/
│   │           └── [id]/
│   │               └── page.tsx
│   └── components/
```

---

## Implementation Roadmap (v2.0)

### MVP (현재 - 2025년 1월)
✅ 완료:
- Clerk 인증 시스템
- VIP 패스 기능
- 학습 세트 생성/관리
- PDF 업로드 인터페이스
- GCP Cloud SQL 연동

🚧 진행 중:
- PDF 처리 파이프라인 (Upstage OCR)
- 질문 추출 엔진
- CBT 테스트 인터페이스

### Phase 2 (2025년 2월-3월)
- Pinecone 벡터 DB 통합
- Neo4j 지식 그래프 구축
- GraphRAG 분석 엔진
- 고급 대시보드
- 결제 시스템 (VIP 외 사용자)

### Phase 3 (2025년 4월-)
- 모바일 앱
- 다중 자격증 지원
- AI 튜터 기능

---

## Architecture Validation Results (v2.0)

### Coherence Validation ✅
- GCP 중심 아키텍처로 통일
- VIP 패스 시스템 통합
- 단계적 구현 전략 명확

### Requirements Coverage ✅
- MVP 핵심 기능 구현 가능
- 고급 기능은 Phase 2로 연기
- VIP 사용자 즉시 지원

### Implementation Readiness ✅
- 현재 구현과 100% 정렬
- 명확한 로드맵
- 기술 부채 최소화

---

## Architecture Status

**Status:** ✅ IMPLEMENTATION ALIGNED
**Version:** 2.0
**Last Updated:** 2026-01-08
**Next Review:** Phase 2 시작 전

**Key Changes from v1.0:**
1. Supabase → GCP Cloud SQL 변경
2. 3-DB → 단일 DB (MVP)
3. VIP 패스 시스템 추가
4. API 경로 구조 수정 (/api/v1 → /v1)
5. Phase별 구현 전략 명확화

---

**Next Steps:**
1. PDF 처리 파이프라인 구현
2. 질문 추출 엔진 개발
3. CBT 테스트 엔진 완성
4. Phase 2 준비 (벡터 DB, 지식 그래프)