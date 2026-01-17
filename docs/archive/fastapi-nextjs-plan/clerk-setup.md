# Clerk 설정 가이드

## 1. Clerk 프로젝트 생성

1. [clerk.com](https://clerk.com)에 접속하여 계정 생성
2. "Create application" 클릭
3. Application name: `CertiGraph`
4. 인증 방법 선택:
   - ✅ Email
   - ✅ Google
   - ✅ Kakao (선택사항)

## 2. 환경변수 복사

Clerk 대시보드 → API Keys 에서 복사:

```bash
# Frontend (.env.local)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxx
CLERK_SECRET_KEY=sk_test_xxxxx
```

## 3. Redirect URLs 설정

Clerk 대시보드 → Paths 에서 설정:

| 설정 | 값 |
|------|-----|
| Sign-in URL | `/sign-in` |
| Sign-up URL | `/sign-up` |
| After sign-in URL | `/dashboard` |
| After sign-up URL | `/dashboard` |

## 4. OAuth 설정 (Google)

Clerk 대시보드 → SSO Connections → Google:

1. Google Cloud Console에서 OAuth 2.0 클라이언트 생성
2. Authorized redirect URI: Clerk에서 제공하는 URL 복사
3. Client ID와 Secret을 Clerk에 입력

## 5. JWKS URL 확인 (백엔드용)

Clerk 대시보드에서 JWKS URL 확인:
```
https://{your-clerk-domain}.clerk.accounts.dev/.well-known/jwks.json
```

이 URL을 백엔드 `.env`의 `CLERK_JWKS_URL`에 설정

## 6. 한국어 설정 (선택사항)

Clerk 대시보드 → Customization → Localization:
- Primary language: Korean
