# PostgreSQL Migration from Supabase

## Overview
Migrate from Supabase to self-managed GCP Cloud SQL PostgreSQL for better control, cost optimization, and direct database access.

## Business Value
- **Cost Reduction**: Direct PostgreSQL hosting is cheaper than Supabase managed service
- **Full Control**: Direct access to database for optimization and custom configurations
- **Security**: Data hosted on organization's GCP project
- **Performance**: Optimized queries and indexing without Supabase overhead

---

## Current State (Supabase)

### Database Schema
```sql
-- User Profiles
CREATE TABLE user_profiles (
  clerk_id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Certifications
CREATE TABLE certifications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  organization TEXT
);

-- Exam Dates
CREATE TABLE exam_dates (
  id TEXT PRIMARY KEY,
  certification_id TEXT REFERENCES certifications(id),
  exam_date DATE NOT NULL,
  round INTEGER,
  exam_type TEXT
);

-- Subscriptions
CREATE TABLE subscriptions (
  id TEXT PRIMARY KEY,
  clerk_id TEXT REFERENCES user_profiles(clerk_id),
  certification_id TEXT REFERENCES certifications(id),
  exam_date_id TEXT REFERENCES exam_dates(id),
  payment_amount INTEGER,
  payment_method TEXT,
  payment_status TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Study Sets
CREATE TABLE study_sets (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES user_profiles(clerk_id),
  name TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  certification_id TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Study Materials
CREATE TABLE study_materials (
  id TEXT PRIMARY KEY,
  study_set_id TEXT REFERENCES study_sets(id),
  pdf_name TEXT,
  pdf_url TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Questions
CREATE TABLE questions (
  id TEXT PRIMARY KEY,
  material_id TEXT REFERENCES study_materials(id),
  question_text TEXT NOT NULL,
  options JSONB,
  correct_answer TEXT,
  explanation TEXT,
  concepts TEXT[],
  difficulty TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Current Dependencies
- `supabase-py` SDK
- Supabase REST API
- Supabase Auth (JWT validation)
- Row-Level Security (RLS) policies

---

## Target State (GCP Cloud SQL PostgreSQL)

### GCP Resources

#### Cloud SQL Instance
```yaml
Instance Name: certigraph-postgres
Database Version: PostgreSQL 15
Region: asia-northeast3 (Seoul)
Tier: db-f1-micro (development) or db-n1-standard-1 (production)
Storage: 10GB SSD (auto-scaling enabled)
Backup: Automated daily backups with 7-day retention
High Availability: Regional (production only)
```

#### Networking
```yaml
Public IP: Enabled with authorized networks
Private IP: VPC peering for backend services
SSL: Required for all connections
Connection Name: certigraph-project:asia-northeast3:certigraph-postgres
```

### Database Configuration
```sql
-- Create database
CREATE DATABASE certigraph_db;

-- Create application user
CREATE USER certigraph_app WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE certigraph_db TO certigraph_app;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- For encryption
```

---

## Migration Strategy

### Phase 1: Setup GCP Cloud SQL (Week 1)

**FR-1.1: Provision Cloud SQL Instance**
```bash
# Create Cloud SQL instance
gcloud sql instances create certigraph-postgres \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=asia-northeast3 \
  --storage-type=SSD \
  --storage-size=10GB \
  --storage-auto-increase \
  --backup-start-time=03:00 \
  --enable-bin-log

# Set root password
gcloud sql users set-password postgres \
  --instance=certigraph-postgres \
  --password=SECURE_ROOT_PASSWORD

# Create application user
gcloud sql users create certigraph_app \
  --instance=certigraph-postgres \
  --password=SECURE_APP_PASSWORD
```

**FR-1.2: Configure Networking**
```bash
# Allow connections from development machine
gcloud sql instances patch certigraph-postgres \
  --authorized-networks=YOUR_IP_ADDRESS/32

# Enable SSL
gcloud sql ssl-certs create client-cert \
  --instance=certigraph-postgres

# Download certificates
gcloud sql ssl-certs describe client-cert \
  --instance=certigraph-postgres \
  --format="get(cert)" > client-cert.pem

gcloud sql instances describe certigraph-postgres \
  --format="get(serverCaCert.cert)" > server-ca.pem
```

**FR-1.3: Create Database Schema**
```python
# backend/migrations/001_initial_schema.sql
-- Execute all CREATE TABLE statements from current Supabase schema
-- Add indexes for performance
CREATE INDEX idx_study_sets_user_id ON study_sets(user_id);
CREATE INDEX idx_questions_material_id ON questions(material_id);
CREATE INDEX idx_subscriptions_clerk_id ON subscriptions(clerk_id);
CREATE INDEX idx_exam_dates_certification ON exam_dates(certification_id);

-- Add full-text search indexes
CREATE INDEX idx_questions_text_search ON questions
  USING gin(to_tsvector('english', question_text));
```

### Phase 2: Update Backend Code (Week 2)

**FR-2.1: Replace Supabase SDK with psycopg2/SQLAlchemy**

Before (Supabase):
```python
from supabase import create_client

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
result = supabase.table("study_sets").select("*").eq("user_id", user_id).execute()
```

After (PostgreSQL):
```python
import psycopg2
from psycopg2.extras import RealDictCursor

conn = psycopg2.connect(
    host=os.getenv("POSTGRES_HOST"),
    database=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD"),
    sslmode='require',
    sslrootcert='server-ca.pem',
    sslcert='client-cert.pem',
    sslkey='client-key.pem'
)

cursor = conn.cursor(cursor_factory=RealDictCursor)
cursor.execute("SELECT * FROM study_sets WHERE user_id = %s", (user_id,))
result = cursor.fetchall()
```

**FR-2.2: Create Database Layer**
```python
# backend/app/db/connection.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import QueuePool

DATABASE_URL = f"postgresql://{os.getenv('POSTGRES_USER')}:{os.getenv('POSTGRES_PASSWORD')}@{os.getenv('POSTGRES_HOST')}/{os.getenv('POSTGRES_DB')}?sslmode=require"

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # Verify connections before using
    echo=os.getenv("DEBUG") == "True"
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

**FR-2.3: Update Repository Pattern**
```python
# backend/app/repositories/study_set.py
from sqlalchemy.orm import Session
from app.db.models import StudySet

class StudySetRepository:
    def __init__(self, db: Session):
        self.db = db

    async def find_all_by_user(self, user_id: str, skip: int = 0, limit: int = 50):
        return self.db.query(StudySet)\
            .filter(StudySet.user_id == user_id)\
            .offset(skip)\
            .limit(limit)\
            .all()

    async def create(self, study_set_data: dict):
        study_set = StudySet(**study_set_data)
        self.db.add(study_set)
        self.db.commit()
        self.db.refresh(study_set)
        return study_set
```

**FR-2.4: Update Environment Variables**
```bash
# .env
# Remove Supabase
# SUPABASE_URL=...
# SUPABASE_SERVICE_KEY=...

# Add PostgreSQL
POSTGRES_HOST=35.xxx.xxx.xxx  # Cloud SQL Public IP
POSTGRES_DB=certigraph_db
POSTGRES_USER=certigraph_app
POSTGRES_PASSWORD=secure_password
POSTGRES_PORT=5432
POSTGRES_SSL_MODE=require
POSTGRES_SSL_ROOT_CERT=./certs/server-ca.pem
POSTGRES_SSL_CERT=./certs/client-cert.pem
POSTGRES_SSL_KEY=./certs/client-key.pem
```

### Phase 3: Data Migration (Week 3)

**FR-3.1: Export Data from Supabase**
```python
# backend/scripts/export_supabase_data.py
import os
from supabase import create_client
import json

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

tables = ["user_profiles", "certifications", "exam_dates", "subscriptions", "study_sets", "study_materials", "questions"]

for table in tables:
    data = supabase.table(table).select("*").execute()
    with open(f"backup/{table}.json", "w") as f:
        json.dump(data.data, f, indent=2, default=str)
    print(f"Exported {len(data.data)} rows from {table}")
```

**FR-3.2: Import Data to PostgreSQL**
```python
# backend/scripts/import_to_postgres.py
import psycopg2
import json
from psycopg2.extras import execute_values

conn = psycopg2.connect(...)

tables = ["user_profiles", "certifications", "exam_dates", "subscriptions", "study_sets", "study_materials", "questions"]

for table in tables:
    with open(f"backup/{table}.json", "r") as f:
        data = json.load(f)

    if not data:
        continue

    # Get column names
    columns = list(data[0].keys())
    values = [[row[col] for col in columns] for row in data]

    # Bulk insert
    query = f"INSERT INTO {table} ({','.join(columns)}) VALUES %s ON CONFLICT DO NOTHING"
    cursor = conn.cursor()
    execute_values(cursor, query, values)
    conn.commit()
    print(f"Imported {len(data)} rows to {table}")
```

**FR-3.3: Verify Data Integrity**
```sql
-- Compare row counts
SELECT 'user_profiles' as table_name, COUNT(*) as count FROM user_profiles
UNION ALL
SELECT 'study_sets', COUNT(*) FROM study_sets
UNION ALL
SELECT 'questions', COUNT(*) FROM questions;

-- Verify foreign key relationships
SELECT
  ss.id,
  ss.user_id,
  up.email,
  COUNT(sm.id) as material_count
FROM study_sets ss
LEFT JOIN user_profiles up ON ss.user_id = up.clerk_id
LEFT JOIN study_materials sm ON sm.study_set_id = ss.id
GROUP BY ss.id, ss.user_id, up.email;
```

### Phase 4: Testing & Deployment (Week 4)

**FR-4.1: Update Tests**
```python
# backend/tests/conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.connection import Base

@pytest.fixture(scope="function")
def db_session():
    # Create test database
    engine = create_engine("postgresql://test_user:test_pass@localhost/test_db")
    Base.metadata.create_all(engine)

    Session = sessionmaker(bind=engine)
    session = Session()

    yield session

    session.close()
    Base.metadata.drop_all(engine)
```

**FR-4.2: Integration Testing**
- Test all API endpoints with PostgreSQL backend
- Verify data persistence
- Test connection pooling under load
- Validate SSL certificate authentication

**FR-4.3: Performance Testing**
```sql
-- Add query explain plans
EXPLAIN ANALYZE
SELECT * FROM study_sets WHERE user_id = 'user_123';

-- Monitor slow queries
CREATE EXTENSION pg_stat_statements;
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

**FR-4.4: Deployment Checklist**
- [ ] Cloud SQL instance provisioned and configured
- [ ] SSL certificates generated and stored securely
- [ ] Database schema migrated
- [ ] Data imported and verified
- [ ] Backend code updated and tested
- [ ] Environment variables configured
- [ ] Monitoring and alerting setup (Cloud Monitoring)
- [ ] Backup strategy verified
- [ ] Rollback plan documented
- [ ] Supabase account deactivated (after verification period)

---

## Files to Update/Delete

### Files to UPDATE
```
backend/.env
backend/app/core/config.py
backend/app/db/connection.py (new)
backend/app/db/models.py (new)
backend/app/repositories/*.py (all repositories)
backend/app/api/v1/deps.py
backend/requirements.txt
backend/docker-compose.yml
backend/alembic/env.py (for migrations)
CLAUDE.md
.bmad/features/postgresql-migration.md
```

### Files to DELETE
```
backend/app/services/supabase_client.py
backend/check_user_supabase.py
backend/apply_migration_supabase.py
Any other Supabase-specific utility scripts
```

### Dependencies to CHANGE
```python
# requirements.txt
# Remove:
# supabase==2.x.x

# Add:
psycopg2-binary==2.9.9
SQLAlchemy==2.0.23
alembic==1.13.1  # For database migrations
```

---

## Rollback Plan

If migration fails:

1. **Immediate Rollback**
   - Revert `.env` to Supabase credentials
   - Redeploy previous backend version
   - Supabase data remains intact

2. **Data Recovery**
   - Restore from Supabase export
   - Cloud SQL automated backups (7-day retention)

3. **Zero Downtime Strategy**
   - Run both databases in parallel during transition
   - Gradual traffic migration using feature flags

---

## Cost Comparison

### Supabase
- Free tier: $0/month (limited)
- Pro: $25/month + usage
- Estimated monthly: $50-100

### GCP Cloud SQL
- db-f1-micro: ~$7.67/month
- 10GB SSD: ~$1.70/month
- Backup storage: ~$0.20/month
- **Total: ~$10/month** (87% cost reduction)

---

## Success Criteria

- [ ] Zero data loss during migration
- [ ] All existing API endpoints functional
- [ ] Query performance equal or better than Supabase
- [ ] SSL connections enforced
- [ ] Automated backups running daily
- [ ] Application response time < 200ms (p95)
- [ ] Database connection pool stable under load
- [ ] All integration tests passing

---

## Timeline

| Week | Phase | Tasks |
|------|-------|-------|
| 1 | Setup | Provision Cloud SQL, configure networking, create schema |
| 2 | Development | Update backend code, create DB layer, update repositories |
| 3 | Migration | Export data, import to PostgreSQL, verify integrity |
| 4 | Testing | Integration tests, performance tests, deployment |

**Total Estimated Time: 4 weeks**

---

## Monitoring & Maintenance

### Cloud Monitoring Alerts
```yaml
- High Connection Count (> 80% of max)
- Slow Queries (> 1 second)
- Disk Usage (> 80%)
- Failed Connections
- Replication Lag (if HA enabled)
```

### Regular Maintenance
- Weekly: Review slow query logs
- Monthly: Vacuum and analyze tables
- Quarterly: Review and optimize indexes
- Yearly: Database version upgrades

---

## References

- [GCP Cloud SQL PostgreSQL Documentation](https://cloud.google.com/sql/docs/postgres)
- [SQLAlchemy ORM Documentation](https://docs.sqlalchemy.org/)
- [psycopg2 Documentation](https://www.psycopg.org/docs/)
- [PostgreSQL Performance Tuning](https://www.postgresql.org/docs/current/performance-tips.html)
