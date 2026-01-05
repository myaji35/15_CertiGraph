# Dependency Audit Report

**Date:** 2026-01-05
**Project:** CertiGraph (AI 자격증 마스터)

---

## Executive Summary

This report analyzes all project dependencies for security vulnerabilities, outdated packages, and unnecessary bloat. **Critical action required** on 2 high-severity security vulnerabilities.

| Category | Status |
|----------|--------|
| Security Vulnerabilities | 🔴 **4 Critical/High** |
| Outdated Packages | 🟡 12 packages need updates |
| Unused Dependencies | 🟠 6 packages can be removed |

---

## 1. Security Vulnerabilities

### 🔴 CRITICAL - Immediate Action Required

#### Frontend

| Package | Version | CVE | Severity | Description | Fix |
|---------|---------|-----|----------|-------------|-----|
| `next` | 16.0.7 | [GHSA-mwv6-3258-q52c](https://github.com/advisories/GHSA-mwv6-3258-q52c) | **HIGH** (7.5) | DoS with Server Components | Upgrade to **16.0.9+** |
| `next` | 16.0.7 | [GHSA-w37m-7fhw-fmv9](https://github.com/advisories/GHSA-w37m-7fhw-fmv9) | MODERATE (5.3) | Server Actions Source Code Exposure | Upgrade to **16.0.9+** |

#### Backend

| Package | Version Constraint | CVE | Severity | Description | Fix |
|---------|-------------------|-----|----------|-------------|-----|
| `langchain` | >=0.2.0 | [CVE-2025-68664](https://github.com/advisories/GHSA-c67j-w6g6-q2cm) | **CRITICAL** (9.3) | LangGrinch - Secret extraction via serialization injection | Upgrade to **>=0.3.81** or **>=1.2.5** |
| `python-jose` | >=3.3.0 | [CVE-2024-33663](https://nvd.nist.gov/vuln/detail/CVE-2024-33663) | HIGH | Algorithm confusion vulnerability | Upgrade to **>=3.3.1** |
| `python-jose` | >=3.3.0 | [CVE-2024-33664](https://github.com/advisories/GHSA-cjwg-qfpm-7377) | MEDIUM | JWT Bomb DoS attack | Upgrade to **>=3.3.1** |

### 🟡 Known Issues (Lower Priority)

| Package | CVE | Severity | Notes |
|---------|-----|----------|-------|
| `neo4j` | CVE-2024-34517 | MEDIUM | Affects Neo4j Enterprise 5.x < 5.19 (package not actively used) |

---

## 2. Outdated Packages

### Frontend - Update Recommended

| Package | Current | Latest | Priority |
|---------|---------|--------|----------|
| `next` | 16.0.7 | 16.1.1 | 🔴 **Critical** (security) |
| `react` | 19.2.0 | 19.2.3 | 🟡 Medium |
| `react-dom` | 19.2.0 | 19.2.3 | 🟡 Medium |
| `@prisma/client` | 7.1.0 | 7.2.0 | 🟢 Low (unused) |
| `prisma` | 7.1.0 | 7.2.0 | 🟢 Low (unused) |
| `@supabase/supabase-js` | 2.86.2 | 2.89.0 | 🟡 Medium |
| `zod` | 4.1.13 | 4.3.5 | 🟡 Medium |
| `lucide-react` | 0.556.0 | 0.562.0 | 🟢 Low |
| `react-hook-form` | 7.68.0 | 7.70.0 | 🟢 Low |
| `framer-motion` | 12.23.26 | 12.23.27 | 🟢 Low |
| `@clerk/nextjs` | 6.36.0 | 6.36.5 | 🟢 Low |
| `@clerk/localizations` | 3.29.1 | 3.32.1 | 🟢 Low |

### Backend - Update Recommended

| Package | Current Constraint | Recommendation |
|---------|-------------------|----------------|
| `langchain` | >=0.2.0 | Pin to **>=0.3.81** or **>=1.2.5** |
| `python-jose` | >=3.3.0 | Pin to **>=3.3.1** |

---

## 3. Unnecessary Dependencies (Bloat)

### Frontend - Can Be Removed

| Package | Size Impact | Reason |
|---------|-------------|--------|
| `@prisma/client` | ~8MB | Not imported anywhere in codebase |
| `prisma` | ~40MB | Not imported anywhere in codebase |
| `@supabase/ssr` | ~100KB | Not imported (using Clerk for auth) |
| `@supabase/supabase-js` | ~500KB | Not imported in frontend (backend uses Supabase directly) |

**Estimated savings:** ~50MB from node_modules

### Backend - Consider Removal (Planning Dependencies)

| Package | Reason |
|---------|--------|
| `langchain` | Not imported in any Python file - only in requirements.txt |
| `langchain-openai` | Not imported in any Python file |
| `openai` | Not imported directly (using google-generativeai instead) |
| `neo4j` | Marked as "optional for MVP - not used" in config.py |

**Note:** These backend packages appear to be planned for future features. Consider:
- Moving to a separate `requirements-future.txt`
- Or adding comments to clarify their purpose

---

## 4. Recommended Actions

### Immediate (Security)

```bash
# Frontend - Fix Next.js vulnerabilities
cd frontend
npm install next@16.1.1

# Backend - Update requirements.txt
# Change langchain version constraint
langchain>=0.3.81  # or >=1.2.5
python-jose[cryptography]>=3.3.1
```

### Short-term (Cleanup)

```bash
# Frontend - Remove unused Prisma
cd frontend
npm uninstall @prisma/client prisma

# Frontend - Remove unused Supabase (if not needed)
npm uninstall @supabase/ssr @supabase/supabase-js
```

### Medium-term (Optimization)

1. **Separate future dependencies** - Create `requirements-future.txt` for planned features
2. **Add dependency comments** - Document why each dependency exists
3. **Set up automated scanning** - Add `npm audit` and `pip-audit` to CI/CD

---

## 5. Updated Dependency Files

### Recommended `requirements.txt`

```txt
# FastAPI Core
fastapi>=0.115.0
uvicorn[standard]>=0.30.0
pydantic>=2.0.0
pydantic-settings>=2.0.0
python-multipart>=0.0.9

# Database Clients
supabase>=2.0.0
pinecone-client>=3.0.0
# neo4j>=5.0.0  # FUTURE: For knowledge graph feature

# AI/LLM - Active
google-generativeai>=0.3.0

# AI/LLM - Future (uncomment when needed)
# langchain>=0.3.81  # SECURITY: Must be >=0.3.81 for CVE-2025-68664
# langchain-openai>=0.1.0
# openai>=1.0.0

# Utilities
python-dotenv>=1.0.0
python-jose[cryptography]>=3.3.1  # SECURITY: Must be >=3.3.1 for CVE-2024-33663/33664
httpx>=0.27.0
pdfplumber>=0.11.0

# Background Jobs
inngest>=0.3.0

# MLflow for AI/LLM Tracking & Monitoring
mlflow>=2.9.0

# Development
pytest>=8.0.0
pytest-asyncio>=0.23.0
```

### Recommended `package.json` changes

```json
{
  "dependencies": {
    "next": "16.1.1",
    // Remove: "@prisma/client", "@supabase/ssr", "@supabase/supabase-js"
    // Keep: prisma only if needed for schema management
  },
  "devDependencies": {
    // Remove: "prisma" if not using Prisma
  }
}
```

---

## 6. Security Scanning Setup (Recommended)

### GitHub Actions Workflow

```yaml
# .github/workflows/security-scan.yml
name: Security Scan
on:
  push:
    branches: [main]
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Monday

jobs:
  frontend-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd frontend && npm audit --audit-level=high

  backend-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install pip-audit && pip-audit -r backend/requirements.txt
```

---

## Sources

- [GitHub Advisory - Next.js DoS](https://github.com/advisories/GHSA-mwv6-3258-q52c)
- [GitHub Advisory - Next.js Source Code Exposure](https://github.com/advisories/GHSA-w37m-7fhw-fmv9)
- [CVE-2025-68664 - LangChain Critical Vulnerability](https://github.com/advisories/GHSA-c67j-w6g6-q2cm)
- [CVE-2024-33663 - python-jose Algorithm Confusion](https://nvd.nist.gov/vuln/detail/CVE-2024-33663)
- [CVE-2024-33664 - python-jose JWT Bomb](https://github.com/advisories/GHSA-cjwg-qfpm-7377)
- [Neo4j Security Advisories](https://neo4j.com/security/advisories/)
