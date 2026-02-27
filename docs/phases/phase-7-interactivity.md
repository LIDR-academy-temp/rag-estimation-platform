# Phase 7 — Real-Time & Interactive Features (Turbo + Stimulus)

**Status: ✅ Completed**

**Objective:** Add all client-side interactivity matching the React reference using Hotwire patterns.

**Dependencies:** Phases 4, 5, 6

**Reference:** `project-blueprint-studio` (interactive behaviors in `EstimatePage.tsx`, `AppSidebar.tsx`, `SearchPage.tsx`, `EstimationDetailPage.tsx`)

---

## 7.1 Stimulus Controllers

### estimation-wizard controller

**app/javascript/controllers/estimation_wizard_controller.js**

The most complex controller. Manages the 3-step estimation wizard.

**Targets:** `step1`, `step2`, `step3`, `stepper`, `transcriptionInput`, `transcriptionList`, `blockList`, `globalRate`, `statsGrid`

**Values:** `currentStep` (Number, default 1)

**Actions:**
- `nextStep` / `prevStep` — Navigate between steps, show/hide step panels
- `addTranscription` — Read textarea value, append to transcription list, clear textarea
- `removeTranscription` — Remove transcription from list by index
- `analyzeTranscriptions` — Submit transcriptions to server (Turbo), transition to step 2

Step 2 (Blocks/Tasks):
- `addBlock` — Append new block card
- `removeBlock` — Remove block card
- `editBlockName` — Toggle block name to input field
- `saveBlockName` — Save edited block name
- `toggleBlock` — Collapse/expand block's task list
- `addTask` — Append task row to a block
- `removeTask` — Remove task row
- `editTaskName` — Toggle task name to input
- `saveTaskName` — Save edited task name

Step 3 (Results):
- `updateGlobalRate` — Recalculate all costs when global rate changes
- `updateTaskRate` — Recalculate individual task cost when per-task rate changes
- `recalculateTotals` — Recompute summary stats

**Key patterns:**
- Use `data-estimation-wizard-target` on DOM elements
- Keyboard support: Enter to save inline edits, Escape to cancel
- Disable "Analizar" button when no transcriptions
- Show/hide steps via CSS classes (`hidden`)

### sidebar controller

**app/javascript/controllers/sidebar_controller.js**

**Values:** `collapsed` (Boolean, default false)

**Lifecycle:**
- `connect()` — Read collapsed state from `localStorage`, apply class
- `toggle()` — Flip collapsed state, save to `localStorage`, toggle width classes

**DOM changes:**
- Collapsed: `w-16`, hide labels, show only icons
- Expanded: `w-60`, show labels

### file-upload controller

**app/javascript/controllers/file_upload_controller.js**

**Targets:** `dropzone`, `textarea`, `fileInput`

**Actions:**
- `dragover` / `dragleave` — Visual feedback on dropzone (border highlight)
- `drop` — Read dropped file, parse content, insert into textarea
- `selectFile` — Trigger hidden file input click
- `readFile` — Read file from input, insert content into textarea

**Constraints:** Accept only `.json` or `.txt` files.

### search-filter controller

**app/javascript/controllers/search_filter_controller.js**

**Targets:** `pill` (multiple), `form`

**Actions:**
- `toggle` — Toggle active class on clicked pill, update hidden input values, auto-submit form via Turbo Frame

**State:** Track selected chunk types as an array, serialize to hidden inputs.

### estimate-toggle controller

**app/javascript/controllers/estimate_toggle_controller.js**

**Targets:** `button` (3), `content` (3, one per estimate type)

**Values:** `active` (String, default "expected")

**Actions:**
- `select` — Set active estimate type, highlight selected button, show/hide corresponding content sections

**Used on:** Estimation detail page for switching between optimistic/expected/pessimistic views.

### collapsible controller

**app/javascript/controllers/collapsible_controller.js**

**Targets:** `content`, `icon`

**Values:** `open` (Boolean, default true)

**Actions:**
- `toggle` — Show/hide content, rotate chevron icon

**Reusable** on: Functional blocks in estimate wizard, block breakdown on detail page.

### password-toggle controller

(Already defined in Phase 2)

### flash controller

**app/javascript/controllers/flash_controller.js**

**Actions:**
- `connect()` — Auto-dismiss flash after 5 seconds
- `dismiss()` — Remove flash immediately on click

---

## 7.2 Turbo Frames

### Ingestion History

```erb
<%= turbo_frame_tag "ingestion_history" do %>
  <!-- Ingestion list -->
<% end %>
```

After `IngestionsController#create` succeeds, redirect includes the frame — list refreshes automatically.

### Search Results

```erb
<%= turbo_frame_tag "search_results" do %>
  <!-- Search results -->
<% end %>
```

Search form targets this frame:
```erb
<%= form_with url: search_path, method: :get, data: { turbo_frame: "search_results" } do |f| %>
```

### Dashboard Panels (Lazy-loaded)

```erb
<%= turbo_frame_tag "dashboard_health", src: dashboard_health_path, loading: "lazy" do %>
  <!-- Loading skeleton -->
<% end %>
```

Requires separate controller actions that return frame-only responses:
- `DashboardController#health` — Health panel
- `DashboardController#chunks` — Chunk distribution panel
- `DashboardController#recent` — Recent ingestions panel

### Documents Table

```erb
<%= turbo_frame_tag "documents_table" do %>
  <!-- Documents table + pagination -->
<% end %>
```

Search form and pagination links target this frame for inline updates.

---

## 7.3 Turbo Streams (via Solid Cable)

### Document Status Broadcasts

When `IngestionStatusJob` updates a document's status:

```ruby
# In IngestionStatusJob, after updating status:
document.broadcast_replace_to(
  "user_#{document.user_id}_documents",
  target: "document_#{document.id}",
  partial: "documents/document",
  locals: { document: document }
)
```

User subscribes in view:
```erb
<%= turbo_stream_from "user_#{current_user.id}_documents" %>
```

### Estimation Results Streaming

When estimation completes, stream results into Step 3:

```ruby
estimation.broadcast_replace_to(
  "estimation_#{estimation.id}",
  target: "estimation_results",
  partial: "estimations/results",
  locals: { estimation: estimation }
)
```

---

## 7.4 CSS Transitions

Replace Framer Motion animations with CSS:

### Hover Effects

```css
/* Card hover */
.card-hover {
  @apply transition-all duration-200;
}
.card-hover:hover {
  @apply bg-surface-hover;
}

/* Nav item hover */
.nav-hover {
  @apply transition-colors duration-200;
}
```

### Entrance Animations

```css
@keyframes fade-in-up {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in-up {
  animation: fade-in-up 0.3s ease-out forwards;
}

/* Staggered children */
.stagger-children > * {
  opacity: 0;
  animation: fade-in-up 0.3s ease-out forwards;
}
.stagger-children > *:nth-child(1) { animation-delay: 0.05s; }
.stagger-children > *:nth-child(2) { animation-delay: 0.1s; }
.stagger-children > *:nth-child(3) { animation-delay: 0.15s; }
.stagger-children > *:nth-child(4) { animation-delay: 0.2s; }
```

### Processing Status Animation

Already defined in Tailwind config as `animate-pulse-glow`. Applied to processing status dots.

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Create | `app/javascript/controllers/estimation_wizard_controller.js` |
| Create | `app/javascript/controllers/sidebar_controller.js` |
| Create | `app/javascript/controllers/file_upload_controller.js` |
| Create | `app/javascript/controllers/search_filter_controller.js` |
| Create | `app/javascript/controllers/estimate_toggle_controller.js` |
| Create | `app/javascript/controllers/collapsible_controller.js` |
| Create | `app/javascript/controllers/flash_controller.js` |
| Modify | All view files (add turbo_frame_tag, data-controller attributes, Stimulus targets/actions) |
| Modify | `app/assets/stylesheets/application.tailwind.css` (CSS transitions) |
| Modify | `app/jobs/ingestion_status_job.rb` (add broadcast) |
| Modify | `config/routes.rb` (add dashboard panel routes if lazy-loaded) |

---

## Verification

1. Sidebar collapses/expands, state persists across page navigations (localStorage)
2. Estimation wizard navigates between 3 steps
3. Transcriptions can be added/removed in step 1
4. Blocks and tasks can be added/edited/deleted inline in step 2
5. Global rate changes recalculate costs in step 3
6. Search form submits via Turbo Frame, results update without full page reload
7. Filter pills toggle and filter results
8. Documents table filters and paginates via Turbo Frame
9. Ingestion history refreshes after creating a new ingestion
10. Real-time status updates appear when ingestion completes (Turbo Stream)
11. Estimate toggle switches between optimistic/expected/pessimistic views
12. Collapsible blocks expand/collapse smoothly
13. Flash messages auto-dismiss after 5 seconds
14. File upload drag-and-drop works on ingest page
15. Password visibility toggle works on login
16. CSS entrance animations appear on page load
