# GCP 마이그레이션 빠른 시작 가이드

프로젝트 ID: `postgresql-479201`

## 1단계: GCP 설정 (5분)

### gcloud CLI 설치 확인
```bash
gcloud --version
```

없다면 설치: https://cloud.google.com/sdk/docs/install

### 프로젝트 설정
```bash
# 프로젝트 설정
gcloud config set project postgresql-479201

# 현재 설정 확인
gcloud config list

# 로그인 (필요시)
gcloud auth login
gcloud auth application-default login
```

### Billing 확인
```bash
# Billing 계정 확인
gcloud beta billing accounts list

# Billing 연결 (아직 안 되어있다면)
gcloud beta billing projects link postgresql-479201 --billing-account=YOUR_BILLING_ACCOUNT_ID
```

## 2단계: Service Account 생성 (10분)

```bash
# Service Account 생성
gcloud iam service-accounts create certigraph-sa \
  --display-name="CertiGraph Service Account" \
  --description="Service account for CertiGraph backend"

# Cloud SQL 권한 부여
gcloud projects add-iam-policy-binding postgresql-479201 \
  --member="serviceAccount:certigraph-sa@postgresql-479201.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

# Vertex AI 권한 부여
gcloud projects add-iam-policy-binding postgresql-479201 \
  --member="serviceAccount:certigraph-sa@postgresql-479201.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# Storage 권한 부여 (Vertex AI가 벡터 저장용)
gcloud projects add-iam-policy-binding postgresql-479201 \
  --member="serviceAccount:certigraph-sa@postgresql-479201.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Key 생성 및 다운로드
gcloud iam service-accounts keys create ~/certigraph-key.json \
  --iam-account=certigraph-sa@postgresql-479201.iam.gserviceaccount.com

echo "✅ Service Account 키 저장됨: ~/certigraph-key.json"
```

## 3단계: 필요한 API 활성화 (5분)

```bash
# Cloud SQL Admin API
gcloud services enable sqladmin.googleapis.com

# Vertex AI API
gcloud services enable aiplatform.googleapis.com

# Compute Engine API (Neo4j용, 선택사항)
gcloud services enable compute.googleapis.com

# Cloud Storage API
gcloud services enable storage-api.googleapis.com

# 활성화 확인
gcloud services list --enabled | grep -E "sqladmin|aiplatform|compute|storage"
```

## 4단계: 환경 변수 설정

```bash
# 터미널에서 설정
export GOOGLE_APPLICATION_CREDENTIALS=~/certigraph-key.json
export GCP_PROJECT_ID=postgresql-479201

# ~/.zshrc 또는 ~/.bashrc에 추가 (영구 설정)
echo 'export GOOGLE_APPLICATION_CREDENTIALS=~/certigraph-key.json' >> ~/.zshrc
echo 'export GCP_PROJECT_ID=postgresql-479201' >> ~/.zshrc
source ~/.zshrc
```

## 5단계: Cloud SQL 생성 (15-20분)

```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/backend/scripts/gcp

# 실행
./1_setup_cloud_sql.sh

# 출력된 정보를 저장하세요:
# - Connection Name: postgresql-479201:asia-northeast3:certigraph-db
# - Database User: certigraph_user
# - Database Password: <랜덤 생성된 비밀번호>
```

## 6단계: Cloud SQL Proxy 설치 및 실행

```bash
# Cloud SQL Proxy 다운로드 (Mac용)
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.2/cloud-sql-proxy.darwin.amd64
chmod +x cloud-sql-proxy
sudo mv cloud-sql-proxy /usr/local/bin/

# 실행 (백그라운드)
cloud-sql-proxy postgresql-479201:asia-northeast3:certigraph-db &

# 또는 포그라운드 (디버깅용)
# cloud-sql-proxy postgresql-479201:asia-northeast3:certigraph-db --port 5432
```

## 7단계: 스키마 마이그레이션 (10분)

```bash
# Backend 디렉토리로 이동
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/backend

# 가상환경 활성화
source ../.venv/bin/activate

# psycopg2 설치 (아직 안 했다면)
pip install psycopg2-binary sqlalchemy

# 스키마 마이그레이션 실행
python scripts/gcp/2_migrate_schema.py
```

### 옵션 선택:
- **Option 1**: Supabase에서 자동 export (SUPABASE_DB_PASSWORD 필요)
- **Option 2**: 기존 schema 파일 사용 (`database_schema.sql`)

## 8단계: .env 파일 업데이트

```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/backend

# .env 파일 편집
nano .env
```

추가할 내용:
```bash
# GCP Cloud SQL
USE_CLOUD_SQL=true
CLOUD_SQL_HOST=localhost
CLOUD_SQL_PORT=5432
CLOUD_SQL_DATABASE=certigraph
CLOUD_SQL_USER=certigraph_user
CLOUD_SQL_PASSWORD=<5단계에서 받은 비밀번호>
CLOUD_SQL_CONNECTION_NAME=postgresql-479201:asia-northeast3:certigraph-db

# GCP Project
GCP_PROJECT_ID=postgresql-479201
GCP_REGION=asia-northeast3
GOOGLE_APPLICATION_CREDENTIALS=/Users/gangseungsig/certigraph-key.json
```

## 9단계: Backend 테스트

```bash
# 의존성 설치
pip install -r requirements.txt

# 서버 실행
uvicorn app.main:app --reload --port 8000

# 다른 터미널에서 테스트
curl http://localhost:8000/api/v1/certifications/calendar/2026/1
```

정상 응답이 오면 Cloud SQL 연결 성공!

## 10단계: Vertex AI 설정 (30-60분, 선택사항)

```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/backend

# Vertex AI SDK 설치
pip install google-cloud-aiplatform

# 설정 실행 (시간 오래 걸림)
python scripts/gcp/4_setup_vertex_ai.py
```

## 문제 해결

### "Permission denied" 오류
```bash
# Service Account 권한 재확인
gcloud projects get-iam-policy postgresql-479201 \
  --flatten="bindings[].members" \
  --filter="bindings.members:certigraph-sa@postgresql-479201.iam.gserviceaccount.com"
```

### Cloud SQL 연결 오류
```bash
# Cloud SQL Proxy 로그 확인
cloud-sql-proxy postgresql-479201:asia-northeast3:certigraph-db --verbose

# 인스턴스 상태 확인
gcloud sql instances describe certigraph-db
```

### Backend 서버 오류
```bash
# Python 환경 확인
which python
pip list | grep -E "sqlalchemy|psycopg2|fastapi"

# .env 파일 확인
cat .env | grep -E "CLOUD_SQL|GCP"
```

## 다음 단계

1. ✅ Cloud SQL 연결 성공 후
2. 데이터 마이그레이션 (Supabase → Cloud SQL)
3. Vertex AI 벡터 마이그레이션 (Pinecone → Vertex AI)
4. 프로덕션 전환

## 비용 모니터링

```bash
# 현재 사용량 확인
gcloud billing budgets list

# Cost alert 설정 (선택사항)
gcloud billing budgets create \
  --billing-account=YOUR_BILLING_ACCOUNT_ID \
  --display-name="CertiGraph Monthly Budget" \
  --budget-amount=300USD
```

---

**현재 프로젝트**: postgresql-479201
**시작일**: 2026-01-07
**예상 완료**: 6주 후
