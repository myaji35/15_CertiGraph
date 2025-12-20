# Story 2.3: Backend JWT Verification

## Story
**As a** backend service
**I want** Clerk JWT를 검증할 수 있길
**So that** 인증된 사용자만 API에 접근하도록 할 수 있다.

## Status
Done

## Acceptance Criteria

```gherkin
Given Authorization 헤더가 없는 요청이 들어올 때
When 보호된 엔드포인트에 접근하면
Then HTTP 401 반환: ✅
  {
    "error": {
      "code": "AUTH_MISSING_TOKEN",
      "message": "인증 토큰이 필요합니다."
    }
  }

Given 유효하지 않은 JWT가 포함된 요청이 들어올 때
When 보호된 엔드포인트에 접근하면
Then HTTP 401 반환: ✅
  {
    "error": {
      "code": "AUTH_INVALID_TOKEN",
      "message": "유효하지 않은 인증 토큰입니다."
    }
  }

Given 유효한 Clerk JWT가 포함된 요청이 들어올 때
When 보호된 엔드포인트에 접근하면
Then 요청이 정상 처리되고 current_user가 주입된다 ✅
```

## Tasks/Subtasks

- [x] python-jose로 JWT 검증 구현 (app/core/security.py)
- [x] Clerk JWKS URL에서 공개키 가져오기
- [x] JWKS 캐싱 (1시간 TTL)
- [x] get_current_user 의존성 구현 (app/api/v1/deps.py)
- [x] 에러 응답 형식 구현 (app/core/exceptions.py)
- [x] DEV_MODE 우회 기능

## Dev Notes

### Technical Notes
- python-jose로 JWT 검증 (RS256)
- Clerk JWKS URL에서 공개키 가져오기
- JWKS 1시간 캐싱으로 성능 최적화
- DEV_MODE=true 시 인증 우회 (개발용)

### Implementation Details
- `security.py`: verify_clerk_token(), get_jwks(), ClerkUser 클래스
- `deps.py`: get_current_user(), CurrentUser type alias
- `exceptions.py`: AuthMissingTokenError, AuthInvalidTokenError, AuthExpiredTokenError

## Dev Agent Record

### Implementation Plan
기존 구현이 Story 2.3 요구사항을 100% 만족함.

### Debug Log
- N/A (이미 구현됨)

### Completion Notes
- 2025-12-20: 기존 구현 검증 완료
- security.py에 JWKS 캐싱 및 JWT 검증 구현됨
- deps.py에 get_current_user 의존성 구현됨
- exceptions.py에 적절한 에러 응답 구현됨

## File List

- backend/app/core/security.py (existing)
- backend/app/api/v1/deps.py (existing)
- backend/app/core/exceptions.py (existing)
- backend/app/core/config.py (existing)

## Change Log

| Date | Change |
|------|--------|
| 2025-12-20 | Story 검증 - 기존 구현 확인 완료 |

## Estimated Points: 5
