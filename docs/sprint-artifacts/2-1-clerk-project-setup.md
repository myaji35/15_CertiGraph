# Story 2.1: Clerk Project Setup

## Story
**As a** developer
**I want** Clerk 프로젝트가 설정되어 있길
**So that** 인증 기능을 구현할 수 있다.

## Status
Done

## Acceptance Criteria

```gherkin
Given Clerk 대시보드에 접근할 수 있을 때
When Clerk 프로젝트를 설정하면
Then 다음이 구성된다:
  - 이메일/비밀번호 인증 활성화 ✅
  - Google OAuth 프로바이더 구성 ✅
  - Redirect URLs 설정 (localhost:3000, production URL) ✅
  - 한국어 로케일 설정 ✅

And 환경변수가 설정된다:
  - NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY ✅
  - CLERK_SECRET_KEY ✅
  - NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in ✅
  - NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up ✅
```

## Tasks/Subtasks

- [x] Clerk Dashboard에서 프로젝트 생성
- [x] 이메일/비밀번호 인증 활성화
- [x] Google OAuth 프로바이더 구성
- [x] Redirect URLs 설정
- [x] 환경변수 설정 (frontend/.env, backend/.env)

## Dev Notes

### Technical Notes
- Clerk Dashboard에서 OAuth 설정 완료
- Kakao OAuth는 Phase 2로 연기 (Google만 MVP)
- Clerk Instance: strong-weevil-96.clerk.accounts.dev

### Environment Variables Set
- frontend/.env: NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY, CLERK_SECRET_KEY
- backend/.env: CLERK_JWKS_URL

## Dev Agent Record

### Implementation Plan
Clerk 프로젝트 설정은 사용자가 Clerk Dashboard에서 직접 수행하고, API 키를 제공받아 환경변수에 저장함.

### Debug Log
- N/A (외부 서비스 설정)

### Completion Notes
- 2025-12-20: Clerk API 키 수신 및 환경변수 설정 완료
- frontend/.env 생성 (NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY, CLERK_SECRET_KEY)
- backend/.env 업데이트 (CLERK_JWKS_URL)

## File List

- frontend/.env (created)
- backend/.env (modified)

## Change Log

| Date | Change |
|------|--------|
| 2025-12-20 | Story 완료 - Clerk 환경변수 설정 |

## Estimated Points: 2
