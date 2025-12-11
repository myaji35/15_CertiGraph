# 🚀 원클릭 Dokploy 배포 가이드

> 이미 설정이 완료된 항목들이 많아 5분 안에 배포 가능합니다!

## ✅ 이미 완료된 작업

- ✅ GitHub 저장소: `git@github.com:myaji35/15_CertiGraph.git`
- ✅ Deploy Key 추가됨 (Dokploy가 저장소 접근 가능)
- ✅ 최신 코드 푸시됨 (Inngest + Plane 통합)
- ✅ Dockerfile 준비됨
- ✅ 애플리케이션 생성됨 (ID: `4sc-UR-ll0dwt7DtoBECo`)

## 🎯 3단계로 배포 완료

### 1단계: 대시보드 접속 (30초)

브라우저에서 열기:
```
http://34.64.143.114:3000/dashboard/project/SVSYksCZ8lAr2Mdrg8902/environment/jn2nZM3RYvYrTczdn4Tdl/services/application/4sc-UR-ll0dwt7DtoBECo
```

### 2단계: Git 설정 (1분)

**Git 탭으로 이동:**

1. **Repository Type**: SSH
2. **Repository URL**: `git@github.com:myaji35/15_CertiGraph.git`
3. **Branch**: `main`
4. **Build Path**: `/backend`
5. **Dockerfile Path**: `Dockerfile`
6. **Save** 클릭

### 3단계: 환경 변수 설정 (2분)

**Environment 탭으로 이동:**

복사해서 붙여넣기 (파일: `backend/.env.production`):

```bash
DEV_MODE=false
CLERK_JWKS_URL=https://your-clerk-domain.clerk.accounts.dev/.well-known/jwks.json
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key
GOOGLE_API_KEY=your-google-api-key
OPENAI_API_KEY=your-openai-key
UPSTAGE_API_KEY=your-upstage-key
CORS_ORIGINS=https://your-frontend.vercel.app
```

**참고**: 실제 API 키는 `backend/.env.production` 파일을 참조하세요 (Git에 커밋되지 않음)

**중요**: 프로덕션 값으로 교체:
- `CLERK_JWKS_URL`: 실제 Clerk 도메인
- `SUPABASE_URL`: 실제 Supabase 프로젝트 URL
- `SUPABASE_SERVICE_KEY`: 실제 서비스 키
- `OPENAI_API_KEY`: 실제 OpenAI 키
- `CORS_ORIGINS`: 실제 프론트엔드 도메인

### 4단계: 빌드 설정 확인 (30초)

**Settings 탭:**

- **Port**: `8000` ✓
- **Health Check Path**: `/health` ✓
- **Health Check Port**: `8000` ✓

### 5단계: 배포! 🚀 (1클릭)

**General 탭:**
1. **"Deploy" 버튼** 클릭
2. 빌드 로그 모니터링
3. 배포 완료 대기 (2-3분)

---

## 📊 배포 확인

### Health Check
```bash
curl http://YOUR_DEPLOYMENT_URL/health
```

예상 응답:
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

### API 문서
```
http://YOUR_DEPLOYMENT_URL/docs
```

---

## 🔧 설정 세부사항

### Git 설정
```json
{
  "repository": "git@github.com:myaji35/15_CertiGraph.git",
  "branch": "main",
  "buildPath": "/backend",
  "dockerfile": "Dockerfile"
}
```

### 필수 환경 변수
| 변수 | 설명 | 상태 |
|------|------|------|
| DEV_MODE | 개발 모드 (false로 설정) | ⚠️ 필수 |
| CLERK_JWKS_URL | Clerk JWT 검증 URL | ⚠️ 필수 |
| SUPABASE_URL | Supabase 프로젝트 URL | ⚠️ 필수 |
| SUPABASE_SERVICE_KEY | Supabase 서비스 키 | ⚠️ 필수 |
| ANTHROPIC_API_KEY | Claude API 키 | ⚠️ 필수 |
| GOOGLE_API_KEY | Gemini API 키 | ⚠️ 필수 |
| OPENAI_API_KEY | OpenAI API 키 | ⚠️ 필수 |
| UPSTAGE_API_KEY | Upstage OCR 키 | ⚠️ 필수 |
| CORS_ORIGINS | 허용할 프론트엔드 도메인 | ⚠️ 필수 |

### 선택적 환경 변수
```bash
# Pinecone (Vector DB)
PINECONE_API_KEY=your-key
PINECONE_INDEX_NAME=certigraph-questions

# Neo4j (Graph DB)
NEO4J_URI=neo4j+s://your-instance.databases.neo4j.io
NEO4J_USER=neo4j
NEO4J_PASSWORD=your-password

# Plane (프로젝트 관리)
PLANE_API_KEY=your-plane-key
PLANE_WORKSPACE=testgraph
PLANE_PROJECT_ID=e9f6ed5d-adb5-4e5c-bee6-73e937cf08c4

# Inngest (백그라운드 작업)
INNGEST_EVENT_KEY=your-inngest-key
```

---

## 🎯 배포 체크리스트

배포 전:
- [ ] Clerk JWKS URL 설정
- [ ] Supabase URL + Service Key 설정
- [ ] OpenAI API 키 교체
- [ ] CORS origins를 실제 프론트엔드 도메인으로 변경
- [ ] DEV_MODE=false 설정

배포 중:
- [ ] Git 연동 확인
- [ ] 빌드 로그에서 에러 확인
- [ ] 환경 변수 로드 확인

배포 후:
- [ ] Health check 응답 확인
- [ ] API 문서 접근 확인 (/docs)
- [ ] 프론트엔드 연동 테스트

---

## 🐛 트러블슈팅

### 빌드 실패
```bash
# 로그 확인
Dokploy 대시보드 → Logs 탭

# 일반적인 원인:
- Dockerfile 경로 오류 → Build Path: /backend 확인
- 의존성 설치 실패 → requirements.txt 확인
```

### 런타임 에러
```bash
# 환경 변수 확인
대시보드 → Environment 탭

# 일반적인 원인:
- DEV_MODE=true (프로덕션에서는 false)
- API 키 누락
- CORS 설정 오류
```

### 헬스체크 실패
```bash
# Port 확인
Settings → Port: 8000
Settings → Health Check: /health

# 앱이 8000 포트에서 실행 중인지 확인
```

---

## 📚 관련 문서

- **상세 배포 가이드**: `DOKPLOY_SETUP.md`
- **백엔드 설정**: `backend/DEPLOYMENT.md`
- **CLI 사용법**: `DEPLOY_INSTRUCTIONS.md`
- **프로덕션 환경변수**: `backend/.env.production`

---

## 🔗 유용한 링크

- **Dokploy 대시보드**: http://34.64.143.114:3000
- **애플리케이션 직접 링크**: [여기 클릭](http://34.64.143.114:3000/dashboard/project/SVSYksCZ8lAr2Mdrg8902/environment/jn2nZM3RYvYrTczdn4Tdl/services/application/4sc-UR-ll0dwt7DtoBECo)
- **GitHub 저장소**: https://github.com/myaji35/15_CertiGraph

---

**준비 완료! 대시보드에서 Deploy 버튼만 누르면 됩니다!** 🚀
