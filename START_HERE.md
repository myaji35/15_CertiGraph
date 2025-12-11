# 🚀 CertiGraph 배포 - 시작 가이드

## ⚡ 원클릭 배포 (가장 빠름!)

```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph
./deploy-now.sh
```

**이 명령 하나로 모든 것이 자동으로 설정됩니다!**

---

## 📋 배포 결과

### 🌐 URL
```
http://testgraph.34.64.143.114.nip.io
```

### ❤️ Health Check
```
http://testgraph.34.64.143.114.nip.io/health
```

### 📚 API 문서
```
http://testgraph.34.64.143.114.nip.io/docs
```

---

## 🎯 스크립트가 자동으로 하는 일

1. ✅ **API 토큰 입력 받기**
2. ✅ **Git 저장소 연결**
   - Repository: git@github.com:myaji35/15_CertiGraph.git
   - Branch: main
   - Build Path: /backend
3. ✅ **빌드 설정**
   - Dockerfile
   - Port 8000
4. ✅ **도메인 추가**
   - testgraph.34.64.143.114.nip.io
5. ✅ **배포 시작**

---

## 📝 실행 전 준비사항

### 1. API 토큰 발급

1. Dokploy 대시보드 접속:
   ```
   http://34.64.143.114:3000
   ```

2. **Settings → API Tokens → Create Token**

3. 토큰 복사

### 2. 스크립트 실행

```bash
./deploy-now.sh
```

프롬프트가 나타나면 토큰 붙여넣기

---

## 🔧 환경 변수 설정 (중요!)

스크립트 실행 후, Dokploy 대시보드에서:

1. **Environment 탭** 클릭

2. 다음 환경 변수 추가:

```bash
DEV_MODE=false
CLERK_JWKS_URL=https://your-clerk-domain.clerk.accounts.dev/.well-known/jwks.json
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-supabase-service-key
ANTHROPIC_API_KEY=your-anthropic-api-key
GOOGLE_API_KEY=your-google-api-key
OPENAI_API_KEY=your-openai-api-key
UPSTAGE_API_KEY=your-upstage-api-key
CORS_ORIGINS=http://testgraph.34.64.143.114.nip.io,https://your-frontend.vercel.app
```

**참고**: 실제 API 키는 `backend/.env.production` 파일을 참조하세요 (로컬에만 존재)

3. **필수 교체 항목**:
   - CLERK_JWKS_URL
   - SUPABASE_URL
   - SUPABASE_SERVICE_KEY
   - OPENAI_API_KEY
   - CORS_ORIGINS (프론트엔드 URL)

4. **Save** 클릭

---

## 📊 배포 확인

### 1. 빌드 로그 모니터링

Dokploy 대시보드 → **Logs** 탭

### 2. Health Check

```bash
curl http://testgraph.34.64.143.114.nip.io/health
```

예상 응답:
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

### 3. API 문서 확인

브라우저에서:
```
http://testgraph.34.64.143.114.nip.io/docs
```

---

## 🐛 트러블슈팅

### 배포 실패 시

1. **환경 변수 확인**
   - Environment 탭에서 모든 필수 변수 설정 확인

2. **빌드 로그 확인**
   - Logs 탭에서 에러 메시지 확인

3. **수동 재배포**
   - General 탭 → **Deploy** 버튼 클릭

### API 토큰 오류

```bash
export DOKPLOY_AUTH_TOKEN="your-new-token"
./deploy-now.sh
```

---

## 📚 추가 문서

- **DOMAIN_SETUP.md** - 도메인 설정 상세 가이드
- **COPY_PASTE_SETUP.md** - UI 복사-붙여넣기 가이드
- **FINAL_SETUP.md** - 3분 완성 가이드
- **backend/.env.production** - 실제 환경 변수 (Git에 커밋 안 됨)

---

## ⚡ 빠른 시작 명령어

```bash
# 1. 스크립트 실행
./deploy-now.sh

# 2. 환경 변수 설정 (대시보드에서)

# 3. 배포 확인
curl http://testgraph.34.64.143.114.nip.io/health
```

---

## 🎉 완료!

모든 설정이 준비되었습니다!

**`./deploy-now.sh` 명령만 실행하세요!** 🚀

---

## 📞 다음 단계

배포 완료 후:

1. ✅ 프론트엔드 환경 변수 업데이트
   ```bash
   NEXT_PUBLIC_API_URL=http://testgraph.34.64.143.114.nip.io
   ```

2. ✅ CORS 설정 확인

3. ✅ 프론트엔드 재배포

4. ✅ 엔드투엔드 테스트

---

**지금 바로 시작하세요!** 🚀
