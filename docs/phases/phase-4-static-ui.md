# Phase 4 — Static UI Scaffolding (ERB + Tailwind)

**Objective:** Build all 8 screens as ERB views with Tailwind CSS to achieve visual parity with the React reference. Data comes from seeds — no backend logic yet.

**Dependencies:** Phase 1 (Tailwind + layouts), Phase 3 (seed data)

**Reference:** `project-blueprint-studio/src/pages/` (all files)

---

## 4.1 Landing Page

**Route:** `GET /` → `pages#landing`
**Layout:** `public`
**Reference:** `LandingPage.tsx` (230 lines)

### Sections

1. **Navigation bar** — Fixed top, glass effect
   - Logo (Activity icon + "LIDR RAG Estimator")
   - CTA buttons: "Iniciar sesion" (outline), "Comenzar" (primary)

2. **Hero** — Centered, glow background
   - Badge: "Powered by RAG + GPT-4o" with Sparkles icon
   - H1: "Estima proyectos de software con inteligencia artificial"
   - Subtitle text
   - CTA buttons: "Comenzar ahora" (primary), "Ver documentacion" (outline)
   - Glow effect: fixed div with `bg-primary/8 blur-[100px]` behind hero

3. **Metrics strip** — 4 stat items in a row
   - "150+" Proyectos analizados
   - "2.8K" Chunks indexados
   - "340ms" Latencia media
   - "94%" Precision estimaciones

4. **Features grid** — 4 cards (2x2)
   - Upload icon: "Ingesta inteligente" — description
   - Brain icon: "Estimacion IA" — description
   - Search icon: "Busqueda semantica" — description
   - BarChart3 icon: "Analisis detallado" — description

5. **CTA section** — Centered card with Shield icon

6. **Footer** — Branding + version

---

## 4.2 Dashboard

**Route:** `GET /dashboard` → `dashboard#index`
**Layout:** `application` (with sidebar)
**Reference:** `Index.tsx` (177 lines)

### Sections

1. **Page header** — "Dashboard" / "Resumen del estado del servicio RAG de estimaciones"

2. **Stats row** — 4 stat cards (grid-cols-1 sm:grid-cols-2 lg:grid-cols-4)
   - Documentos: 150, "145 indexados", FileText icon, variant: primary
   - Chunks totales: "2,850", "5 tipos de fragmentos", Layers icon
   - Busquedas (30d): "1,200", "+12% vs mes anterior", Search icon
   - Latencia media: "340ms", "P50 busqueda semantica", Clock icon, variant: success

3. **3-column grid** (mt-8, lg:grid-cols-3):
   - **System health** — "Estado del sistema" with health badge, 3 dependency rows (PostgreSQL + pgvector, Embedding API, LLM API) each with status dot and latency
   - **Chunk distribution** — "Distribucion de chunks" with stacked progress bar and legend (5 types with counts)
   - **Recent ingestions** — "Ingestas recientes" with 4 items showing title, status badge, chunk count, date

---

## 4.3 Ingest Page

**Route:** `GET /ingestions` → `ingestions#index`
**Layout:** `application`
**Reference:** `IngestPage.tsx` (103 lines)

### Layout: 2-column (lg:grid-cols-2)

**Left column — Upload area:**
- Card with border-dashed upload zone
- Upload icon with "Arrastra un archivo JSON" text
- Textarea for direct JSON paste (min-h-[200px], monospace font)
- Sample JSON placeholder showing expected format
- "Ingestar presupuesto" button (primary, full width)

**Right column — Ingestion history:**
- "Historial de ingestas" heading
- List of ingestion items, each showing:
  - Title
  - Status badge (completed/processing/failed)
  - Chunks count (if completed)
  - Processing time
  - Date

---

## 4.4 Estimate Page (3-Step Wizard)

**Route:** `GET /estimations/new` → `estimations#new`
**Layout:** `application`
**Reference:** `EstimatePage.tsx` (738 lines) — **Most complex screen**

### Stepper Header

3-step progress indicator:
- Step 1: "Transcripciones" (FileText icon)
- Step 2: "Bloques funcionales" (Layers icon)
- Step 3: "Estimacion" (Brain icon)
- Active step highlighted with primary color, completed steps with check

### Step 1: Transcriptions

- Page header: "Nueva Estimacion" / "Crea una estimacion basada en transcripciones de reuniones"
- Textarea: "Pega aqui la transcripcion..." (min-h-[200px])
- Row of buttons: "Anadir transcripcion", "Subir archivo .txt"
- List of added transcriptions (title, preview, remove button)
- "Analizar transcripciones" button (primary, disabled when empty)

### Step 2: Functional Blocks & Tasks

- Page header: "Bloques Funcionales" / "Revisa y ajusta los bloques funcionales detectados"
- Summary bar: "X bloques, Y tareas detectadas"
- "Anadir bloque" button
- For each block:
  - Collapsible card with block name (editable inline)
  - Delete block button, edit name button
  - Task list inside:
    - Each task: name (editable), delete button
    - "Anadir tarea" button
- "Continuar a estimacion" button

### Step 3: Estimation Results

- Page header: "Resultado de Estimacion" / "Revisa las estimaciones generadas"
- Global rate input (number, EUR/h)
- Stats grid (4 items): Total horas, Bloques, Tareas, Coste total
- Detailed breakdown per block:
  - Block name, total hours, total cost
  - Per-task rows: name, rate input, hours bar (progress), cost
- "Exportar estimacion" button

---

## 4.5 Search Page

**Route:** `GET /search` → `search#index`
**Layout:** `application`
**Reference:** `SearchPage.tsx` (132 lines)

### Sections

1. **Page header** — "Busqueda Semantica" / "Busca en la base de conocimiento de estimaciones"

2. **Search input** — Full width with Search icon prefix

3. **Filter pills** — 5 chunk type toggles:
   - project_overview, scope_block, line_item, phase, team_conditions
   - Toggle on/off with active highlighting

4. **Results grid** — For each result:
   - Type badge (colored by chunk type)
   - Similarity score % (color-coded: green 80%+, orange 65-79%, gray <65%)
   - Project name
   - Content preview text (truncated)
   - Technology tags
   - Cost display

---

## 4.6 Documents Page

**Route:** `GET /documents` → `documents#index`
**Layout:** `application`
**Reference:** `DocumentsPage.tsx` (113 lines)

### Sections

1. **Page header** — "Estimaciones" / "Historial de presupuestos y estimaciones" with "Exportar" action button

2. **Search input** — Filter by title

3. **Table grid** — `grid-cols-[1fr_100px_80px_100px_120px_80px]`
   - Header row: Proyecto, Estado, Chunks, Presupuesto, Duracion, Acciones
   - For each document:
     - Title + technology tags
     - Status badge
     - Chunks count
     - Budget (formatted currency, right-aligned)
     - Duration
     - Action buttons: view (eye icon → `/documents/:id`), delete (trash icon)
   - Hover: `bg-surface`

---

## 4.7 Estimation Detail Page

**Route:** `GET /documents/:id` → `documents#show`
**Layout:** `application`
**Reference:** `EstimationDetailPage.tsx` (557 lines)

### Sections

1. **Page header** — Estimation title / description with "Exportar PDF" action button

2. **Meta cards row** — 4 items: Fecha, Bloques, Tareas, Tarifa hora

3. **Status row** — Status badge + Confidence bar (score %, level badge) + Tech stack tags

4. **3-point estimate selector** — 3 buttons:
   - Optimista (TrendingDown icon, green)
   - Esperado (Minus icon, blue)
   - Pesimista (TrendingUp icon, orange)
   - Selected one highlighted

5. **Summary stats** — For selected estimate type:
   - Total horas, Coste total (formatted)

6. **Block/task breakdown** — Collapsible blocks:
   - Block name, hours subtotal, cost subtotal
   - Per-task rows: name, rate, hours (with progress bar), cost
   - Progress bars proportional to max task hours

7. **References grid** — "Proyectos de referencia" heading:
   - For each reference:
     - Type badge
     - Similarity % (color-coded)
     - Project title
     - Content preview
     - Tech tags
     - Cost

---

## 4.8 Minimal Controllers

Stub controllers with hardcoded or seed data:

```ruby
class PagesController < ApplicationController
  layout "public"
  skip_before_action :authenticate_user!

  def landing; end
end

class DashboardController < ApplicationController
  def index
    # Use seed data or hardcoded values for now
  end
end

class IngestionsController < ApplicationController
  def index; end
end

class EstimationsController < ApplicationController
  def new; end
end

class SearchController < ApplicationController
  def index; end
end

class DocumentsController < ApplicationController
  def index
    @documents = Document.includes(:chunks_breakdown).recent
  end

  def show
    @estimation = Estimation.includes(functional_blocks: :tasks, references: []).find(params[:id])
  end
end
```

---

## 4.9 Routes

```ruby
root "pages#landing"

get "dashboard", to: "dashboard#index"

resources :ingestions, only: [:index, :create]
resources :estimations, only: [:new, :create, :show]
get "search", to: "search#index"
resources :documents, only: [:index, :show, :destroy]
```

---

## Files to Create

| Action | File |
|--------|------|
| Create | `app/controllers/pages_controller.rb` |
| Create | `app/controllers/dashboard_controller.rb` |
| Create | `app/controllers/ingestions_controller.rb` |
| Create | `app/controllers/estimations_controller.rb` |
| Create | `app/controllers/search_controller.rb` |
| Create | `app/controllers/documents_controller.rb` |
| Create | `app/views/pages/landing.html.erb` |
| Create | `app/views/dashboard/index.html.erb` |
| Create | `app/views/ingestions/index.html.erb` |
| Create | `app/views/estimations/new.html.erb` |
| Create | `app/views/search/index.html.erb` |
| Create | `app/views/documents/index.html.erb` |
| Create | `app/views/documents/show.html.erb` |
| Modify | `config/routes.rb` |

---

## Verification

1. All 8 routes respond with 200 (authenticated where required)
2. Visual comparison with React reference — dark theme, correct colors, layout
3. Landing page renders all sections (hero, metrics, features, CTA, footer)
4. Dashboard shows stat cards, health, chunks, recent ingestions
5. Ingest page shows upload area and history
6. Estimate wizard renders all 3 steps (static, no JS navigation yet)
7. Search page shows input, filters, and result cards
8. Documents table shows all columns with seed data
9. Estimation detail shows meta, 3-point selector, breakdown, references
10. Sidebar highlights active page correctly
