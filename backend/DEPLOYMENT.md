# Dokploy 배포 가이드

## 필수 환경 변수

Dokploy 대시보드 → 애플리케이션 → Environment 탭에서 다음 환경 변수를 설정하세요:

### Clerk (인증)
```
CLERK_JWKS_URL=https://your-clerk-domain.clerk.accounts.dev/.well-known/jwks.json
```

### Supabase (데이터베이스)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key
```

### AI/LLM API Keys
```
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key
GOOGLE_API_KEY=your-google-api-key
OPENAI_API_KEY=sk-your-openai-api-key
UPSTAGE_API_KEY=your-upstage-api-key
```

### Pinecone (Vector DB)
```
PINECONE_API_KEY=your-pinecone-api-key
PINECONE_INDEX_NAME=certigraph-questions
```

### Neo4j (선택사항)
```
NEO4J_URI=neo4j+s://your-instance.databases.neo4j.io
NEO4J_USER=neo4j
NEO4J_PASSWORD=your-neo4j-password
```

### Plane (프로젝트 관리 - 선택사항)
```
PLANE_API_URL=http://localhost:8000/api/v1
PLANE_API_KEY=your-plane-api-key
PLANE_WORKSPACE=your-workspace-slug
PLANE_PROJECT_ID=your-project-id
```

### Inngest (백그라운드 작업 - 선택사항)
```
INNGEST_EVENT_KEY=your-inngest-key
```

### Server
```
CORS_ORIGINS=https://your-frontend-domain.com
DEV_MODE=false
```

## 배포 단계

### 1. Dokploy CLI 인증
```bash
dokploy authenticate --url=http://34.64.143.114:3000 --token=YOUR_API_TOKEN
dokploy verify
```

### 2. Git 저장소 연결 (Dokploy 대시보드에서)
1. 애플리케이션 → Git 탭
2. GitHub 저장소 연결
3. Branch: `main`
4. Build Path: `/backend`
5. Dockerfile: `Dockerfile`

### 3. 빌드 설정
- **Port**: 8000
- **Health Check Path**: `/health`
- **Auto Deploy**: ON (선택사항)

### 4. 도메인 설정 (선택사항)
- 애플리케이션 → Domains 탭
- 커스텀 도메인 추가 또는 Dokploy 제공 도메인 사용

### 5. 배포
- "Deploy" 버튼 클릭
- 빌드 로그 확인

## Inngest 설정 (백그라운드 작업 사용 시)

Inngest를 사용하려면:

### 개발 환경
```bash
npx inngest-cli@latest dev
```

### 프로덕션
1. [Inngest Cloud](https://www.inngest.com/) 계정 생성
2. Event Key 발급
3. 환경 변수에 `INNGEST_EVENT_KEY` 설정
4. Inngest Cloud에서 앱 등록:
   - App URL: `https://your-api-domain.com/api/inngest`

## 배포 확인

```bash
curl http://34.64.143.114:PORT/health
```

예상 응답:
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

## 트러블슈팅

### 빌드 실패
- Dockerfile 경로 확인
- requirements.txt 확인
- 빌드 로그에서 에러 메시지 확인

### 런타임 에러
- 환경 변수 설정 확인
- 애플리케이션 로그 확인
- Health check endpoint 테스트

### Inngest 작업이 실행되지 않음
- Inngest Event Key 확인
- Inngest Cloud에서 앱 등록 확인
- `/api/inngest` endpoint 접근 가능 여부 확인
