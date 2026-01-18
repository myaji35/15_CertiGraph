# 복사-붙여넣기 전용 설정 가이드

> 각 섹션을 복사해서 Dokploy 화면에 붙여넣기만 하면 됩니다.

---

## 1️⃣ Git Repository 설정

### Repository URL (SSH)
```
git@github.com:myaji35/15_CertiGraph.git
```

### Branch
```
main
```

### Build Path
```
/backend
```

### Dockerfile Path
```
Dockerfile
```

---

## 2️⃣ Build 설정

### Build Type
```
Dockerfile
```

### Build Context
```
/backend
```

---

## 3️⃣ Deploy 설정

### Port
```
8000
```

### Health Check Path
```
/health
```

### Health Check Port
```
8000
```

### Health Check Interval (초)
```
30
```

### Health Check Timeout (초)
```
5
```

### Health Check Retries
```
3
```

---

## 4️⃣ 환경 변수 (Environment Variables)

### 필수 환경 변수
아래 내용을 **한 번에 복사**해서 Environment 탭에 붙여넣기:

```bash
DEV_MODE=false
CLERK_JWKS_URL=https://your-clerk-domain.clerk.accounts.dev/.well-known/jwks.json
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-supabase-service-key
ANTHROPIC_API_KEY=your-anthropic-key
GOOGLE_API_KEY=your-google-key
OPENAI_API_KEY=your-openai-key
UPSTAGE_API_KEY=your-upstage-key
CORS_ORIGINS=https://your-frontend.vercel.app,http://localhost:3000
```

### 선택적 환경 변수 (필요시 추가)
```bash
PINECONE_API_KEY=your-pinecone-key
PINECONE_INDEX_NAME=certigraph-questions
NEO4J_URI=neo4j+s://your-instance.databases.neo4j.io
NEO4J_USER=neo4j
NEO4J_PASSWORD=your-neo4j-password
PLANE_API_KEY=your-plane-key
PLANE_API_URL=http://localhost:8000/api/v1
PLANE_WORKSPACE=testgraph
PLANE_PROJECT_ID=e9f6ed5d-adb5-4e5c-bee6-73e937cf08c4
INNGEST_EVENT_KEY=your-inngest-key
```

---

## 5️⃣ SSH Key (이미 추가됨 ✅)

GitHub Deploy Key가 이미 추가되어 있습니다:
- **Key ID**: 138095262
- **Title**: Dokploy Deploy Key
- **Status**: ✅ Active

**추가 작업 불필요!**

---

## 📋 체크리스트

설정 전:
- [ ] Git 탭 열기
- [ ] Repository URL 복사-붙여넣기
- [ ] Branch, Build Path, Dockerfile 입력
- [ ] Save 클릭

환경 변수:
- [ ] Environment 탭 열기
- [ ] 필수 환경 변수 복사-붙여넣기
- [ ] 실제 API 키로 교체
- [ ] Save 클릭

배포:
- [ ] General 탭 또는 Deploy 탭
- [ ] Port: 8000 확인
- [ ] Health Check 설정 확인
- [ ] **Deploy 버튼 클릭!** 🚀

---

## 🎯 단축 버전 (가장 빠름)

### Git 설정 (한 줄씩 복사)
```
Repository: git@github.com:myaji35/15_CertiGraph.git
Branch: main
Build Path: /backend
Dockerfile: Dockerfile
```

### 환경 변수 (한 번에 복사)
`backend/.env.production` 파일 참조 (실제 키 포함)

### 배포
Port 8000 확인 → Deploy 버튼 클릭!

---

**모든 설정이 준비되었습니다. 복사-붙여넣기만 하면 됩니다!** 🚀
