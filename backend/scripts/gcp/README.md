# GCP Migration Scripts

이 디렉토리에는 Supabase/Pinecone에서 GCP로 마이그레이션하기 위한 스크립트들이 있습니다.

## 사전 준비사항

1. **GCP 프로젝트 생성**
```bash
gcloud projects create certigraph-prod
gcloud config set project certigraph-prod
```

2. **Billing 계정 연결**
```bash
gcloud beta billing accounts list
gcloud beta billing projects link certigraph-prod --billing-account=ACCOUNT_ID
```

3. **gcloud CLI 설치 및 인증**
```bash
gcloud auth login
gcloud auth application-default login
```

4. **Service Account 생성 및 키 다운로드**
```bash
gcloud iam service-accounts create certigraph-sa \
  --display-name="CertiGraph Service Account"

gcloud projects add-iam-policy-binding certigraph-prod \
  --member="serviceAccount:certigraph-sa@certigraph-prod.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding certigraph-prod \
  --member="serviceAccount:certigraph-sa@certigraph-prod.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

gcloud iam service-accounts keys create ~/certigraph-key.json \
  --iam-account=certigraph-sa@certigraph-prod.iam.gserviceaccount.com
```

5. **환경 변수 설정**
```bash
export GOOGLE_APPLICATION_CREDENTIALS=~/certigraph-key.json
export GCP_PROJECT_ID=certigraph-prod
```

## 마이그레이션 순서

### 1. Cloud SQL 설정
```bash
chmod +x scripts/gcp/1_setup_cloud_sql.sh
./scripts/gcp/1_setup_cloud_sql.sh
```

**결과물**: Cloud SQL 인스턴스, 데이터베이스, 사용자 생성됨

### 2. Cloud SQL Proxy 실행 (로컬 개발용)
```bash
cloud-sql-proxy PROJECT_ID:REGION:INSTANCE_NAME &
```

### 3. 스키마 마이그레이션
```bash
python scripts/gcp/2_migrate_schema.py
```

**선택지**:
- Option 1: Supabase에서 자동 export (SUPABASE_DB_PASSWORD 필요)
- Option 2: 기존 schema.sql 파일 사용

### 4. 데이터 마이그레이션
```bash
python scripts/gcp/3_migrate_data.py
```

### 5. Vertex AI Vector Search 설정
```bash
python scripts/gcp/4_setup_vertex_ai.py
```

**소요 시간**: 30-60분 (인덱스 생성)

### 6. Neo4j 설정 (선택사항)
```bash
./scripts/gcp/5_setup_neo4j.sh
```

**옵션**:
- GCE에 Neo4j 설치
- 또는 Neo4j Aura 계속 사용 (하이브리드 접근)

### 7. 검증
```bash
python scripts/gcp/6_verify_migration.py
```

## 환경 변수 업데이트

마이그레이션 후 `.env` 파일 업데이트:

```bash
# GCP 모드 활성화
USE_CLOUD_SQL=true
USE_VERTEX_AI=true

# Cloud SQL
CLOUD_SQL_HOST=localhost  # Cloud SQL Proxy 사용 시
CLOUD_SQL_PORT=5432
CLOUD_SQL_DATABASE=certigraph
CLOUD_SQL_USER=certigraph_user
CLOUD_SQL_PASSWORD=<스크립트 1에서 생성된 비밀번호>
CLOUD_SQL_CONNECTION_NAME=certigraph-prod:asia-northeast3:certigraph-db

# Vertex AI
GCP_PROJECT_ID=certigraph-prod
GCP_REGION=asia-northeast3
VERTEX_AI_INDEX_ID=<스크립트 4에서 생성된 ID>
VERTEX_AI_INDEX_ENDPOINT_ID=<스크립트 4에서 생성된 ID>
GOOGLE_APPLICATION_CREDENTIALS=~/certigraph-key.json

# 기존 Supabase/Pinecone 설정은 주석 처리 또는 삭제
# SUPABASE_URL=...
# PINECONE_API_KEY=...
```

## 롤백 절차

마이그레이션 실패 시:

1. `.env`에서 `USE_CLOUD_SQL=false`, `USE_VERTEX_AI=false`로 변경
2. Supabase/Pinecone 환경 변수 복원
3. 서버 재시작

## 비용 최적화

**개발 환경**:
```bash
# Cloud SQL 인스턴스 중지 (사용하지 않을 때)
gcloud sql instances patch certigraph-db --activation-policy=NEVER

# 재시작
gcloud sql instances patch certigraph-db --activation-policy=ALWAYS
```

**프로덕션**:
- Cloud SQL: 자동 백업 활성화 (스크립트 1에 포함됨)
- Vertex AI: min_replica_count=1로 설정 (스크립트 4에 포함됨)

## 문제 해결

### Cloud SQL 연결 오류
```bash
# Cloud SQL Proxy 로그 확인
cloud-sql-proxy PROJECT_ID:REGION:INSTANCE_NAME --verbose

# 방화벽 확인
gcloud sql instances describe certigraph-db | grep ipConfiguration
```

### Vertex AI 인덱스 생성 실패
```bash
# 인덱스 상태 확인
gcloud ai indexes list --region=asia-northeast3

# 로그 확인
gcloud logging read "resource.type=aiplatform.googleapis.com/Index" --limit 50
```

## 추가 리소스

- [Cloud SQL 문서](https://cloud.google.com/sql/docs)
- [Vertex AI Vector Search 문서](https://cloud.google.com/vertex-ai/docs/matching-engine/overview)
- [GCP 마이그레이션 계획](../docs/GCP_MIGRATION_PLAN.md)
