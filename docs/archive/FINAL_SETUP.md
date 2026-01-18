# ⚡ 최종 배포 가이드 - 3분 완성

## 🎯 Dokploy 화면에서 3단계만 복사-붙여넣기

---

## 1단계: Git 설정 ✅

Dokploy 화면에서 뒤로가기 → 애플리케이션 설정으로 이동

**Repository** 필드에 복사-붙여넣기:
```
git@github.com:myaji35/15_CertiGraph.git
```

**Branch** 필드에 복사-붙여넣기:
```
main
```

**Build Path** 필드에 복사-붙여넣기:
```
/backend
```

**Dockerfile** 필드에 복사-붙여넣기:
```
Dockerfile
```

**→ Save 클릭**

---

## 2단계: 환경 변수 설정 ✅

**Environment 탭**으로 이동

아래 전체를 복사해서 붙여넣기:

```
DEV_MODE=false
CLERK_JWKS_URL=https://your-clerk-domain.clerk.accounts.dev/.well-known/jwks.json
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-supabase-service-key
ANTHROPIC_API_KEY=your-anthropic-key
GOOGLE_API_KEY=your-google-key
OPENAI_API_KEY=your-openai-key
UPSTAGE_API_KEY=your-upstage-key
CORS_ORIGINS=https://your-frontend.vercel.app
```

**실제 값으로 교체** (backend/.env.production 파일 참조)

**→ Save 클릭**

---

## 3단계: 배포 🚀

**General** 또는 **Deploy** 탭으로 이동

**Port 확인**: 8000

**Health Check 확인**: /health

**→ Deploy 버튼 클릭!**

---

## ✅ 완료!

배포 로그를 보면서 대기 (2-3분)

배포 완료 후:
```bash
curl http://YOUR_DOMAIN/health
```

---

## 📱 빠른 참조

- **Repository**: `git@github.com:myaji35/15_CertiGraph.git`
- **Branch**: `main`
- **Build Path**: `/backend`
- **Dockerfile**: `Dockerfile`
- **Port**: `8000`
- **Health Check**: `/health`
- **환경 변수**: `backend/.env.production` 참조

---

## 🤖 자동 배포 (선택사항)

API 토큰이 있다면 터미널에서:

```bash
export DOKPLOY_AUTH_TOKEN="your-token"
./auto-deploy-dokploy.sh
```

모든 설정이 자동으로 완료됩니다!

---

**이제 Dokploy 화면에서 복사-붙여넣기만 하세요!** 🚀
