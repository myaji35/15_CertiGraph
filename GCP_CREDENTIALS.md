# GCP Credentials and Configuration

**⚠️ IMPORTANT: Keep this file secure and do not commit to git**

## Project Information
- **Project ID**: postgresql-479201
- **Project Number**: 243433369144
- **Region**: asia-northeast3

## Service Account
- **Email**: certigraph-sa@postgresql-479201.iam.gserviceaccount.com
- **Key Location**: ~/certigraph-key.json

## Cloud SQL
- **Instance Name**: certigraph-db
- **Connection Name**: postgresql-479201:asia-northeast3:certigraph-db
- **Public IP**: 34.64.209.227
- **Database**: certigraph
- **User**: certigraph_user
- **Password**: `6zpqI+m/oOlaUx0SszxQEKi3xbV62/Z6SERgUZWudYc=`

## Environment Variables (for .env file)

```bash
# GCP Configuration
USE_CLOUD_SQL=true
GCP_PROJECT_ID=postgresql-479201
GCP_REGION=asia-northeast3
GOOGLE_APPLICATION_CREDENTIALS=/Users/gangseungsig/certigraph-key.json

# Cloud SQL
CLOUD_SQL_HOST=localhost  # When using Cloud SQL Proxy
CLOUD_SQL_PORT=5432
CLOUD_SQL_DATABASE=certigraph
CLOUD_SQL_USER=certigraph_user
CLOUD_SQL_PASSWORD=6zpqI+m/oOlaUx0SszxQEKi3xbV62/Z6SERgUZWudYc=
CLOUD_SQL_CONNECTION_NAME=postgresql-479201:asia-northeast3:certigraph-db
```

## Quick Start Commands

### Start Cloud SQL Proxy (로컬 개발)
```bash
cloud-sql-proxy postgresql-479201:asia-northeast3:certigraph-db &
```

### Connect to Database
```bash
psql "host=localhost port=5432 dbname=certigraph user=certigraph_user password=6zpqI+m/oOlaUx0SszxQEKi3xbV62/Z6SERgUZWudYc="
```

### Verify Connection (Python)
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="certigraph",
    user="certigraph_user",
    password="6zpqI+m/oOlaUx0SszxQEKi3xbV62/Z6SERgUZWudYc="
)
print("Connection successful!")
conn.close()
```

---
Created: 2026-01-07
