# RAG Estimation Platform — Implementation Plan

## Overview

A software estimation platform powered by AI. The Rails 8 app (`rag-estimation-platform`) is the core product — it handles UI, data persistence, and orchestration. It delegates all AI/RAG work (ingestion, semantic search, estimation) to an existing Python microservice (`rag-estimation-service`) via HTTP. The visual design comes from a React reference app (`project-blueprint-studio`) which has 8 screens with hardcoded data that we replicate in ERB + Tailwind + Hotwire.

**Current state:** Phases 1–8 completed. PostgreSQL, Tailwind dark theme, authentication, 6 models with migrations, all 8 static UI screens, full backend logic with controllers, RAG service integration, Hotwire interactivity, and bug fixes/polish (critical 500-error fixes, nil guards, model validations) are all built. Phase 9 (testing, responsive design, accessibility, print) is pending.

---

## Phase Dependency Graph

```
Phase 1 (Setup)
  └─▸ Phase 2 (Auth)
       └─▸ Phase 3 (Models)
            └─▸ Phase 4 (Static UI)
                 └─▸ Phase 5 (Backend CRUD)
                      └─▸ Phase 6 (RAG Integration)
                           └─▸ Phase 7 (Interactivity)
                                └─▸ Phase 8 (Bug Fixes & Polish)
                                     └─▸ Phase 9 (Testing & Accessibility)
```

Phases 4 & 5 can partially overlap (build a view then wire it up immediately), but the plan sequences them for focused visual QA before introducing data flows.

---

## Phases

| Phase | Title | Status | Dependencies | Detail Doc |
|-------|-------|--------|-------------|------------|
| 1 | Project Setup & Configuration | ✅ Completed | None | [phase-1-setup.md](phases/phase-1-setup.md) |
| 2 | Authentication | ✅ Completed | Phase 1 | [phase-2-auth.md](phases/phase-2-auth.md) |
| 3 | Data Modeling & Migrations | ✅ Completed | Phase 2 | [phase-3-models.md](phases/phase-3-models.md) |
| 4 | Static UI Scaffolding | ✅ Completed | Phases 1, 3 | [phase-4-static-ui.md](phases/phase-4-static-ui.md) |
| 5 | Backend Logic & Controllers | ✅ Completed | Phases 3, 4 | [phase-5-backend.md](phases/phase-5-backend.md) |
| 6 | RAG Service Integration | ✅ Completed | Phase 5 | [phase-6-rag-integration.md](phases/phase-6-rag-integration.md) |
| 7 | Real-Time & Interactive Features | ✅ Completed | Phases 4, 5, 6 | [phase-7-interactivity.md](phases/phase-7-interactivity.md) |
| 8 | Bug Fixes & Polish | ✅ Completed | Phases 1–7 | [phase-8-polish-testing.md](phases/phase-8-polish-testing.md) |
| 9 | Testing, Responsive & Accessibility | ⬚ Pending | Phases 1–8 | [phase-9.md](phases/phase-9.md) |

---

## Key Reference Files

| File | Purpose |
|------|---------|
| `project-blueprint-studio/src/index.css` | Dark theme CSS variables + custom utilities to port |
| `project-blueprint-studio/tailwind.config.ts` | Extended Tailwind theme to replicate |
| `project-blueprint-studio/src/pages/EstimatePage.tsx` (738 lines) | Most complex screen — 3-step wizard |
| `project-blueprint-studio/src/pages/EstimationDetailPage.tsx` (557 lines) | 3-point estimate detail view |
| `project-blueprint-studio/src/pages/LandingPage.tsx` (230 lines) | Marketing landing page |
| `project-blueprint-studio/src/pages/SearchPage.tsx` (132 lines) | Semantic search interface |
| `project-blueprint-studio/src/pages/DocumentsPage.tsx` (113 lines) | Documents table view |
| `project-blueprint-studio/src/pages/IngestPage.tsx` (103 lines) | JSON ingestion page |
| `project-blueprint-studio/src/pages/LoginPage.tsx` (129 lines) | Login/register page |
| `project-blueprint-studio/src/pages/Index.tsx` (177 lines) | Dashboard page |
| `project-blueprint-studio/src/components/AppSidebar.tsx` | Collapsible sidebar navigation |
| `project-blueprint-studio/src/components/AppLayout.tsx` | Sidebar + main content layout |
| `project-blueprint-studio/src/components/PageHeader.tsx` | Reusable page header |
| `project-blueprint-studio/src/components/StatCard.tsx` | Metric stat card component |
| `project-blueprint-studio/src/components/StatusBadge.tsx` | Status badge component |
| `rag-estimation-service/app/api/schemas/quote_input.py` | Ingestion request schema |
| `rag-estimation-service/app/api/schemas/estimate_response.py` | Estimation response with 3-point estimates |
| `rag-estimation-service/app/api/schemas/estimate_request.py` | Estimation request schema |
| `rag-estimation-service/app/api/schemas/search_request.py` | Search request schema |
| `rag-estimation-service/app/api/schemas/search_response.py` | Search results schema |
| `rag-estimation-service/app/api/schemas/ingest_response.py` | Ingest response schemas |
| `rag-estimation-service/app/api/v1/health.py` | Health check endpoint |
| `rag-estimation-service/app/api/v1/ingest.py` | Ingest endpoints |
| `rag-estimation-service/app/api/v1/search.py` | Search endpoint |
| `rag-estimation-service/app/api/v1/estimate.py` | Estimate endpoints |
| `rag-estimation-service/app/api/v1/stats.py` | Stats endpoint |

---

## RAG Service API Contract Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/v1/health` | System health with DB/pgvector latency |
| `POST` | `/api/v1/ingest` | Ingest a quote JSON (max 5MB) |
| `GET` | `/api/v1/ingest/{id}/status` | Check ingestion status |
| `DELETE` | `/api/v1/ingest/{id}` | Delete a document and its chunks |
| `POST` | `/api/v1/search` | Semantic search with filters |
| `POST` | `/api/v1/estimate` | Single estimation request |
| `POST` | `/api/v1/estimate/batch` | Batch estimation (up to 20 queries) |
| `GET` | `/api/v1/stats` | Documents/chunks/search metrics |

**Valid chunk types:** `project_overview`, `scope_block`, `line_item`, `phase`, `team_conditions`

---

## Design System Summary

- **Theme:** Very dark (background 4%), lime-yellow primary (HSL 46 78% 59%)
- **Fonts:** Inter (sans), JetBrains Mono (mono)
- **Custom utilities:** `.glow-sm`, `.glow-md`, `.glass`
- **Custom animation:** `pulse-glow` (2s ease-in-out infinite)
- **Semantic colors:** success (teal), warning (orange), info (blue), destructive (red)
- **Border radius:** 0.625rem base
- **Localization:** Spanish (es-ES)
