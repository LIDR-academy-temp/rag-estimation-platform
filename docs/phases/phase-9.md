# Phase 9 — Testing, Responsive Design & Accessibility

**Status: ⬚ Pending**

**Objective:** Achieve production quality with full test coverage, responsive design, error states, accessibility, and print support.

**Dependencies:** All previous phases (1–8)

---

## 9.1 Test Infrastructure

### Gemfile Additions

```ruby
group :test do
  gem "webmock"
  gem "capybara"
  gem "selenium-webdriver"
end
```

### Test Helper Setup

```ruby
# test/test_helper.rb
require "webmock/minitest"

# Disable all external HTTP requests in tests
WebMock.disable_net_connect!(allow_localhost: true)
```

### Fixtures

Create fixtures for all models: users, documents, chunks_breakdowns, estimations, functional_blocks, tasks, references.

---

## 9.2 Model Tests

| Model | Test Coverage |
|-------|--------------|
| User | Validates email uniqueness, email format, name presence, password length |
| Document | Validates title, status inclusion, scopes (by_status, recent, search_by_title) |
| ChunksBreakdown | `#total` computed correctly |
| Estimation | Validates title, status, nested attributes, associations |
| FunctionalBlock | `#total_hours_*` methods, `#total_cost` |
| Task | `#cost` calculation, `#effective_rate` fallback to global rate |
| Reference | `by_similarity` scope ordering |

### Files to Create

- `test/models/user_test.rb`
- `test/models/document_test.rb`
- `test/models/estimation_test.rb`
- `test/models/functional_block_test.rb`
- `test/models/task_test.rb`
- `test/models/reference_test.rb`
- `test/models/chunks_breakdown_test.rb`

---

## 9.3 Service Tests

### RagServiceClient Tests

Use **WebMock** to stub all HTTP calls to the RAG service.

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

### RagResponseParser Tests

- `test/services/rag_service_client_test.rb`
- `test/services/rag_response_parser_test.rb`

---

## 9.4 Controller Tests (Request Specs)

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

### Files to Create

- `test/controllers/sessions_controller_test.rb`
- `test/controllers/registrations_controller_test.rb`
- `test/controllers/dashboard_controller_test.rb`
- `test/controllers/ingestions_controller_test.rb`
- `test/controllers/documents_controller_test.rb`
- `test/controllers/estimations_controller_test.rb`
- `test/controllers/search_controller_test.rb`
- `test/controllers/pages_controller_test.rb`

---

## 9.5 System Tests (Capybara + Selenium)

Full browser-driven tests for critical user flows:

| Test | Steps |
|------|-------|
| Registration flow | Visit `/register`, fill form, submit → redirected to `/dashboard` |
| Login flow | Visit `/login`, fill credentials, submit → redirected to `/dashboard` |
| Logout | Click logout → redirected to `/login` |
| Auth guard | Visit `/dashboard` unauthenticated → redirected to `/login` |
| Estimation wizard | Login → Navigate to Estimate → Add transcriptions → Step 2: edit blocks/tasks → Step 3: set rate, verify costs |

### Test Setup

```ruby
# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]
end
```

### Files to Create

- `test/system/authentication_test.rb`
- `test/system/estimation_wizard_test.rb`
- `test/system/ingestion_test.rb`
- `test/system/search_test.rb`
- `test/system/documents_test.rb`

---

## 9.6 Responsive Design

Test at 3 breakpoints:

| Breakpoint | Width | Key Checks |
|------------|-------|------------|
| Mobile | 375px | Sidebar hidden or hamburger menu, single-column grids, full-width cards, readable text |
| Tablet | 768px | 2-column grids, sidebar collapsed by default, form layouts stack |
| Desktop | 1280px+ | Full layout with expanded sidebar, 4-column stat grids, full table columns |

### Mobile Sidebar Approach

Recommended: **Overlay sidebar** — Hidden off-screen, slides in on hamburger click.

---

## 9.7 Error & Empty States

| State | Location | Display |
|-------|----------|---------|
| No documents | Documents index | Centered empty state: icon, message, "Ingestar primer documento" CTA |
| No search results | Search index | "No se encontraron resultados" with suggestion to broaden query |
| Failed ingestion | Ingestion history | Status badge "failed", error message in tooltip or detail |
| RAG service unavailable | Dashboard, Search, Estimate | Alert banner: "Servicio RAG no disponible", graceful fallback |

---

## 9.8 Accessibility

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

## 9.9 Print Stylesheet + PDF Export Stub

Recommended: Client-side `window.print()` with print-specific CSS using `@media print` styles that:
- Remove sidebar, navigation
- White background for readability
- Show all blocks expanded
- Include a header with logo and date

Use Tailwind's `print:` variant or a dedicated print stylesheet.

---

## 9.10 Verification Checklist

1. `rails test` — All model, controller, and integration tests pass
2. `rails test:system` — All system tests pass in headless Chrome
3. Responsive: manually verify at 375px, 768px, 1280px
4. Empty states: verify with empty database
5. Error states: verify with RAG service stopped
6. Accessibility: run axe-core or Lighthouse audit, verify keyboard navigation
7. Print: `Ctrl+P` on estimation detail produces readable output

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Modify | `Gemfile` (add webmock) |
| Modify | `test/test_helper.rb` (WebMock setup) |
| Create | `test/models/user_test.rb` |
| Create | `test/models/document_test.rb` |
| Create | `test/models/estimation_test.rb` |
| Create | `test/models/functional_block_test.rb` |
| Create | `test/models/task_test.rb` |
| Create | `test/models/reference_test.rb` |
| Create | `test/models/chunks_breakdown_test.rb` |
| Create | `test/services/rag_service_client_test.rb` |
| Create | `test/services/rag_response_parser_test.rb` |
| Create | `test/controllers/sessions_controller_test.rb` |
| Create | `test/controllers/registrations_controller_test.rb` |
| Create | `test/controllers/dashboard_controller_test.rb` |
| Create | `test/controllers/ingestions_controller_test.rb` |
| Create | `test/controllers/documents_controller_test.rb` |
| Create | `test/controllers/estimations_controller_test.rb` |
| Create | `test/controllers/search_controller_test.rb` |
| Create | `test/controllers/pages_controller_test.rb` |
| Create | `test/system/authentication_test.rb` |
| Create | `test/system/estimation_wizard_test.rb` |
| Create | `test/system/ingestion_test.rb` |
| Create | `test/system/search_test.rb` |
| Create | `test/system/documents_test.rb` |
| Create | Empty state partials as needed |
| Modify | Views (add ARIA attributes, empty states, print styles) |
| Modify | `app/assets/stylesheets/application.tailwind.css` (print styles, responsive tweaks) |
