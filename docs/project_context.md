---
project_name: 'Certi-Graph'
user_name: 'Q123'
date: '2025-01-04'
sections_completed: ['technology_stack', 'critical_rules']
existing_patterns_found: 25
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- **Frontend:** Next.js 15.5 (App Router), React 19, TypeScript 5.x, Tailwind CSS 3.x, shadcn/ui
- **State Management:** Zustand (Global), TanStack Query (Server)
- **Backend:** FastAPI (Python 3.10+), Pydantic
- **Databases:**
  - Supabase (PostgreSQL) - User/Session data
  - Pinecone - Vector embeddings
  - Neo4j AuraDB - Knowledge Graph
- **Authentication:** Clerk (Frontend components + Backend JWT verification)
- **AI/ML:** Upstage Document Parse, OpenAI GPT-4o, LangChain/LangGraph
- **Infrastructure:** Vercel (Frontend), Railway (Backend), GitHub Actions

## Critical Implementation Rules

### Naming Conventions
- **Database:** snake_case, plural table names (e.g., `users`, `study_sets`)
- **API Endpoints:** kebab-case, plural (e.g., `/api/v1/study-sets`)
- **API Parameters:** snake_case (e.g., `study_set_id`)
- **React Components:** PascalCase (e.g., `StudySetCard.tsx`)
- **Hooks/Utils:** camelCase (e.g., `useStudySets.ts`, `formatDate.ts`)
- **Constants:** SCREAMING_SNAKE_CASE

### Architectural Patterns
1. **Authentication:**
    - Frontend: Use Clerk's `<SignIn />` and `useAuth()`.
    - Backend: Verify Clerk's JWT token in dependencies.
2. **Error Handling:**
    - Use standard error codes: `AUTH_`, `RESOURCE_`, `VALIDATION_`.
    - Backend must return JSON with `error` object.
3. **Data Flow:**
    - Dates: Store as UTC ISO 8601, display in local time.
    - JSON Fields: API uses snake_case, Frontend converts to camelCase (or handles snake_case typings).
4. **State Management:**
    - Use encapsulation pattern for Zustand stores.
    - React Query keys must follow factory pattern (e.g., `queryKeys.studySets.list()`).

### Development Workflow
- **Monorepo Structure:** `frontend/` and `backend/` in root.
- **Testing:** Mirror directory structure in `tests/` or `__tests__/`.
