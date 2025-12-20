# Story 2.2: Frontend Auth Pages

## Story
**As a** user
**I want** 로그인/회원가입 페이지가 있길
**So that** 계정을 만들고 로그인할 수 있다.

## Status
Done

## Acceptance Criteria

```gherkin
Given 로그인되지 않은 상태에서
When /sign-in 페이지에 접근하면
Then Clerk SignIn 컴포넌트가 표시된다: ✅
  - 이메일/비밀번호 입력 필드
  - "Continue with Google" 버튼
  - "회원가입" 링크

Given 로그인되지 않은 상태에서
When /sign-up 페이지에 접근하면
Then Clerk SignUp 컴포넌트가 표시된다: ✅
  - 이메일/비밀번호 입력 필드
  - "Continue with Google" 버튼
  - "로그인" 링크

Given 인증되지 않은 상태에서
When /dashboard/* 경로에 접근하면
Then /sign-in으로 리다이렉트된다 ✅
```

## Tasks/Subtasks

- [x] Sign-in 페이지 구현 (app/sign-in/[[...sign-in]]/page.tsx)
- [x] Sign-up 페이지 구현 (app/sign-up/[[...sign-up]]/page.tsx)
- [x] Clerk 미들웨어 설정 (proxy.ts)
- [x] ClerkProvider로 root layout 래핑
- [x] 빌드 테스트 통과

## Dev Notes

### Technical Notes
- Clerk 한국어 로케일 적용 (koKR)
- Next.js 16에서는 middleware.ts 대신 proxy.ts 사용
- 보호된 경로: /dashboard/*, /admin/* 등
- 공개 경로: /, /sign-in, /sign-up, /pricing, /api/health

### Implementation
- 기존 proxy.ts를 public route 기반으로 업데이트
- Sign-in/Sign-up 페이지에 브랜딩 및 스타일링 적용

## Dev Agent Record

### Implementation Plan
1. Clerk 미들웨어로 경로 보호 설정
2. Sign-in/Sign-up 페이지 개선
3. 빌드 테스트

### Debug Log
- middleware.ts vs proxy.ts 충돌 → middleware.ts 삭제
- .env.local placeholder → 실제 키로 교체

### Completion Notes
- 2025-12-20: 인증 페이지 구현 완료
- proxy.ts로 경로 보호 설정
- Sign-in/Sign-up 페이지 스타일링 적용
- 빌드 성공 확인

## File List

- frontend/src/proxy.ts (modified)
- frontend/src/app/sign-in/[[...sign-in]]/page.tsx (modified)
- frontend/src/app/sign-up/[[...sign-up]]/page.tsx (modified)
- frontend/.env.local (modified)

## Change Log

| Date | Change |
|------|--------|
| 2025-12-20 | Story 완료 - 인증 페이지 및 미들웨어 구현 |

## Estimated Points: 3
