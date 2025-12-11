# Dokploy 배포 설정 가이드

## 저장소 정보
- **Repository URL**: https://github.com/myaji35/15_CertiGraph.git
- **Branch**: main
- **Backend Path**: /backend
- **Dokploy Server**: http://34.64.143.114:3000
- **Application ID**: 4sc-UR-ll0dwt7DtoBECo

## 단계별 배포 가이드

### 1. Dokploy 대시보드 접속
http://34.64.143.114:3000/dashboard/project/SVSYksCZ8lAr2Mdrg8902/environment/jn2nZM3RYvYrTczdn4Tdl/services/application/4sc-UR-ll0dwt7DtoBECo

### 2. Git 저장소 연결

**Git 탭으로 이동:**
- Repository: `https://github.com/myaji35/15_CertiGraph.git`
- Branch: `main`
- Provider: GitHub
- Build Path: `/backend`
- Dockerfile Path: `Dockerfile`

**GitHub 연동 방법:**
- Personal Access Token 사용
  1. GitHub → Settings → Developer settings → Personal access tokens
  2. Generate new token (classic)
  3. Scopes: `repo` 전체 선택
  4. Token 복사 → Dokploy에 입력

### 3. 환경 변수 설정 (Environment 탭)

필수 환경 변수:

```bash
# 개발 모드 (선택)
DEV_MODE=false

# Clerk 인증
CLERK_JWKS_URL=https://your-clerk-domain.clerk.accounts.dev/.well-known/jwks.json

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key

# AI API Keys
ANTHROPIC_API_KEY=sk-ant-your-key
GOOGLE_API_KEY=your-google-key
OPENAI_API_KEY=sk-your-openai-key

# 선택사항 (MVP에서는 필수 아님)
UPSTAGE_API_KEY=your-upstage-key
PINECONE_API_KEY=your-pinecone-key
PINECONE_INDEX_NAME=certigraph-questions

# Neo4j (선택)
NEO4J_URI=neo4j+s://your-instance.databases.neo4j.io
NEO4J_USER=neo4j
NEO4J_PASSWORD=your-password

# Plane (선택 - 프로젝트 관리용)
PLANE_API_URL=http://localhost:8000/api/v1
PLANE_API_KEY=your-plane-key
PLANE_WORKSPACE=your-workspace
PLANE_PROJECT_ID=your-project-id

# Inngest (선택 - 백그라운드 작업용)
INNGEST_EVENT_KEY=your-inngest-key

# CORS
CORS_ORIGINS=https://your-frontend-domain.vercel.app,http://localhost:3000
```

### 4. 빌드 설정 (Settings 탭)

**General:**
- App Name: certigraph-backend
- Port: `8000`

**Health Check:**
- Path: `/health`
- Port: `8000`

**Docker:**
- Dockerfile: `Dockerfile`
- Build Args: (없음 필요시 추가)

### 5. 도메인 설정 (Domains 탭)

옵션 1: Dokploy 제공 도메인 사용
- 자동 생성되는 도메인 확인

옵션 2: 커스텀 도메인
- 도메인 추가
- DNS A 레코드: `34.64.143.114`
- SSL 인증서 자동 발급 (Let's Encrypt)

### 6. 배포 실행

1. 모든 설정 완료 확인
2. **"Deploy" 버튼** 클릭
3. 빌드 로그 모니터링
4. 배포 상태 확인

### 7. 배포 검증

```bash
# Health Check
curl http://YOUR_DOMAIN/health

# 예상 응답
{
  "status": "healthy",
  "version": "1.0.0"
}

# API 문서 확인
open http://YOUR_DOMAIN/docs
```

## CLI를 통한 배포 (대체 방법)

로컬 터미널에서:

```bash
# 1. 인증
export DOKPLOY_URL="http://34.64.143.114:3000"
export DOKPLOY_AUTH_TOKEN="your-api-token"

# 2. 확인
dokploy verify

# 3. 프로젝트 조회
dokploy project

# 4. 앱 생성/조회
dokploy app

# 5. 환경 변수 관리
dokploy env
```

## Inngest 백그라운드 작업 설정 (선택사항)

Plane API 호출 등 백그라운드 작업을 사용하려면:

### 개발 환경
```bash
# 로컬에서 Inngest Dev Server 실행
npx inngest-cli@latest dev
```

### 프로덕션
1. Inngest Cloud 가입: https://www.inngest.com/
2. 프로젝트 생성
3. Event Key 발급
4. 환경 변수 설정: `INNGEST_EVENT_KEY=your-key`
5. Inngest Cloud에서 앱 등록:
   - App URL: `https://your-domain.com/api/inngest`
   - Endpoint 자동 동기화

## 트러블슈팅

### 빌드 실패
- **로그 확인**: Dokploy 대시보드 → Logs 탭
- **Dockerfile 경로**: Build Path가 `/backend`인지 확인
- **의존성 문제**: requirements.txt 확인

### 런타임 에러
- **환경 변수**: 모든 필수 변수가 설정되었는지 확인
- **Health Check**: `/health` 엔드포인트 응답 확인
- **로그**: 애플리케이션 로그에서 에러 확인

### 포트 충돌
- 포트 8000이 올바르게 설정되었는지 확인
- Health Check 포트와 App 포트가 동일한지 확인

### Git 연동 실패
- GitHub Personal Access Token 권한 확인
- Repository URL이 올바른지 확인
- Branch 이름이 정확한지 확인 (`main`)

## 최신 변경사항 (2025-01-11)

✅ Inngest 백그라운드 작업 통합
✅ Plane 프로젝트 관리 API 추가
✅ 자동 재시도 기능 (최대 3회)
✅ 비동기 작업 처리 (사용자 요청 블로킹 방지)

최신 커밋: `5160aac` - feat: Add Inngest background jobs and Plane project management integration
