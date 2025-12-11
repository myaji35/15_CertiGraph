# Dokploy CLI 배포 가이드

## 빠른 시작

### 1. API 토큰 발급
http://34.64.143.114:3000 접속 → Settings → API Tokens → Create Token

### 2. 배포 스크립트 실행
```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph
./deploy-dokploy.sh YOUR_API_TOKEN
```

스크립트가 자동으로:
- ✅ 인증 확인
- ✅ 프로젝트 목록 표시
- ✅ 새 프로젝트 생성 (필요시)
- ✅ 애플리케이션 생성
- ✅ 배포 실행

## 수동 실행 (단계별)

API 토큰을 발급받은 후:

```bash
# 1. 환경 변수 설정
export DOKPLOY_URL="http://34.64.143.114:3000"
export DOKPLOY_AUTH_TOKEN="YOUR_API_TOKEN"

# 2. 인증 확인
dokploy verify

# 3. 기존 프로젝트 목록
dokploy project list

# 4. 새 프로젝트 생성 (선택사항)
dokploy project create
# 프롬프트:
#   - Project name: certigraph
#   - Description: AI-powered certification exam study platform

# 5. 프로젝트 정보 확인
dokploy project info --project-id YOUR_PROJECT_ID

# 6. 새 앱 생성
dokploy app create
# 프롬프트:
#   - Project ID: (위에서 받은 ID)
#   - Application name: certigraph-backend
#   - Application type: application
#   - Source type: git
#   - Repository: git@github.com:myaji35/15_CertiGraph.git
#   - Branch: main
#   - Build path: /backend
#   - Dockerfile: Dockerfile

# 7. 환경 변수 설정 (대시보드에서)
# http://34.64.143.114:3000 → 프로젝트 → 앱 → Environment 탭

# 8. 배포
dokploy app deploy --app-id YOUR_APP_ID
```

## 필수 환경 변수

대시보드 또는 CLI로 설정:

```bash
# 필수
CLERK_JWKS_URL=https://your-clerk-domain.clerk.accounts.dev/.well-known/jwks.json
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key
OPENAI_API_KEY=sk-your-openai-api-key
GOOGLE_API_KEY=your-google-api-key
CORS_ORIGINS=https://your-frontend-domain.vercel.app

# 선택 (MVP에서는 불필요)
ANTHROPIC_API_KEY=sk-ant-your-key
UPSTAGE_API_KEY=your-upstage-key
PINECONE_API_KEY=your-pinecone-key
PINECONE_INDEX_NAME=certigraph-questions
NEO4J_URI=neo4j+s://your-instance.databases.neo4j.io
NEO4J_USER=neo4j
NEO4J_PASSWORD=your-password
PLANE_API_KEY=your-plane-key
PLANE_WORKSPACE=your-workspace
PLANE_PROJECT_ID=your-project-id
INNGEST_EVENT_KEY=your-inngest-key
```

## CLI 환경 변수 설정 (대체 방법)

```bash
# env 명령어로 환경 변수 저장
dokploy env

# 로컬 .env 파일에서 환경 변수 가져오기
# 1. backend/.env 파일 준비
# 2. 대시보드에서 수동으로 복사/붙여넣기
```

## 배포 모니터링

```bash
# 앱 상태 확인
dokploy app info --app-id YOUR_APP_ID

# 대시보드에서 로그 확인
# http://34.64.143.114:3000 → 프로젝트 → 앱 → Logs 탭
```

## 배포 검증

```bash
# Health Check
curl http://YOUR_DEPLOYMENT_URL/health

# 예상 응답
{
  "status": "healthy",
  "version": "1.0.0"
}

# API 문서
open http://YOUR_DEPLOYMENT_URL/docs
```

## 기존 애플리케이션 업데이트

이미 생성된 애플리케이션이 있다면 (URL에서 ID 확인):
```
Application ID: 4sc-UR-ll0dwt7DtoBECo
```

환경 변수만 설정하고 배포:
```bash
export DOKPLOY_URL="http://34.64.143.114:3000"
export DOKPLOY_AUTH_TOKEN="YOUR_API_TOKEN"

# 배포
dokploy app deploy --app-id 4sc-UR-ll0dwt7DtoBECo
```

## 트러블슈팅

### 인증 실패
```bash
# 토큰 재확인
echo $DOKPLOY_AUTH_TOKEN

# 새 토큰 발급
# Settings → API Tokens → Create new token
```

### 빌드 실패
- 로그 확인: 대시보드 → Logs
- Dockerfile 경로: `/backend/Dockerfile`
- Build path: `/backend`

### 앱이 시작되지 않음
- 환경 변수 확인
- Port 8000 설정 확인
- Health check `/health` 확인

## 참고 문서

- **Dokploy 설정**: `DOKPLOY_SETUP.md`
- **백엔드 배포**: `backend/DEPLOYMENT.md`
- **Plane 통합**: `docs/plane-integration.md`
