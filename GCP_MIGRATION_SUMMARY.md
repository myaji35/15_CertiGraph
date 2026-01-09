# GCP 마이그레이션 요약

## ✅ 완료된 작업

### 1. 마이그레이션 계획 수립
- **파일**: `docs/GCP_MIGRATION_PLAN.md`
- 6주 마이그레이션 타임라인 수립
- 비용 예측: 월 $252-302
- Phase별 작업 계획

### 2. 인프라 설정 스크립트 생성
위치: `backend/scripts/gcp/`

- `1_setup_cloud_sql.sh` - Cloud SQL 인스턴스 생성
- `2_migrate_schema.py` - Supabase → Cloud SQL 스키마 마이그레이션
- `4_setup_vertex_ai.py` - Vertex AI Vector Search 설정
- `README.md` - 전체 마이그레이션 가이드

### 3. Backend 코드 업데이트

#### Config 설정 (app/core/config.py)
```python
# GCP Cloud SQL 설정 추가
use_cloud_sql: bool
cloud_sql_host, cloud_sql_port, cloud_sql_database
cloud_sql_user, cloud_sql_password
cloud_sql_connection_name

# Vertex AI 설정 추가
use_vertex_ai: bool
gcp_project_id, gcp_region
vertex_ai_index_id, vertex_ai_index_endpoint_id
```

#### Database Session (app/db/session.py) - 신규 생성
- SQLAlchemy 엔진 설정
- Cloud SQL 연결 관리
- Connection pooling

#### Dependencies (app/api/v1/deps.py)
- `get_db_client()` - Cloud SQL/Supabase 자동 선택
- `get_supabase()` - 하위 호환성 유지 (deprecated)

#### 의존성 (requirements.txt)
```
# 추가된 패키지
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0
cloud-sql-python-connector[pg8000]>=1.4.0
google-cloud-aiplatform>=1.38.0
```

### 4. 환경 변수 템플릿 (.env.example)
- Cloud SQL 설정
- Vertex AI 설정
- 기존 Supabase/Pinecone과 공존 가능 (feature flag 방식)

## 🔄 현재 아키텍처 상태

### 데이터베이스 레이어
```
┌─────────────────────────────────────┐
│      Application Code              │
├─────────────────────────────────────┤
│      get_db_client() Dependency    │
│  (USE_CLOUD_SQL 플래그로 자동 선택)  │
├──────────────┬──────────────────────┤
│  Cloud SQL   │    Supabase         │
│  (NEW)       │    (LEGACY)         │
└──────────────┴──────────────────────┘
```

### Vector Search 레이어
```
┌─────────────────────────────────────┐
│      Embedding Service             │
├──────────────┬──────────────────────┤
│  Vertex AI   │    Pinecone         │
│  (NEW)       │    (LEGACY)         │
└──────────────┴──────────────────────┘
```

## 📋 다음 단계

### Phase 1: GCP 리소스 생성 (1-2일)
```bash
# 1. GCP 프로젝트 생성
gcloud projects create certigraph-prod

# 2. Service Account 생성
gcloud iam service-accounts create certigraph-sa

# 3. Cloud SQL 설정
./backend/scripts/gcp/1_setup_cloud_sql.sh

# 4. Vertex AI 설정 (30-60분 소요)
python backend/scripts/gcp/4_setup_vertex_ai.py
```

### Phase 2: 데이터 마이그레이션 (1-2일)
```bash
# 1. Schema 마이그레이션
python backend/scripts/gcp/2_migrate_schema.py

# 2. Data 마이그레이션
python backend/scripts/gcp/3_migrate_data.py  # TODO: 생성 필요

# 3. Vector 데이터 마이그레이션
python backend/scripts/gcp/migrate_vectors.py  # TODO: 생성 필요
```

### Phase 3: 코드 마이그레이션 (3-5일)
아직 완료되지 않은 작업:

1. **Subscription endpoint 수정** (app/api/v1/endpoints/subscriptions.py)
   - `supabase.rpc()` → Raw SQL 쿼리로 변환
   - 약 17개 파일에 supabase 사용 중

2. **Vector Search 클라이언트 생성** (신규)
   - `app/services/vector_search.py`
   - Pinecone → Vertex AI 마이그레이션

3. **Repository 레이어 수정**
   - `app/repositories/*.py` 파일들

### Phase 4: 테스트 및 검증 (2-3일)
```bash
# 테스트 실행
pytest backend/tests/

# 통합 테스트
python backend/scripts/gcp/6_verify_migration.py  # TODO: 생성 필요
```

## 🚨 주의사항

### 1. 하위 호환성 유지
현재 코드는 **feature flag 방식**으로 작성됨:
- `USE_CLOUD_SQL=false` → Supabase 사용 (기존 동작)
- `USE_CLOUD_SQL=true` → Cloud SQL 사용 (신규)

이를 통해 점진적 마이그레이션 가능.

### 2. VIP 사용자 패스 코드
`subscriptions.py`의 myaji35@gmail.com VIP 패스는 Cloud SQL 마이그레이션 시에도 유지됨 (코드 레벨 체크).

### 3. Neo4j 전략
Neo4j는 아직 결정되지 않음. 옵션:
- GCE에 직접 설치 (관리 부담 증가)
- Neo4j Aura 유지 (하이브리드 접근)
- BigQuery로 대체 (성능 저하 가능성)

## 📊 마이그레이션 진행률

```
┌────────────────────────────────────────────────┐
│ Phase 1: 계획 수립              [████████] 100%│
│ Phase 2: 인프라 설정 스크립트    [████████] 100%│
│ Phase 3: 리소스 생성            [        ]   0%│
│ Phase 4: 데이터 마이그레이션     [        ]   0%│
│ Phase 5: 코드 마이그레이션       [██      ]  25%│
│ Phase 6: 테스트                 [        ]   0%│
│                                                │
│ 전체 진행률                     [███     ]  38%│
└────────────────────────────────────────────────┘
```

## 💰 예상 비용

### 초기 비용 (첫 달)
- Cloud SQL: $130
- Vertex AI: $100 (인덱스 생성 비용 포함)
- GCE (Neo4j): $60
- 네트워크: $12
- **합계: ~$302**

### 이후 월간 비용
- Cloud SQL: $130
- Vertex AI: $50-70 (쿼리 수에 따라)
- GCE (Neo4j): $60
- 네트워크: $10-15
- **합계: ~$250-275**

### Supabase와 비교
- Supabase Pro: $25/월
- 하지만 데이터 증가 시 추가 비용 발생
- GCP는 초기에는 비싸지만 스케일링에 유리

## 🔗 관련 문서

- [전체 마이그레이션 계획](docs/GCP_MIGRATION_PLAN.md)
- [GCP 스크립트 가이드](backend/scripts/gcp/README.md)
- [환경 변수 예시](backend/.env.example)

## 👤 담당자 정보

- Supabase 유료 전환 완료
- GCP 마이그레이션 시작일: 2026-01-07
- 목표 완료일: 2026-02-18 (6주 후)

---

**다음 작업**: GCP 프로젝트 생성 및 Cloud SQL 리소스 설정
```bash
cd backend/scripts/gcp
./1_setup_cloud_sql.sh
```
