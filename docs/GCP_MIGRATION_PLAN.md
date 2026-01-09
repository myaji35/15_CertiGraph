# GCP Migration Plan for CertiGraph

## 1. Migration Overview

### Current Stack
- **PostgreSQL**: Supabase (유료 전환됨)
- **Vector DB**: Pinecone
- **Graph DB**: Neo4j AuraDB
- **Auth**: Clerk
- **Storage**: Supabase Storage (현재 사용 안 함)

### Target GCP Stack
- **PostgreSQL**: Cloud SQL for PostgreSQL
- **Vector DB**: Vertex AI Vector Search (Matching Engine)
- **Graph DB**: Neo4j on GCE (Compute Engine)
- **Auth**: Clerk (유지)
- **Storage**: Cloud Storage

## 2. Migration Phases

### Phase 1: Infrastructure Setup (Week 1)
- [ ] GCP 프로젝트 생성
- [ ] Cloud SQL 인스턴스 생성
- [ ] Vertex AI API 활성화
- [ ] GCE Neo4j 인스턴스 설정
- [ ] Cloud Storage 버킷 생성
- [ ] VPC 및 네트워크 설정

### Phase 2: Database Migration (Week 2)
- [ ] Supabase 스키마 export
- [ ] Cloud SQL 스키마 적용
- [ ] 데이터 마이그레이션 스크립트 작성
- [ ] 데이터 검증

### Phase 3: Backend Code Migration (Week 3-4)
- [ ] Supabase client → Cloud SQL 연결로 변경
- [ ] RPC 함수 → Raw SQL/ORM 쿼리로 변경
- [ ] Pinecone → Vertex AI Vector Search 변경
- [ ] 환경 변수 업데이트
- [ ] 의존성 패키지 업데이트

### Phase 4: Testing & Validation (Week 5)
- [ ] 단위 테스트 수정 및 실행
- [ ] 통합 테스트
- [ ] 성능 테스트
- [ ] 롤백 계획 수립

## 3. Detailed Implementation

### 3.1 Cloud SQL Setup

```bash
# Create Cloud SQL instance
gcloud sql instances create certigraph-db \
  --database-version=POSTGRES_15 \
  --tier=db-custom-2-7680 \
  --region=asia-northeast3 \
  --storage-type=SSD \
  --storage-size=20GB \
  --storage-auto-increase \
  --backup-start-time=03:00 \
  --enable-bin-log \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=4

# Create database
gcloud sql databases create certigraph \
  --instance=certigraph-db

# Create user
gcloud sql users create certigraph_user \
  --instance=certigraph-db \
  --password='<strong-password>'

# Enable Cloud SQL Admin API
gcloud services enable sqladmin.googleapis.com
```

### 3.2 Vertex AI Vector Search Setup

```bash
# Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com

# Create index (via Python SDK - see scripts/gcp/setup_vertex_ai.py)
```

### 3.3 Neo4j on GCE Setup

```bash
# Create GCE instance
gcloud compute instances create neo4j-instance \
  --zone=asia-northeast3-a \
  --machine-type=n2-standard-2 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --boot-disk-type=pd-ssd \
  --tags=neo4j-server

# Create firewall rule
gcloud compute firewall-rules create allow-neo4j \
  --allow=tcp:7474,tcp:7687 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=neo4j-server
```

### 3.4 Required Code Changes

#### Files to Modify:
1. `backend/app/core/config.py` - 환경 변수 추가
2. `backend/app/api/v1/deps.py` - DB 연결 변경
3. `backend/app/db/session.py` (신규) - SQLAlchemy 설정
4. `backend/app/api/v1/endpoints/subscriptions.py` - 쿼리 변경
5. `backend/app/api/v1/endpoints/admin.py` - 쿼리 변경
6. `backend/app/services/vector_search.py` (신규) - Vertex AI 클라이언트
7. `backend/requirements.txt` - 의존성 업데이트

## 4. Migration Scripts Location

All migration scripts will be in:
```
backend/scripts/gcp/
├── 1_setup_cloud_sql.sh
├── 2_migrate_schema.py
├── 3_migrate_data.py
├── 4_setup_vertex_ai.py
├── 5_setup_neo4j.sh
└── 6_verify_migration.py
```

## 5. Rollback Strategy

1. Keep Supabase active for 2 weeks after migration
2. Maintain dual-write capability during transition
3. DNS/environment variable quick switch capability
4. Automated data sync validation

## 6. Cost Estimation (Monthly)

| Service | Configuration | Cost (USD) |
|---------|--------------|-----------|
| Cloud SQL | db-custom-2-7680, 20GB | $130 |
| Vertex AI Vector Search | 100K vectors, ~1000 queries/day | $50-100 |
| GCE Neo4j | n2-standard-2 | $60 |
| Cloud Storage | 10GB | $0.20 |
| Network Egress | ~100GB/month | $12 |
| **Total** | | **$252-302** |

## 7. Timeline

```
Week 1: Infrastructure setup
Week 2: Database migration
Week 3-4: Code migration
Week 5: Testing
Week 6: Production cutover
```

Start Date: 2026-01-07
Target Completion: 2026-02-18

## 8. Next Steps

1. Get GCP project access and credentials
2. Create service accounts with proper IAM roles
3. Set up local development environment with Cloud SQL Proxy
4. Begin Phase 1 infrastructure setup
