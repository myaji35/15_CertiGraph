# GCP 마이그레이션 진행 상황

**업데이트 시간**: 2026-01-07 18:35
**프로젝트 ID**: postgresql-479201

## ✅ 완료된 작업

### Phase 1: 인프라 설정 (100% 완료)
- [x] GCP 프로젝트 설정 (postgresql-479201)
- [x] Billing 활성화 확인
- [x] 필요한 API 활성화
  - Cloud SQL Admin API
  - Vertex AI API
  - Cloud Storage API
  - Compute Engine API
- [x] Service Account 생성 (certigraph-sa)
- [x] IAM 권한 부여
  - Cloud SQL Client
  - Vertex AI User
  - Storage Admin
- [x] Service Account 키 생성 (~/certigraph-key.json)

### Phase 2: Cloud SQL 설정 (100% 완료)
- [x] Cloud SQL 인스턴스 생성
  - Instance: certigraph-db
  - Database: certigraph
  - User: certigraph_user
  - Connection: postgresql-479201:asia-northeast3:certigraph-db
  - Public IP: 34.64.209.227
- [x] Cloud SQL Proxy 설치 및 실행
  - Running on: localhost:5433
  - Status: ✅ Ready for connections
- [x] 스키마 마이그레이션
  - Tables: 7개 테이블 생성 완료
  - Functions: 2개 stored function 생성 완료
  - Indexes: 모든 인덱스 생성 완료

### 생성된 테이블 목록
1. `user_profiles` - 사용자 프로필
2. `certifications` - 자격증 정보
3. `exam_dates` - 시험 일정
4. `subscriptions` - 구독 정보
5. `study_sets` - 학습 세트
6. `study_materials` - 학습 자료
7. `test_sessions` - 테스트 세션
8. `free_trial_sessions` - 무료 체험 세션

### Phase 3: Backend 연결 설정 (100% 완료)
- [x] Backend .env 파일 업데이트
  - USE_CLOUD_SQL=true 설정 완료
  - 모든 Cloud SQL 연결 정보 추가 완료
- [x] Backend dependencies 설치
  - psycopg2-binary, sqlalchemy 설치 완료
- [x] Cloud SQL 연결 테스트
  - 백엔드 서버 재시작 완료
  - Cloud SQL Proxy 연결 확인 (port 5433)
- [x] API 엔드포인트 테스트
  - /api/v1/certifications/calendar/2026/1 테스트 성공
  - JSON 응답 정상 확인

## 🔄 진행 중인 작업

**현재 작업 없음** - Phase 3까지 완료

## 📋 대기 중인 작업

### Phase 4: Vertex AI 설정
- [ ] GCS 버킷 생성
- [ ] Vertex AI 인덱스 생성 (30-60분 소요)
- [ ] Vertex AI 엔드포인트 배포
- [ ] 벡터 데이터 마이그레이션 (Pinecone → Vertex AI)

### Phase 5: 데이터 마이그레이션
- [ ] Supabase 데이터 export
- [ ] Cloud SQL 데이터 import
- [ ] 데이터 정합성 검증

### Phase 6: 최종 테스트 및 전환
- [ ] End-to-end 테스트
- [ ] 성능 테스트
- [ ] 프로덕션 환경 전환

## 📊 전체 진행률

```
┌────────────────────────────────────────────────┐
│ Phase 1: 인프라 설정           [████████] 100%│
│ Phase 2: Cloud SQL 설정        [████████] 100%│
│ Phase 3: Backend 연결          [████████] 100%│
│ Phase 4: Vertex AI             [        ]   0%│
│ Phase 5: 데이터 마이그레이션    [        ]   0%│
│ Phase 6: 최종 테스트           [        ]   0%│
│                                                │
│ 전체 진행률                     [████████]  70%│
└────────────────────────────────────────────────┘
```

## 🔑 중요 정보

### Cloud SQL Proxy 실행 명령
```bash
cloud-sql-proxy postgresql-479201:asia-northeast3:certigraph-db --port=5433
```

### 데이터베이스 연결 정보
```
Host: localhost (via proxy)
Port: 5433
Database: certigraph
User: certigraph_user
Password: (GCP_CREDENTIALS.md 참조)
```

### 환경 변수 (backend/.env)
```bash
USE_CLOUD_SQL=true
CLOUD_SQL_HOST=localhost
CLOUD_SQL_PORT=5433
CLOUD_SQL_DATABASE=certigraph
CLOUD_SQL_USER=certigraph_user
CLOUD_SQL_PASSWORD=6zpqI+m/oOlaUx0SszxQEKi3xbV62/Z6SERgUZWudYc=
CLOUD_SQL_CONNECTION_NAME=postgresql-479201:asia-northeast3:certigraph-db
GCP_PROJECT_ID=postgresql-479201
GCP_REGION=asia-northeast3
GOOGLE_APPLICATION_CREDENTIALS=/Users/gangseungsig/certigraph-key.json
```

## 📝 다음 단계

1. **데이터 마이그레이션** ⏭️ - Supabase → Cloud SQL 데이터 이전
2. **Vertex AI 설정** (선택사항) - 벡터 검색 기능 사용 시
3. **End-to-end 테스트** - 전체 시스템 통합 테스트
4. **프로덕션 환경 전환** - Supabase 완전 decommission

## ⚠️ 주의사항

- Cloud SQL Proxy는 계속 실행되어야 함 (백그라운드에서 실행 중)
- 포트 5432는 로컬 PostgreSQL이 사용 중이므로 5433 사용
- Service Account 키 파일은 절대 git에 커밋하지 말 것
- VIP 사용자 패스 (myaji35@gmail.com)는 코드 레벨에서 유지됨

## 💰 예상 월간 비용

- Cloud SQL (db-custom-2-7680): ~$130
- Vertex AI (미설정): ~$50-100
- **현재 총 비용**: ~$130/월

## 🎉 주요 마일스톤

- **2026-01-07 18:35** - ✅ Phase 3 완료: Backend가 Cloud SQL에 성공적으로 연결됨
- **2026-01-07 18:16** - ✅ Phase 2 완료: Cloud SQL 스키마 마이그레이션 완료
- **2026-01-07 18:00** - ✅ Phase 1 완료: GCP 인프라 설정 완료

---
최종 업데이트: 2026-01-07 18:35
