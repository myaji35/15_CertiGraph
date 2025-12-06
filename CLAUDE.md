# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Certi-Graph** (AI 자격증 마스터) - An AI-powered certification exam study platform that transforms static PDF exam materials into a dynamic learning experience using Knowledge Graph technology to identify and visualize knowledge gaps.

### Project Status
Currently in **Planning/MVP Preparation** stage. No source code exists yet - the project has a PRD (`prd.md`) defining requirements.

## Planned Tech Stack

### Frontend
- Next.js 14+ (App Router)
- React Three Fiber + Drei (3D visualization)
- Zustand (state management)
- Tailwind CSS

### Backend
- Python 3.10+ with FastAPI
- LangChain or LangGraph for orchestration

### Databases
- Pinecone (Vector DB for embeddings)
- Neo4j AuraDB (Graph DB for concepts and learning history)
- PostgreSQL via Supabase (user/payment data)

### AI/ML
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
