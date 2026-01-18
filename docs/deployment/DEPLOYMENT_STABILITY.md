# 🚀 ExamsGraph 안정적 배포 가이드

## 📌 현재 상황 진단

### 문제점
1. **다중 플랫폼 설정** - Dokploy, Coolify, Vercel 설정 혼재
2. **환경 변수 혼란** - 여러 .env 파일, 일관성 없음
3. **자동 배포 부재** - GitHub webhook 미설정
4. **빌드 에러 빈발** - TypeScript/ESLint 에러

## ✅ 근본적 해결 방안

### 1. 단일 플랫폼 선택
**권장: Vercel (Frontend) + Railway/Render (Backend)**

이유:
- Vercel: Next.js 공식 플랫폼, 자동 배포, 무료 티어
- Railway/Render: 간단한 백엔드 배포, 자동 SSL

### 2. 환경 변수 통합 관리

```bash
# .env.example (템플릿)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
DATABASE_URL=
NEXT_PUBLIC_API_URL=

# .env.local (로컬 개발)
# 실제 개발 값

# .env.production (배포용)
# 플랫폼에서 직접 설정
```

### 3. 프로젝트 구조 개선

```
옵션 A: Monorepo (권장)
/
├── apps/
│   ├── web/          # Next.js frontend
│   └── api/          # FastAPI backend
├── packages/         # 공유 코드
├── turbo.json       # Turborepo 설정
└── package.json

옵션 B: 분리 배포
- Frontend: 별도 리포지토리 → Vercel
- Backend: 별도 리포지토리 → Railway
```

## 🎯 즉시 실행 가능한 안정화 방안

### Step 1: Vercel 배포 (Frontend)

```bash
# 1. Vercel CLI 설치
npm i -g vercel

# 2. Frontend 디렉토리에서
cd frontend
vercel

# 3. 환경 변수 설정 (Vercel 대시보드)
# Settings → Environment Variables
```

### Step 2: 환경 변수 정리

```typescript
// utils/config.ts
export const config = {
  api: {
    url: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'
  },
  clerk: {
    publishableKey: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY || ''
  }
}
```

### Step 3: 빌드 안정화

```typescript
// next.config.ts
const nextConfig = {
  // 개발 중에만 에러 무시
  typescript: {
    ignoreBuildErrors: process.env.NODE_ENV === 'development'
  },
  eslint: {
    ignoreDuringBuilds: process.env.NODE_ENV === 'development'
  }
}
```

## 📊 배포 체크리스트

### 배포 전
- [ ] 환경 변수 확인
- [ ] 로컬 빌드 테스트 (`npm run build`)
- [ ] TypeScript 에러 해결
- [ ] 불필요한 console.log 제거

### 배포 설정
- [ ] 자동 배포 설정 (GitHub 연동)
- [ ] 환경 변수 설정
- [ ] 도메인 설정 (옵션)
- [ ] SSL 인증서

### 배포 후
- [ ] 헬스 체크
- [ ] 기능 테스트
- [ ] 에러 모니터링
- [ ] 성능 확인

## 🔧 현재 Dokploy 임시 안정화

만약 Dokploy를 계속 사용한다면:

### 1. 자동 배포 설정
```bash
# Dokploy 대시보드에서
1. Settings → GitHub Integration
2. Enable Auto Deploy
3. Set Branch: main
4. Save
```

### 2. 환경 변수 통합
```bash
# Dokploy 대시보드에서 모든 환경 변수 설정
# 로컬 .env 파일은 .gitignore에 추가
```

### 3. Docker 최적화
```dockerfile
# multi-stage build로 크기 최소화
# 캐싱 활용으로 빌드 시간 단축
```

## 💡 장기적 권장사항

1. **CI/CD 파이프라인 구축**
   - GitHub Actions 활용
   - 자동 테스트
   - 자동 배포

2. **모니터링 도입**
   - Sentry (에러 추적)
   - Vercel Analytics (성능)
   - Uptime monitoring

3. **인프라 코드화 (IaC)**
   - Terraform 또는
   - Docker Compose 표준화

---

## 결론

**즉시 조치:**
1. Vercel로 Frontend 마이그레이션
2. 환경 변수 정리 및 통합
3. 자동 배포 설정

**중기 목표:**
1. Backend 분리 배포
2. CI/CD 파이프라인
3. 모니터링 시스템

이렇게 하면 안정적이고 예측 가능한 배포 환경을 구축할 수 있습니다.