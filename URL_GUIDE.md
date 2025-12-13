# ExamsGraph URL 접속 가이드

## 🌐 새로운 URL 구조 (nip.io 활용)

ExamsGraph는 이제 서브도메인 기반의 깔끔한 URL을 사용합니다.
`.nip.io` 서비스를 활용하여 IP 주소를 도메인처럼 사용할 수 있습니다.

### 📍 메인 접속 URL

| 서비스 | URL | 설명 |
|--------|-----|------|
| **메인 앱** | http://examsgraph.34.64.191.91.nip.io | ExamsGraph 메인 애플리케이션 |
| **API** | http://api.examsgraph.34.64.191.91.nip.io | 백엔드 API 서버 |
| **관리자** | http://admin.examsgraph.34.64.191.91.nip.io | Dokploy 관리 대시보드 |

### 🎯 주요 페이지 직접 접속

- **홈**: http://examsgraph.34.64.191.91.nip.io
- **대시보드**: http://examsgraph.34.64.191.91.nip.io/dashboard
- **문제집**: http://examsgraph.34.64.191.91.nip.io/dashboard/study-sets
- **시험 일정**: http://examsgraph.34.64.191.91.nip.io/dashboard/certifications
- **자격증 검색**: http://examsgraph.34.64.191.91.nip.io/dashboard/certifications/search
- **학습 자료**: http://examsgraph.34.64.191.91.nip.io/dashboard/study-materials

### 💡 nip.io란?

`nip.io`는 무료 DNS 서비스로, IP 주소를 도메인 형식으로 변환해줍니다.
- `examsgraph.34.64.191.91.nip.io` → `34.64.191.91`로 자동 해석
- 별도의 DNS 설정 불필요
- 서브도메인 사용 가능 (api., admin. 등)

### 🔧 기존 URL (직접 IP 접속)

nip.io가 작동하지 않을 경우 기존 URL도 사용 가능합니다:
- Frontend: http://34.64.191.91:3000
- Backend API: http://34.64.191.91:8000
- Dokploy Admin: http://34.64.143.114:3000

### 📱 모바일 접속

모바일 브라우저에서도 동일한 URL로 접속 가능합니다:
```
http://examsgraph.34.64.191.91.nip.io
```

### 🚀 로컬 개발 환경

개발 중인 로컬 서버:
- Frontend: http://localhost:3030
- Backend: http://localhost:8000

### 🔐 HTTPS 설정 (추후)

추후 SSL 인증서 적용 시:
- https://examsgraph.34.64.191.91.nip.io
- https://api.examsgraph.34.64.191.91.nip.io

---

## 환경 변수 업데이트

`.env` 파일에 다음과 같이 설정하세요:

```env
# Frontend URLs
NEXT_PUBLIC_APP_URL=http://examsgraph.34.64.191.91.nip.io
NEXT_PUBLIC_API_URL=http://api.examsgraph.34.64.191.91.nip.io

# Backend CORS
CORS_ORIGINS=["http://examsgraph.34.64.191.91.nip.io","http://localhost:3030"]
```