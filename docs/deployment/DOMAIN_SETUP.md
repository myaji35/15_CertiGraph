# 🌐 Dokploy 도메인 설정 가이드

## 🎯 목표 도메인
```
http://testgraph.34.64.143.114.nip.io
```

**nip.io란?**
- Wildcard DNS 서비스
- DNS 설정 없이 즉시 사용 가능
- `*.34.64.143.114.nip.io` → `34.64.143.114`로 자동 연결

---

## 🚀 방법 1: 자동 스크립트 (권장)

### 1단계: API 토큰 설정
```bash
export DOKPLOY_AUTH_TOKEN="your-api-token"
```

### 2단계: 스크립트 실행
```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph
./setup-domain.sh
```

스크립트가 자동으로:
- ✅ Git 저장소 설정
- ✅ 빌드 설정 (Dockerfile, Port 8000)
- ✅ 도메인 추가 (testgraph.34.64.143.114.nip.io)
- ✅ 환경 변수 안내

---

## 🖱️ 방법 2: Dokploy UI에서 수동 설정

### 1단계: Domains 탭으로 이동

Dokploy 대시보드 → 애플리케이션 → **Domains** 탭

### 2단계: Add Domain 클릭

### 3단계: 도메인 정보 입력

**Host:**
```
testgraph.34.64.143.114.nip.io
```

**Path:**
```
/
```

**Port:**
```
8000
```

**HTTPS:**
```
☐ (체크 안 함 - HTTP만 사용)
```

### 4단계: Save 클릭

---

## 📋 대체 도메인 옵션

### Option 1: nip.io (추천)
```
testgraph.34.64.143.114.nip.io
```
- DNS 설정 불필요
- 즉시 사용 가능

### Option 2: sslip.io
```
testgraph.34.64.143.114.sslip.io
```
- nip.io와 동일한 서비스

### Option 3: IP만 사용
```
http://34.64.143.114:8000
```
- 포트 번호 필요
- 도메인 이름 없음

### Option 4: 커스텀 도메인
```
api.certigraph.com
```
- DNS A 레코드: 34.64.143.114
- SSL 인증서 자동 발급 가능

---

## 🔧 도메인 설정 후 확인

### Health Check
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

### API 문서
```
http://testgraph.34.64.143.114.nip.io/docs
```

---

## 🎨 프론트엔드 연동

프론트엔드 환경 변수:
```bash
NEXT_PUBLIC_API_URL=http://testgraph.34.64.143.114.nip.io
```

CORS 설정 (백엔드 환경 변수):
```bash
CORS_ORIGINS=https://your-frontend.vercel.app,http://localhost:3000,http://testgraph.34.64.143.114.nip.io
```

---

## ⚡ 빠른 설정 명령어

```bash
# 1. 토큰 설정
export DOKPLOY_AUTH_TOKEN="your-token"
export DOKPLOY_URL="http://34.64.143.114:3000"

# 2. 인증 확인
dokploy verify

# 3. 도메인 설정 스크립트 실행
./setup-domain.sh

# 4. 배포 확인
curl http://testgraph.34.64.143.114.nip.io/health
```

---

## 🔐 HTTPS 설정 (선택사항)

nip.io는 기본적으로 HTTP만 지원합니다.

HTTPS가 필요하다면:
1. **커스텀 도메인** 사용
2. Dokploy에서 **Let's Encrypt 자동 SSL** 활성화
3. DNS A 레코드 설정

---

## 📊 설정 요약

| 항목 | 값 |
|------|-----|
| 도메인 | testgraph.34.64.143.114.nip.io |
| 프로토콜 | HTTP |
| 포트 | 8000 (내부), 80 (외부) |
| Health Check | /health |
| API Docs | /docs |
| CORS | 프론트엔드 도메인 추가 필요 |

---

**준비 완료! 스크립트를 실행하거나 UI에서 도메인을 추가하세요!** 🚀
