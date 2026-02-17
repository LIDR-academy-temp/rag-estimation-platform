# Data Flow: Document Ingestion

## Overview

This document describes how budget documents flow through the system, from user upload in the Rails platform to AI-powered chunking in the Python RAG service and back.

---

## Domain Models

### Document

A `Document` is the **local tracking record** for a budget PDF/file sent to the Python RAG service for ingestion. It stores:

- **Metadata**: title, description, budget amount, currency, duration, technologies
- **Processing state**: status (`pending` -> `processing` -> `completed` | `failed`)
- **RAG link**: `external_document_id` (UUID assigned by the RAG service)
- **Chunk count**: `chunks_count` (total chunks created by the RAG service)
- **Raw response**: `raw_json` (full JSON response from the service, for debugging)

A Document belongs to a `User` and has one optional `ChunksBreakdown`.

### ChunksBreakdown

A `ChunksBreakdown` is a **cached snapshot of chunk counts** returned by the RAG service after successful ingestion. It breaks down the total chunk count into 5 semantic categories:

| Field              | Description                                           |
|--------------------|-------------------------------------------------------|
| `project_overview` | High-level project description and objectives chunks  |
| `scope_block`      | Functional scope blocks / feature group chunks        |
| `line_item`        | Individual line items / deliverables chunks           |
| `phase`            | Project phase / timeline milestone chunks             |
| `team_conditions`  | Team composition, rates, and conditions chunks        |

These 5 types map directly to the `ChunksBreakdown` Pydantic model in the RAG service (`rag-estimation-service/app/api/schemas/ingest_response.py`).

---

## Ingestion Flow

```
User                     Rails Platform              RAG Service (Python)
 |                            |                            |
 |  1. Upload budget file     |                            |
 |--------------------------->|                            |
 |                            |                            |
 |                            | 2. Create Document         |
 |                            |    (status: pending)       |
 |                            |                            |
 |                            | 3. POST /ingest            |
 |                            |    {file, metadata}        |
 |                            |--------------------------->|
 |                            |                            |
 |                            | 4. Receive accepted        |
 |                            |    {document_id, status}   |
 |                            |<---------------------------|
 |                            |                            |
 |                            | 5. Update Document         |
 |                            |    external_document_id    |
 |                            |    status: processing      |
 |                            |                            |
 |                            |            ... async processing ...
 |                            |                            |
 |                            | 6. GET /ingest/:id/status  |
 |                            |    (polling or webhook)    |
 |                            |--------------------------->|
 |                            |                            |
 |                            | 7. Receive completed       |
 |                            |    {chunks_created,        |
 |                            |     breakdown, title}      |
 |                            |<---------------------------|
 |                            |                            |
 |                            | 8. Update Document         |
 |                            |    status: completed       |
 |                            |    chunks_count: N         |
 |                            |    Create ChunksBreakdown  |
 |                            |                            |
 |  9. Show results           |                            |
 |<---------------------------|                            |
```

---

## What Rails Sends vs What the Service Returns

### Rails -> RAG Service (POST /ingest)

- The uploaded budget file (PDF, DOCX, etc.)
- Optional metadata (user context, project hints)

### RAG Service -> Rails (Ingest Response)

The service returns an `IngestStatusResponse`:

```python
class IngestStatusResponse(BaseModel):
    document_id: UUID           # Unique ID assigned by the RAG service
    status: str                 # "pending" | "processing" | "completed" | "failed"
    project_title: str | None   # Extracted project title
    chunks_created: int         # Total number of chunks created
    processing_time_ms: int     # Time taken to process
    breakdown: ChunksBreakdown  # Per-type chunk counts
```

---

## Chunk Types and Chunking Strategy

The 5 chunk types align with the RAG service's semantic chunking strategy for budget documents:

1. **project_overview** - Captures the high-level project description, objectives, and context. These chunks help the AI understand what the project is about.

2. **scope_block** - Identifies functional blocks or feature groups within the budget. These map to the `FunctionalBlock` model in the estimation.

3. **line_item** - Extracts individual deliverables, tasks, or cost line items. These map to the `Task` model in the estimation.

4. **phase** - Recognizes project phases, milestones, and timeline information. Used to understand project duration and sequencing.

5. **team_conditions** - Captures team size, roles, hourly rates, and contractual conditions. Used to inform rate calculations in estimations.

Each chunk type is stored and indexed separately in the RAG service's vector database, enabling type-specific retrieval when generating new estimations based on similar historical projects.
