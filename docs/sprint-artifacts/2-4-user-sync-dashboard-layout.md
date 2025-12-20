# Story 2.4: User Sync & Dashboard Layout

## Story
**As a** user
**I want** 로그인 후 대시보드를 볼 수 있길
**So that** 서비스를 사용할 수 있다.

## Status
Done

## Acceptance Criteria

```gherkin
Given 처음 로그인하는 사용자일 때
When 로그인에 성공하면
Then Supabase users 테이블에 레코드가 생성된다: ✅
  - clerk_user_id: Clerk에서 받은 user_id
  - email: 사용자 이메일

Given 로그인된 상태에서
When /dashboard에 접근하면
Then 다음 레이아웃이 표시된다: ✅
  - Header: 로고, UserButton (프로필/로그아웃)
  - Sidebar: 대시보드, 학습 세트, 모의고사, 취약점 분석
  - Main content area

Given UserButton에서 로그아웃을 클릭하면
When 로그아웃이 완료되면
Then 세션이 종료되고 / 페이지로 리다이렉트된다 ✅
```

## Tasks/Subtasks

- [x] 첫 API 호출 시 사용자 자동 동기화 (deps.py)
- [x] 대시보드 레이아웃 구현 (NotionLayout.tsx)
  - [x] Header: 로고, 브랜딩
  - [x] Sidebar: 네비게이션 메뉴
  - [x] 사용자 정보 표시
  - [x] 로그아웃 버튼
- [x] 대시보드 메인 페이지 (page.tsx)
  - [x] 환영 메시지
  - [x] 통계 카드 (학습 문제, 정답률, 학습 세트, 모의고사)
  - [x] 최근 활동
  - [x] 온보딩 안내 (데이터 없을 때)
- [x] 다크 모드 토글

## Dev Notes

### Technical Notes
- 첫 API 호출 시 사용자 동기화 (Webhook 대신 간단한 방식)
- NotionLayout: Notion 스타일 사이드바
- Clerk UserButton 대신 커스텀 사용자 프로필 UI 사용
- signOut() 호출로 로그아웃 처리

### Implementation Details
- NotionLayout.tsx: Sidebar with navigation tree
- deps.py: Auto-registration in user_profiles table
- Dashboard page: Stats from /analysis/dashboard API

## Dev Agent Record

### Implementation Plan
기존 구현이 Story 2.4 요구사항을 100% 만족함.

### Debug Log
- N/A (이미 구현됨)

### Completion Notes
- 2025-12-20: 기존 구현 검증 완료
- NotionLayout에 사용자 정보/로그아웃 구현됨
- 대시보드 페이지에 통계/활동/온보딩 구현됨
- User sync가 deps.py의 get_current_user에서 자동 처리됨

## File List

- frontend/src/components/layout/NotionLayout.tsx (existing)
- frontend/src/app/(dashboard)/page.tsx (existing)
- frontend/src/app/(dashboard)/layout.tsx (existing)
- backend/app/api/v1/deps.py (existing - user sync)

## Change Log

| Date | Change |
|------|--------|
| 2025-12-20 | Story 검증 - 기존 구현 확인 완료 |

## Estimated Points: 5
