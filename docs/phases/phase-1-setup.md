# Phase 1 — Project Setup & Configuration

**Status: ✅ Completed**

**Objective:** Establish the foundational tooling, styling system, and layout scaffolding that all subsequent phases build upon.

**Dependencies:** None

---

## 1.1 Database — Switch from SQLite to PostgreSQL

### Current State
- `Gemfile` has `gem "sqlite3", ">= 2.1"`
- `config/database.yml` uses SQLite3 adapter for all environments
- Production uses separate SQLite DBs for Solid Cache/Queue/Cable

### Changes Required

**Gemfile:**
- Replace `gem "sqlite3", ">= 2.1"` with `gem "pg", "~> 1.5"`

**config/database.yml:**
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: rag_estimation_platform_development

test:
  <<: *default
  database: rag_estimation_platform_test

production:
  primary:
    <<: *default
    url: <%= ENV["DATABASE_URL"] %>
  cache:
    <<: *default
    database: rag_estimation_platform_production_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: rag_estimation_platform_production_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: rag_estimation_platform_production_cable
    migrations_paths: db/cable_migrate
```

**Notes:**
- Solid Cache/Queue/Cable can stay on separate PostgreSQL databases in production, or could use the same primary DB with different schemas. Simplest approach: keep them as separate DBs following the existing Rails 8 convention.
- Development and test use local PostgreSQL with default credentials.

---

## 1.2 Docker & Deployment Infrastructure

### docker-compose.dev.yml (new file)

Services:
- **app**: Rails app
  - Build from `Dockerfile.dev` or use volume mounts with base Ruby image
  - Port: `3000:3000`
  - Bind mounts: `app/`, `config/`, `db/`, `lib/`, `Gemfile`, `Gemfile.lock`
  - Environment: `DATABASE_URL`, `RAG_SERVICE_BASE_URL=http://host.docker.internal:8000`
  - Depends on: `db`
- **db**: PostgreSQL 16
  - Image: `postgres:16-alpine`
  - Port: `5432:5432`
  - Environment: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
  - Volume: `pgdata:/var/lib/postgresql/data`

### Dockerfile (update existing)

Current state: Multi-stage build with SQLite3 dependencies.

Changes:
- **Base stage:** Replace `sqlite3` with `libpq5` in runtime packages
- **Build stage:** Add `libpq-dev` to build packages (needed to compile `pg` gem)
- Keep everything else (bootsnap precompile, propshaft assets, non-root user)

```dockerfile
# Base stage - change:
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips libpq5 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Build stage - change:
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
```

### docker-compose.prod.yml (new file)

Services:
- **app**: Rails from built image, port 80 via Thruster
  - Environment via `.env.production`
  - Depends on: `db`
- **db**: PostgreSQL 16 with production-tuned settings
  - Persistent volume
  - Tuned `shared_buffers`, `work_mem`, etc.

### Kamal deployment (update config/deploy.yml)

Changes to existing file:
- Add `DATABASE_URL` and `RAG_SERVICE_BASE_URL` to env secrets
- Add PostgreSQL accessory:
  ```yaml
  accessories:
    db:
      image: postgres:16-alpine
      host: 192.168.0.1
      port: "127.0.0.1:5432:5432"
      env:
        secret:
          - POSTGRES_PASSWORD
        clear:
          POSTGRES_USER: rag_estimation_platform
          POSTGRES_DB: rag_estimation_platform_production
      directories:
        - data:/var/lib/postgresql/data
  ```
- Remove SQLite storage volume (no longer needed for DB, but keep for Active Storage if used)
- Configure health check against `/up`

### Environment Files (new)

- **`.env.development`** — `DATABASE_URL`, `RAG_SERVICE_BASE_URL`
- **`.env.production.sample`** — Template with all required vars
- **`.env.kamal`** — `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`, `DATABASE_URL`, `RAG_SERVICE_BASE_URL`, `POSTGRES_PASSWORD`
- Add `.env*` patterns to `.gitignore` (keep `.env.*.sample`)

---

## 1.3 Tailwind CSS & Theme

### Install tailwindcss-rails

```bash
bundle add tailwindcss-rails
rails tailwindcss:install
```

This will:
- Add `tailwindcss-rails` to Gemfile
- Create `config/tailwind.config.js`
- Create `app/assets/stylesheets/application.tailwind.css`
- Update `Procfile.dev` for Tailwind watcher

### Port the Dark Theme

**app/assets/stylesheets/application.tailwind.css:**

Port from `project-blueprint-studio/src/index.css`:

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 4%;
    --foreground: 0 0% 95%;
    --card: 0 0% 7%;
    --card-foreground: 0 0% 95%;
    --popover: 0 0% 7%;
    --popover-foreground: 0 0% 95%;
    --primary: 46 78% 59%;
    --primary-foreground: 0 0% 4%;
    --secondary: 0 0% 12%;
    --secondary-foreground: 0 0% 80%;
    --muted: 0 0% 10%;
    --muted-foreground: 0 0% 55%;
    --accent: 46 78% 59%;
    --accent-foreground: 0 0% 4%;
    --destructive: 0 62% 50%;
    --destructive-foreground: 0 0% 100%;
    --border: 0 0% 14%;
    --input: 0 0% 14%;
    --ring: 46 78% 59%;
    --radius: 0.625rem;
    --sidebar-background: 0 0% 5%;
    --sidebar-foreground: 0 0% 55%;
    --sidebar-primary: 46 78% 59%;
    --sidebar-primary-foreground: 0 0% 4%;
    --sidebar-accent: 0 0% 12%;
    --sidebar-accent-foreground: 0 0% 85%;
    --sidebar-border: 0 0% 14%;
    --sidebar-ring: 46 78% 59%;
    --surface: 0 0% 9%;
    --surface-hover: 0 0% 13%;
    --glow: 46 78% 59%;
    --success: 152 60% 42%;
    --warning: 38 92% 50%;
    --info: 210 80% 56%;
  }

  * { @apply border-border; }
  body { @apply bg-background text-foreground font-sans antialiased; }
}

@layer utilities {
  .font-mono { font-family: 'JetBrains Mono', monospace; }
  .glow-sm { box-shadow: 0 0 15px -3px hsl(var(--glow) / 0.15); }
  .glow-md { box-shadow: 0 0 30px -5px hsl(var(--glow) / 0.2); }
  .glass { @apply bg-card/80 backdrop-blur-sm border border-border/50; }
}
```

### Tailwind Config

**config/tailwind.config.js** — port from `project-blueprint-studio/tailwind.config.ts`:

- Extended font families: Inter (sans), JetBrains Mono (mono)
- All semantic color tokens mapped to CSS variables via `hsl(var(--token))`
- Colors: border, input, ring, background, foreground, primary, secondary, destructive, muted, accent, popover, card, sidebar (with sub-tokens), surface, surface-hover, glow, success, warning, info
- Border radius tokens: lg, md, sm (based on `--radius`)
- Keyframes: `pulse-glow` (`0%,100%` opacity 0.4, `50%` opacity 1)
- Animations: `pulse-glow: pulse-glow 2s ease-in-out infinite`
- Container: centered, 2rem padding, max 1400px at 2xl

### Google Fonts

Add to `app/views/layouts/application.html.erb` `<head>`:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
```

Or use the `@import` in the CSS file (already included above).

---

## 1.4 Dependencies & Configuration

### Gemfile Additions

```ruby
gem "pg", "~> 1.5"                    # PostgreSQL adapter
gem "bcrypt", "~> 3.1.7"              # Uncomment existing line for has_secure_password
gem "faraday", "~> 2.9"               # HTTP client for RAG service
gem "tailwindcss-rails", "~> 3.0"     # Tailwind CSS integration
```

### Lucide Icons

Options (choose one):
1. **CDN via importmap** — Pin `lucide` in `config/importmap.rb` and use via Stimulus controllers
2. **SVG partials** — Create `app/views/shared/icons/` with individual SVG partials for each icon used

Recommended: **SVG partials** — Simpler, no JS dependency, works with ERB naturally. Create a helper method `icon(name, classes: "h-4 w-4")` that renders the SVG inline.

Icons needed from the reference app:
- Navigation: `LayoutDashboard`, `Upload`, `Brain`, `Search`, `FileText`, `Activity`, `ChevronLeft`, `ChevronRight`
- Dashboard: `Heart`, `Database`, `Cpu`, `Zap`, `Clock`, `Layers`
- Login: `ArrowLeft`, `Eye`, `EyeOff`
- Landing: `Sparkles`, `Shield`, `BarChart3`, `TrendingUp`, `TrendingDown`, `Minus`
- Estimate: `Plus`, `Trash2`, `Edit3`, `Check`, `X`, `ChevronDown`, `ChevronUp`, `Download`
- Search: Filter icons for chunk types
- Documents: `MoreHorizontal`, `ExternalLink`

### RAG Service Configuration

**config/initializers/rag_service.rb:**
```ruby
Rails.application.config.rag_service_base_url = ENV.fetch("RAG_SERVICE_BASE_URL", "http://localhost:8000")
```

Or use Rails credentials:
```bash
rails credentials:edit
# Add:
# rag_service:
#   base_url: http://localhost:8000
```

---

## 1.5 Layouts & Shared Components

### Two Layout Templates

**app/views/layouts/public.html.erb:**
- Full-width, no sidebar
- Used for: Landing page, Login/Register
- Includes Google Fonts, Tailwind CSS, Turbo/Stimulus
- Full dark background

**app/views/layouts/application.html.erb (update):**
- Sidebar + main content area
- Renders `shared/_sidebar` partial
- Main area: `flex-1 overflow-auto` with `max-w-7xl mx-auto p-6 lg:p-8`
- Flash messages area

### Sidebar Partial

**app/views/shared/_sidebar.html.erb:**

Port from `AppSidebar.tsx`:
- 5 nav items: Dashboard, Ingesta, Estimacion, Busqueda, Estimaciones
- Collapsible with toggle button at bottom
- Active-link highlighting (use `current_page?` helper or match controller)
- Logo section with "LIDR RAG Estimator" and version
- Stimulus controller for collapse/expand with localStorage persistence

Nav items:
| Label | Path | Icon |
|-------|------|------|
| Dashboard | `/dashboard` | LayoutDashboard |
| Ingesta | `/ingestions` | Upload |
| Estimacion | `/estimations/new` | Brain |
| Busqueda | `/search` | Search |
| Estimaciones | `/documents` | FileText |

### Shared Component Partials

**app/views/shared/_page_header.html.erb:**
- Locals: `title`, `description`, `actions` (optional block)
- Flexbox layout with title/description on left, actions on right

**app/views/shared/_stat_card.html.erb:**
- Locals: `title`, `value`, `subtitle` (optional), `icon`, `variant` (default/primary/success/warning), `trend` (optional hash with value + label)
- Variant-based border and icon background colors
- Monospace value display

**app/views/shared/_status_badge.html.erb:**
- Locals: `status` (healthy/completed/processing/failed/pending)
- Color-coded badge with dot indicator
- Processing status uses `animate-pulse-glow`

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Modify | `Gemfile` |
| Modify | `config/database.yml` |
| Modify | `Dockerfile` |
| Modify | `config/deploy.yml` |
| Modify | `app/views/layouts/application.html.erb` |
| Modify | `.gitignore` |
| Create | `docker-compose.dev.yml` |
| Create | `docker-compose.prod.yml` |
| Create | `.env.development` |
| Create | `.env.production.sample` |
| Create | `config/tailwind.config.js` |
| Create | `app/assets/stylesheets/application.tailwind.css` |
| Create | `config/initializers/rag_service.rb` |
| Create | `app/views/layouts/public.html.erb` |
| Create | `app/views/shared/_sidebar.html.erb` |
| Create | `app/views/shared/_page_header.html.erb` |
| Create | `app/views/shared/_stat_card.html.erb` |
| Create | `app/views/shared/_status_badge.html.erb` |
| Create | `app/helpers/icon_helper.rb` + SVG icon partials |

---

## Verification

1. `bundle install` succeeds with `pg` gem
2. `docker-compose -f docker-compose.dev.yml up db` starts PostgreSQL
3. `rails db:create db:migrate` runs without errors
4. `rails server` starts with Tailwind CSS compiling
5. Visit `http://localhost:3000/up` returns 200
6. Dark theme renders correctly (dark background, yellow primary accent)
7. Sidebar partial renders with 5 nav items
8. Layouts switch correctly between public and application
