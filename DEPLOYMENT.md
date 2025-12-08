# CertiGraph Coolify 배포 가이드

## 배포 아키텍처
```
Frontend (Next.js) → Backend (FastAPI) → Database (PostgreSQL)
   :3000               :8000
```

## Prerequisites
- Coolify 설치 및 실행 중
- GitHub 저장소 접근 권한
- PostgreSQL 데이터베이스
- Clerk 인증 설정
- API Keys (Upstage, OpenAI, Google)

## 배포 단계

### 1. GitHub 연동
Coolify에서 GitHub 저장소 연결:
- Repository: `https://github.com/myaji35/15_CertiGraph`
- Branch: `main`

### 2. 환경 변수 설정
Coolify에서 다음 환경 변수 설정:

**필수 환경 변수:**
```env
# Domain
DOMAIN=your-domain.com

# Database
DATABASE_URL=postgresql://user:password@db:5432/certigraph

# JWT
JWT_SECRET_KEY=your-secret-key
JWT_ALGORITHM=HS256

# Clerk Auth
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
CLERK_PEM_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----...

# API Keys
UPSTAGE_API_KEY=up_...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=...
```

### 3. 서비스 설정

#### Frontend 설정:
- Build Command: `docker build -f frontend/Dockerfile frontend`
- Port: 3000
- Domain: `certigraph.your-domain.com`

#### Backend 설정:
- Build Command: `docker build -f backend/Dockerfile backend`
- Port: 8000
- Domain: `api.certigraph.your-domain.com`

### 4. PostgreSQL 설정
Coolify에서 PostgreSQL 서비스 추가:
- Database Name: `certigraph`
- User: `certigraph_user`
- Password: (secure password)

### 5. CORS 설정
Backend 환경 변수에 Frontend URL 추가:
```env
CORS_ORIGINS=["https://certigraph.your-domain.com"]
```

### 6. 빌드 및 배포
1. Coolify에서 "Deploy" 버튼 클릭
2. 빌드 로그 확인
3. 서비스 상태 확인

### 7. SSL 인증서
Coolify는 Let's Encrypt를 통해 자동으로 SSL 인증서 발급

## 모니터링
- Frontend: `https://certigraph.your-domain.com`
- Backend API: `https://api.certigraph.your-domain.com/docs`
- Health Check: `https://api.certigraph.your-domain.com/health`

## 트러블슈팅

### Frontend 빌드 실패
```bash
# node_modules 캐시 클리어
docker system prune -a
```

### Backend 연결 실패
- DATABASE_URL 확인
- CORS 설정 확인
- API Keys 유효성 확인

### 데이터베이스 마이그레이션
```bash
docker exec -it backend-container python -m alembic upgrade head
```

## 업데이트 절차
1. GitHub에 코드 푸시
2. Coolify에서 "Redeploy" 클릭
3. Zero-downtime 배포 자동 수행

## 백업
정기적으로 PostgreSQL 데이터 백업:
```bash
pg_dump -U certigraph_user certigraph > backup_$(date +%Y%m%d).sql
```
