# Story 1.1: Frontend Project Initialization

**Status:** ready-for-dev

## Story

**As a** developer,
**I want** Next.js 프로젝트가 초기화되어 있길,
**So that** 프론트엔드 기능 개발을 시작할 수 있다.

## Acceptance Criteria

### AC1: Project Structure
```gherkin
Given 개발 환경이 준비되어 있을 때
When 프론트엔드 프로젝트를 초기화하면
Then 다음 구조가 생성된다:
  - frontend/src/app/ (App Router)
  - frontend/src/components/ui/ (shadcn/ui)
  - frontend/src/lib/ (utilities)
  - frontend/src/stores/ (Zustand)
  - frontend/src/types/ (TypeScript types)
```

### AC2: Package Installation
```gherkin
Given 프로젝트가 초기화되면
When package.json을 확인하면
Then 다음 패키지가 설치되어 있다:
  - next: ^15.x
  - react: ^19.x
  - typescript: ^5.x
  - tailwindcss: ^3.x
  - zustand: latest
  - @tanstack/react-query: latest
  - shadcn/ui components (button, card, input, dialog)
```

### AC3: Development Server
```gherkin
Given 모든 의존성이 설치되었을 때
When npm run dev를 실행하면
Then localhost:3000에서 Next.js 앱이 정상 동작한다
And 콘솔에 에러가 없다
```

### AC4: Environment Configuration
```gherkin
Given 프로젝트가 초기화되면
When 환경 파일을 확인하면
Then .env.example 파일이 존재한다
And 필요한 환경변수 템플릿이 포함되어 있다
```

## Tasks / Subtasks

- [ ] Task 1: Create Next.js Project (AC: 1, 2)
  - [ ] 1.1: Run create-next-app with specified options
  - [ ] 1.2: Verify project structure created correctly
  - [ ] 1.3: Test initial npm run dev works

- [ ] Task 2: Install Additional Dependencies (AC: 2)
  - [ ] 2.1: Install Zustand for state management
  - [ ] 2.2: Install TanStack Query for server state
  - [ ] 2.3: Verify package.json has all dependencies

- [ ] Task 3: Setup shadcn/ui (AC: 1, 2)
  - [ ] 3.1: Initialize shadcn/ui with CLI
  - [ ] 3.2: Install core components (button, card, input, dialog, form)
  - [ ] 3.3: Verify components in src/components/ui/

- [ ] Task 4: Create Project Structure (AC: 1)
  - [ ] 4.1: Create src/lib/ directory with utils.ts
  - [ ] 4.2: Create src/stores/ directory with placeholder
  - [ ] 4.3: Create src/types/ directory with index.ts

- [ ] Task 5: Environment Setup (AC: 4)
  - [ ] 5.1: Create .env.example with required variables
  - [ ] 5.2: Create .env.local from example (gitignored)
  - [ ] 5.3: Update .gitignore if needed

- [ ] Task 6: Final Verification (AC: 3)
  - [ ] 6.1: Run npm run dev and verify no errors
  - [ ] 6.2: Run npm run build to check for build errors
  - [ ] 6.3: Run npm run lint to verify code quality

## Dev Notes

### Architecture Requirements
[Source: docs/architecture.md#Frontend]

**Tech Stack:**
- Framework: Next.js 15.x (App Router)
- Language: TypeScript 5.x
- Styling: Tailwind CSS 3.x
- State Management: Zustand (global) + TanStack Query (server state)
- UI Components: shadcn/ui
- Build: Turbopack (dev), Webpack (production)

**Initialization Command:**
```bash
npx create-next-app@latest frontend \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*"
```

### Project Structure Notes
[Source: docs/architecture.md#Project-Structure]

Target directory structure:
```
frontend/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── components/
│   │   └── ui/                 # shadcn/ui components
│   ├── lib/
│   │   └── utils.ts            # Utility functions
│   ├── stores/                 # Zustand stores
│   │   └── .gitkeep
│   └── types/                  # TypeScript types
│       └── index.ts
├── public/
├── .env.example
├── .env.local                  # gitignored
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

### shadcn/ui Setup
```bash
# Initialize shadcn/ui
npx shadcn@latest init

# Install core components
npx shadcn@latest add button card input dialog form label
```

### Environment Variables Template
```env
# .env.example
# Clerk Authentication
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up

# API
NEXT_PUBLIC_API_URL=http://localhost:8000

# Supabase (DB only, no auth)
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

### Testing Standards
- No unit tests required for this initialization story
- Manual verification: dev server runs without errors
- Build verification: `npm run build` succeeds

### References

- [Architecture: Frontend Starter](docs/architecture.md#Selected-Starters)
- [Architecture: Frontend Directory Structure](docs/architecture.md#Frontend-디렉토리-구조)
- [Architecture: Naming Patterns](docs/architecture.md#Naming-Patterns)
- [Epic 1: Project Foundation](docs/epics.md#Epic-1-Project-Foundation)

## Dev Agent Record

### Context Reference
- Story created by create-story workflow
- Epic 1, Story 1 - First story in the project

### Agent Model Used
<!-- Will be filled by dev agent -->

### Debug Log References
<!-- Will be filled by dev agent -->

### Completion Notes List
<!-- Will be filled by dev agent -->

### File List
<!-- Will be filled by dev agent with all created/modified files -->

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-12-18 | Story created with comprehensive context | create-story workflow |
