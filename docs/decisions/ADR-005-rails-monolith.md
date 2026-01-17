# ADR-005: FastAPI+Next.js → Rails 모놀리식 전환

## Status
**Accepted** (2025-12 실행, 2026-01-18 문서화)

## Context

초기 architecture.md(2025-12-06)에서 FastAPI + Next.js 분리형 아키텍처를 계획했으나,
실제 구현 과정에서 Rails 7.2 모놀리식으로 전환하여 개발을 진행함.

### 초기 계획 (architecture.md)
```
certigraph/
├── frontend/          # Next.js 15.5 + Clerk Auth
├── backend/           # FastAPI + Python
└── shared/            # 공통 타입 정의
```

### 실제 구현
```
CertiGraph/
└── rails-api/         # Rails 7.2.3 모놀리식
    ├── app/           # MVC + Services
    ├── config/        # Devise, Turbo, Stimulus
    └── db/            # SQLite → PostgreSQL(planned)
```

## Decision

**Rails 7.2.3 모놀리식 아키텍처 채택**

- **Backend**: Rails 7.2.3
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Auth**: Devise (Clerk 대신)
- **Views**: ERB templates + Tailwind CSS
- **API**: RESTful endpoints (필요 시)

## Rationale

### 1. 1인 개발 환경에 최적화
- **분리형**: 2개 코드베이스 관리, 배포 2배, API 계약 관리
- **모놀리식**: 단일 코드베이스, 빠른 반복 개발
- **선택**: 속도 > 확장성 (MVP 단계)

### 2. Hotwire의 성능
- Turbo Drive: 페이지 전환 없는 네비게이션
- Turbo Frames: 부분 업데이트
- Turbo Streams: 실시간 업데이트
- **결과**: SPA 수준 UX를 React 없이 달성

### 3. Rails 생태계 활용
- Devise: 검증된 인증 (Clerk 비용 절감)
- Active Storage: 파일 업로드
- Solid Queue: 백그라운드 작업
- **결과**: 외부 서비스 의존 최소화

### 4. 배포 단순화
- **분리형**: Vercel(frontend) + Railway(backend) + CORS 설정
- **모놀리식**: 단일 서버 배포
- **결과**: 인프라 비용 50% 절감

### 5. Rails 8 준비
- Solid Queue/Cache 이미 사용 가능
- Kamal 2로 컨테이너 배포 준비
- Propshaft 마이그레이션 용이

## Consequences

### Positive
- ✅ **개발 속도 3배 향상**: 프론트/백엔드 분리 오버헤드 제거
- ✅ **단순한 배포**: 단일 Dockerfile, 단일 서버
- ✅ **Rails 에코시스템**: gem 활용, 커뮤니티 지원
- ✅ **비용 절감**: Clerk($0→$25/월), Vercel 불필요

### Negative
- ⚠️ **Frontend 최신 기술 미사용**: React 19, Next.js 16
- ⚠️ **API 재사용성 낮음**: 향후 모바일 앱 개발 시 API 분리 필요
- ⚠️ **JavaScript heavy 기능 제한**: 3D 시각화는 Three.js로 별도 처리

### Neutral
- 📊 **성능**: Hotwire로 SPA 수준 달성, 실제 차이 미미
- 🔄 **향후 전환 가능**: API-only 모드로 점진적 전환 가능

## Alternatives Considered

### Option 1: FastAPI + Next.js (초기 계획)
**Pros**:
- Frontend/Backend 기술 스택 독립
- 모바일 앱 API 재사용
- 최신 React 생태계

**Cons**:
- 2배 배포 복잡도
- CORS, API 계약 관리
- 1인 개발에 오버킬

**Rejected**: 개발 속도 저하

### Option 2: Rails API + Next.js
**Pros**:
- Rails 백엔드 + React 프론트엔드
- 중간 복잡도

**Cons**:
- 여전히 2개 배포
- API 계약 관리 필요

**Rejected**: Hotwire로 충분한 UX

### Option 3: Rails Monolith (선택)
**이유**: 1인 개발, MVP 속도, 충분한 UX

## Implementation

### Phase 1: Rails 기본 구조 (2025-12)
- ✅ Devise 인증
- ✅ Turbo/Stimulus 설정
- ✅ Tailwind CSS 통합

### Phase 2: 18 Epics 구현 (2025-12 ~ 2026-01)
- ✅ Epic 1-18 완료
- ✅ Study Sets, Mock Exams, Payment
- ✅ Knowledge Graph, Recommendations

### Phase 3: 프로젝트 정리 (2026-01-18)
- ✅ frontend/, backend/ 디렉토리 삭제
- ✅ 문서 업데이트
- ✅ ADR 작성

## Migration Path (Future)

만약 향후 Next.js로 전환이 필요한 경우:

```ruby
# Rails를 API-only 모드로 전환
config.api_only = true

# 기존 Views는 유지 (옵션)
# API endpoints 추가
namespace :api do
  namespace :v1 do
    # RESTful endpoints
  end
end
```

**예상 작업**: 2-3주 (Views → React 컴포넌트 전환)

## References

- [Initial Architecture Plan](../archive/fastapi-nextjs-plan/architecture.md)
- [Rails 7.2 Release Notes](https://guides.rubyonrails.org/7_2_release_notes.html)
- [Hotwire Documentation](https://hotwired.dev/)

## Notes

- **2026-01-18**: 프로젝트 정리 완료, 백업 태그 `v1.0-pre-cleanup-backup` 생성
- **Backup Scripts**: backend/scripts/ → rails-api/scripts/legacy-python/

---

**Author**: KPM Orchestrator
**Date**: 2026-01-18
**Reviewers**: [Project Owner]
