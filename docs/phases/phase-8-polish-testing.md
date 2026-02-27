# Phase 8 — Polish, Testing & End-to-End Validation

**Status: 🔶 In Progress**

**Objective:** Achieve production quality with full test coverage, responsive design, error states, and accessibility.

**Dependencies:** All previous phases (1–7)

---

## Completed — Bug Fixes & Polish (Phase 8.6 partial, model validations)

The following bug fixes and polish items have been addressed:

### Critical Bug Fixes (prevented 500 errors in production)
- **`ApplicationController`** — Added `rescue_from ActiveRecord::RecordNotFound` with redirect + alert
- **`IngestController#create`** — Changed `create!` → `create` with persistence guard
- **`RagResponseParser.parse_estimate`** — Added nil guards (`dig`, `|| 0`, `|| {}`) and `rescue NoMethodError, TypeError` wrapper
- **`IngestionStatusJob`** — Added `discard_on NotFoundError` (marks document failed), `retry_on RagServiceClient::Error` (3 attempts then fails), safe `chunks_breakdown` upsert via `find_or_initialize_by`

### Moderate Fixes (behavioral/UX)
- **`RagErrorHandling`** — Fixed flash lost on redirect: uses `@rag_error_message` ivar instead of fragile `flash.now[:alert]` read-back
- **`SessionsController` / `RegistrationsController`** — Replaced hardcoded `"/dashboard"` with `dashboard_path`
- **`Task#cost`** — Added `ESTIMATE_TYPES` guard (`ArgumentError` instead of `NoMethodError`), `.to_f` nil safety

### Model Validation Polish
- **`Estimation`** — `global_rate` numericality > 0, `currency` inclusion in EUR/USD/GBP, `confidence_score` in 0..1
- **`Task`** — `hours_*` numericality >= 0, `rate` numericality > 0
- **`FunctionalBlock`** — `position` integer numericality >= 0
- **`Reference`** — `similarity_score` numericality in 0..1
- **`ChunksBreakdown#total`** — Nil-safe with `|| 0` guards

---

## 8.1 System Tests (Capybara + Selenium)

Full browser-driven tests for critical user flows:

### Test Scenarios

| Test | Steps |
|------|-------|
| Registration flow | Visit `/register`, fill form, submit → redirected to `/dashboard` |
| Login flow | Visit `/login`, fill credentials, submit → redirected to `/dashboard` |
| Logout | Click logout → redirected to `/login` |
| Auth guard | Visit `/dashboard` unauthenticated → redirected to `/login` |
| Estimation wizard | Login → Navigate to Estimate → Add transcriptions → Step 2: edit blocks/tasks → Step 3: set rate, verify costs |
| Ingestion flow | Login → Navigate to Ingest → Paste JSON → Submit → See in history |
| Search | Login → Navigate to Search → Enter query → Toggle filters → Verify results |
| Documents browsing | Login → Navigate to Documents → Search filter → Click view → See detail |
| 3-point toggle | Navigate to estimation detail → Click Optimistic/Expected/Pessimistic → Verify data changes |

### Test Setup

```ruby
# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]
end
```

---

## 8.2 Integration Tests — RagServiceClient

Use **WebMock** to stub all HTTP calls to the RAG service.

### Stubbed Endpoints

| Test | Endpoint | Assertions |
|------|----------|------------|
| Health check | `GET /api/v1/health` | Returns parsed health data |
| Ingest success | `POST /api/v1/ingest` | Returns document_id and status |
| Ingest duplicate (409) | `POST /api/v1/ingest` | Raises appropriate error |
| Ingest status | `GET /api/v1/ingest/{id}/status` | Returns status with chunks |
| Delete document | `DELETE /api/v1/ingest/{id}` | Returns confirmation |
| Search | `POST /api/v1/search` | Returns results array |
| Estimate | `POST /api/v1/estimate` | Returns 3-point estimates |
| Batch estimate | `POST /api/v1/estimate/batch` | Returns aggregated results |
| Stats | `GET /api/v1/stats` | Returns document/chunk counts |
| Timeout handling | Any endpoint | Raises `TimeoutError` |
| Service unavailable | Any endpoint | Raises `ServiceUnavailableError` |

### Setup

```ruby
# test/services/rag_service_client_test.rb
require "test_helper"
require "webmock/minitest"

class RagServiceClientTest < ActiveSupport::TestCase
  setup do
    @client = RagServiceClient.new(base_url: "http://rag-test:8000")
  end

  test "health returns parsed response" do
    stub_request(:get, "http://rag-test:8000/api/v1/health")
      .to_return(status: 200, body: { status: "healthy", version: "0.1.0" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.health
    assert_equal "healthy", result["status"]
  end

  # ... more tests
end
```

---

## 8.3 Model Tests

| Model | Test Coverage |
|-------|--------------|
| User | Validates email uniqueness, email format, name presence, password length |
| Document | Validates title, status inclusion, scopes (by_status, recent, search_by_title) |
| ChunksBreakdown | `#total` computed correctly |
| Estimation | Validates title, status, nested attributes, associations |
| FunctionalBlock | `#total_hours_*` methods, `#total_cost` |
| Task | `#cost` calculation, `#effective_rate` fallback to global rate |
| Reference | `by_similarity` scope ordering |

---

## 8.4 Controller Tests (Request Specs)

| Controller | Tests |
|------------|-------|
| SessionsController | Login success, login failure, logout, session management |
| RegistrationsController | Register success, register with invalid data |
| DashboardController | Requires auth, renders with seed data |
| IngestionsController | Index lists documents, create with valid JSON, create with invalid JSON |
| DocumentsController | Index with search, index with pagination, show, destroy |
| EstimationsController | New renders form, create persists data, show loads associations |
| SearchController | Index without query, index with query (stubbed RAG) |
| PagesController | Landing page loads without auth |

All protected routes should return 302 redirect when unauthenticated.

---

## 8.5 Responsive Design

Test at 3 breakpoints:

| Breakpoint | Width | Key Checks |
|------------|-------|------------|
| Mobile | 375px | Sidebar hidden or hamburger menu, single-column grids, full-width cards, readable text |
| Tablet | 768px | 2-column grids, sidebar collapsed by default, form layouts stack |
| Desktop | 1280px+ | Full layout with expanded sidebar, 4-column stat grids, full table columns |

### Mobile Sidebar Approach

Options:
1. **Overlay sidebar** — Hidden off-screen, slides in on hamburger click
2. **Bottom navigation** — 5-item bottom bar on mobile
3. **Collapsed by default** — Always show icon-only sidebar on mobile

Recommended: **Option 1** — Overlay with hamburger button visible in mobile layout.

---

## 8.6 Error & Empty States

| State | Location | Display |
|-------|----------|---------|
| No documents | Documents index | Centered empty state: icon, message, "Ingestar primer documento" CTA |
| No search results | Search index | "No se encontraron resultados" with suggestion to broaden query |
| Failed ingestion | Ingestion history | Status badge "failed", error message in tooltip or detail |
| RAG service unavailable | Dashboard, Search, Estimate | Alert banner: "Servicio RAG no disponible", graceful fallback |
| Form validation errors | All forms | Inline field errors with red border and message text |
| Estimation processing | Detail page | Processing skeleton/spinner state |
| Estimation failed | Detail page | Error state with retry button |

---

## 8.7 Accessibility

### Requirements

| Area | Implementation |
|------|---------------|
| Heading hierarchy | h1 per page (in PageHeader), h2 for sections, h3 for sub-sections |
| Form labels | Every input has `<label>` with `for` attribute |
| ARIA attributes | `aria-current="page"` on active sidebar link, `aria-expanded` on collapsibles, `aria-label` on icon-only buttons |
| Focus management | Focus ring visible on all interactive elements (Tailwind `ring` utilities), skip-to-main link |
| Keyboard navigation | Tab through all interactive elements, Enter/Space to activate, Escape to dismiss |
| Color contrast | Verify muted text against dark backgrounds meets WCAG AA |
| Screen reader | Status badges include text (not just color), progress bars have `aria-valuenow` |

---

## 8.8 Performance

### N+1 Prevention

| Query | Eager Load |
|-------|-----------|
| Documents index | `includes(:chunks_breakdown)` |
| Estimation detail | `includes(functional_blocks: :tasks, references: [])` |
| Dashboard recent | `includes(:chunks_breakdown)` |

### Database Indexes

Verify these indexes exist (created in Phase 3 migrations):
- `documents.external_document_id` (unique)
- `documents.status`
- `documents.created_at`
- `documents.user_id`
- `estimations.status`
- `estimations.created_at`
- `estimations.user_id`
- `functional_blocks.estimation_id`
- `tasks.functional_block_id`
- `references.estimation_id`
- `users.email` (unique)

### Asset Performance

- Tailwind CSS purged in production (only used classes)
- Propshaft fingerprints assets for cache busting
- Thruster provides HTTP compression and caching

---

## 8.9 PDF Export (Stub)

Placeholder for estimation detail export:

**Option A:** `prawn` gem for server-side PDF generation
**Option B:** Client-side `window.print()` with print-specific CSS

Recommended: **Option B** initially (simpler), with `@media print` styles that:
- Remove sidebar, navigation
- White background for readability
- Show all blocks expanded
- Include a header with logo and date

Create a print stylesheet or use Tailwind's `print:` variant.

---

## 8.10 Seed Data Update

Update `db/seeds.rb` with a complete demo dataset that exercises all UI states:

- 1 admin user with varied data
- 6+ documents: 3 completed, 1 processing, 1 failed, 1 pending
- Chunks breakdowns for completed documents
- 3 completed estimations with:
  - Varying confidence levels (high, medium, low)
  - Different technology stacks
  - Realistic Spanish project names
  - 3-5 functional blocks with 3-8 tasks each
  - 5-10 references per estimation
- Data should match the hardcoded values in the React reference where possible

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Create | `test/system/authentication_test.rb` |
| Create | `test/system/estimation_wizard_test.rb` |
| Create | `test/system/ingestion_test.rb` |
| Create | `test/system/search_test.rb` |
| Create | `test/system/documents_test.rb` |
| Create | `test/services/rag_service_client_test.rb` |
| Create | `test/services/rag_response_parser_test.rb` |
| Create | `test/models/user_test.rb` |
| Create | `test/models/document_test.rb` |
| Create | `test/models/estimation_test.rb` |
| Create | `test/models/functional_block_test.rb` |
| Create | `test/models/task_test.rb` |
| Create | `test/models/reference_test.rb` |
| Create | `test/controllers/sessions_controller_test.rb` |
| Create | `test/controllers/registrations_controller_test.rb` |
| Create | `test/controllers/dashboard_controller_test.rb` |
| Create | `test/controllers/ingestions_controller_test.rb` |
| Create | `test/controllers/documents_controller_test.rb` |
| Create | `test/controllers/estimations_controller_test.rb` |
| Create | `test/controllers/search_controller_test.rb` |
| Create | `test/controllers/pages_controller_test.rb` |
| Create | Empty state partials as needed |
| Modify | `Gemfile` (add webmock) |
| Modify | `test/test_helper.rb` (WebMock setup) |
| Modify | `db/seeds.rb` (comprehensive demo data) |
| Modify | Views (add ARIA attributes, empty states, print styles) |
| Modify | `app/assets/stylesheets/application.tailwind.css` (print styles, responsive tweaks) |

---

## Verification

1. `rails test` — All model, controller, and integration tests pass
2. `rails test:system` — All system tests pass in headless Chrome
3. Responsive: manually verify at 375px, 768px, 1280px
4. Empty states: verify with empty database
5. Error states: verify with RAG service stopped
6. Accessibility: run axe-core or Lighthouse audit, verify keyboard navigation
7. Performance: check N+1 with `bullet` gem or query logs
8. Print: `Ctrl+P` on estimation detail produces readable output
9. Seed data: `rails db:seed` creates complete demo dataset
