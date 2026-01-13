# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Certi-Graph** (AI 자격증 마스터) - An AI-powered certification exam study platform that transforms static PDF exam materials into a dynamic learning experience using Knowledge Graph technology to identify and visualize knowledge gaps.

### Project Status
Currently in **Planning/MVP Preparation** stage. No source code exists yet - the project has a PRD (`prd.md`) defining requirements.

## Planned Tech Stack

### Frontend (Rails-integrated)
- Rails 8.0+ with Turbo & Stimulus
- Three.js via importmap (3D visualization)
- Tailwind CSS v3 (tailwindcss-rails ~> 2.0)
- Stimulus controllers with fallback patterns

### Backend
- Ruby 3.3.0+ with Rails 8.0+
- Sidekiq or Solid Queue (background jobs)
- Active Storage with Direct Upload
- Service Objects for business logic

### Databases
- PostgreSQL with pgvector extension (embeddings)
- Neo4j AuraDB via REST API (Graph DB)
- Solid Cache or Redis (caching)

### AI/ML (via API)
- Upstage Document Parse (OCR)
- OpenAI GPT-4o / GPT-4o-mini (reasoning)
- OpenAI text-embedding-3-small (embeddings)

## BMad Method (BMM) Framework

This project uses the BMad Method for structured development. Access workflows via slash commands:

### Key Agents
- `/bmad:bmm:agents:pm` - Project Manager
- `/bmad:bmm:agents:architect` - Architect
- `/bmad:bmm:agents:dev` - Developer
- `/bmad:bmm:agents:analyst` - Business Analyst
- `/bmad:bmm:agents:ux-designer` - UX Designer

### Key Workflows
- `/bmad:bmm:workflows:workflow-init` - Initialize project workflow
- `/bmad:bmm:workflows:create-epics-and-stories` - Break PRD into stories
- `/bmad:bmm:workflows:create-tech-spec` - Create technical specifications
- `/bmad:bmm:workflows:sprint-planning` - Generate sprint tracking
- `/bmad:bmm:workflows:dev-story` - Execute story implementation
- `/bmad:bmm:workflows:code-review` - Adversarial code review

### Workflow Status
- `/bmad:bmm:workflows:workflow-status` - Check current progress
- `/bmad:core:agents:bmad-master` - Master orchestration agent

## Core Domain Concepts

### Data Ingestion Pipeline
- PDF upload → Upstage OCR → Markdown conversion
- Image handling: crop + GPT-4o captioning
- Intelligent chunking with "지문 복제" (passage replication) for multi-question contexts

### Knowledge Graph
- Ontology: Subject → Chapter → Key Concept
- LLM extracts concepts and prerequisite relationships from questions
- Used for GraphRAG-based weakness analysis

### Test Engine
- Answer option randomization (anti-memorization)
- GraphRAG reasoning for error analysis
- Distinguishes concept gaps vs careless mistakes

### Visualization
- 3D brain map with React Three Fiber
- Node colors: Green (mastered), Red (weak), Gray (untested)
- Click-to-drill feature for focused practice

## Sprint Artifacts

Development artifacts are stored in `docs/sprint-artifacts/`.

## 코드 수정 프로토콜 (엄격 모드)

**모든 코드 수정 후 아래 절차를 반드시 수행:**

1. `cat [수정한 파일]` 로 변경사항 저장 확인
2. 관련 캐시 디렉토리 전체 삭제
3. 실행 중인 관련 프로세스 모두 종료 (`pkill -f` 또는 `lsof -i:[포트]`)
4. 클린 빌드 실행
5. 서버 새로 시작
6. 테스트 실행

**절대 하지 말 것:**
- 파일 수정 후 바로 "수정 완료"라고 보고하지 말 것
- 캐시 클리어 없이 테스트하지 말 것
- 이전 프로세스가 실행 중인 상태에서 테스트하지 말 것
