# Phase 5 — Backend Logic & Controllers

**Objective:** Wire all static views to real database queries, implement CRUD, filtering, pagination, and prepare the controller actions for RAG integration.

**Dependencies:** Phase 3 (models), Phase 4 (views)

---

## 5.1 DashboardController

**app/controllers/dashboard_controller.rb:**

```ruby
class DashboardController < ApplicationController
  def index
    @document_stats = {
      total: Document.count,
      completed: Document.where(status: "completed").count,
      processing: Document.where(status: "processing").count,
      failed: Document.where(status: "failed").count
    }

    @chunk_distribution = ChunksBreakdown.pluck(
      Arel.sql("SUM(project_overview), SUM(scope_block), SUM(line_item), SUM(phase), SUM(team_conditions)")
    ).first

    @total_chunks = @chunk_distribution&.compact&.sum || 0

    @recent_ingestions = Document.includes(:chunks_breakdown)
                                .recent
                                .limit(5)

    # Placeholders until RAG integration (Phase 6)
    @health_status = nil
    @search_metrics = { total: 0, avg_latency: 0 }
  end
end
```

---

## 5.2 IngestionsController

**app/controllers/ingestions_controller.rb:**

```ruby
class IngestionsController < ApplicationController
  def index
    @documents = current_user.documents
                             .includes(:chunks_breakdown)
                             .recent
                             .limit(20)
  end

  def create
    raw_json = params[:raw_json]

    # Validate JSON
    parsed = JSON.parse(raw_json)
    title = parsed.dig("quote", "project", "title") || "Sin titulo"

    @document = current_user.documents.build(
      title: title,
      raw_json: raw_json,
      status: "pending",
      technologies: parsed.dig("quote", "scope_blocks")&.flat_map { |b| b["technologies"] || [] }&.uniq || [],
      currency: parsed.dig("quote", "currency") || "EUR"
    )

    if @document.save
      # Phase 6: will call RagServiceClient#ingest here
      redirect_to ingestions_path, notice: "Presupuesto enviado para ingesta"
    else
      @documents = current_user.documents.includes(:chunks_breakdown).recent.limit(20)
      render :index, status: :unprocessable_entity
    end
  rescue JSON::ParserError
    redirect_to ingestions_path, alert: "JSON invalido"
  end
end
```

---

## 5.3 DocumentsController

**app/controllers/documents_controller.rb:**

### Pagination

Add `pagy` gem to Gemfile:
```ruby
gem "pagy", "~> 9.0"
```

Include in `ApplicationController`:
```ruby
include Pagy::Backend
# In ApplicationHelper:
include Pagy::Frontend
```

### Controller

```ruby
class DocumentsController < ApplicationController
  def index
    scope = current_user.documents.includes(:chunks_breakdown).recent
    scope = scope.search_by_title(params[:q]) if params[:q].present?

    @pagy, @documents = pagy(scope, limit: 15)
  end

  def show
    @estimation = Estimation.includes(
      functional_blocks: :tasks,
      references: []
    ).find(params[:id])
  end

  def destroy
    @document = current_user.documents.find(params[:id])
    # Phase 6: will call RagServiceClient#delete_document here
    @document.destroy
    redirect_to documents_path, notice: "Documento eliminado"
  end
end
```

---

## 5.4 EstimationsController

**app/controllers/estimations_controller.rb:**

```ruby
class EstimationsController < ApplicationController
  def new
    @estimation = Estimation.new
    @estimation.functional_blocks.build.tasks.build
  end

  def create
    @estimation = current_user.estimations.build(estimation_params)
    @estimation.status = "draft"

    if @estimation.save
      # Phase 6: will call RagServiceClient#estimate here
      redirect_to document_path(@estimation), notice: "Estimacion creada"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @estimation = Estimation.includes(
      functional_blocks: :tasks,
      references: []
    ).find(params[:id])
  end

  private

  def estimation_params
    params.require(:estimation).permit(
      :title, :description, :global_rate, :currency,
      raw_transcriptions: [],
      functional_blocks_attributes: [
        :id, :name, :position, :_destroy,
        tasks_attributes: [
          :id, :name, :hours_optimistic, :hours_expected,
          :hours_pessimistic, :rate, :position, :_destroy
        ]
      ]
    )
  end
end
```

---

## 5.5 SearchController

**app/controllers/search_controller.rb:**

```ruby
class SearchController < ApplicationController
  def index
    @query = params[:q]
    @chunk_types = params[:chunk_types] || []
    @results = [] # Phase 6: will call RagServiceClient#search here
  end
end
```

---

## 5.6 Turbo Frame IDs

Add frame IDs to key view sections for Turbo updates (Phase 7):

| Section | Frame ID | View File |
|---------|----------|-----------|
| Ingestion history | `ingestion_history` | `ingestions/index` |
| Documents table | `documents_table` | `documents/index` |
| Search results | `search_results` | `search/index` |
| Dashboard panels | `dashboard_health`, `dashboard_chunks`, `dashboard_recent` | `dashboard/index` |

---

## 5.7 Helper Methods

**app/helpers/application_helper.rb:**

```ruby
module ApplicationHelper
  include Pagy::Frontend

  def format_currency(amount, currency = "EUR")
    return "-" unless amount
    symbol = currency == "EUR" ? "€" : currency
    "#{number_with_delimiter(amount.round(0))}#{symbol}"
  end

  def confidence_color(level)
    case level
    when "high" then "text-success"
    when "medium" then "text-warning"
    when "low" then "text-destructive"
    else "text-muted-foreground"
    end
  end

  def score_color(score)
    case
    when score >= 0.8 then "text-success"
    when score >= 0.65 then "text-warning"
    else "text-muted-foreground"
    end
  end

  def score_bg_color(score)
    case
    when score >= 0.8 then "bg-success/10 text-success"
    when score >= 0.65 then "bg-warning/10 text-warning"
    else "bg-muted text-muted-foreground"
    end
  end

  def chunk_type_color(type)
    {
      "project_overview" => "bg-primary",
      "scope_block" => "bg-info",
      "line_item" => "bg-success",
      "phase" => "bg-warning",
      "team_conditions" => "bg-destructive"
    }[type] || "bg-muted"
  end
end
```

---

## 5.8 Flash Messages

Add a shared partial for flash messages:

**app/views/shared/_flash.html.erb:**
- Success: green border, success text
- Alert/Error: red border, destructive text
- Auto-dismiss after 5 seconds (Stimulus controller or CSS animation)

Include in application layout before `yield`.

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Modify | `Gemfile` (add pagy) |
| Modify | `app/controllers/dashboard_controller.rb` |
| Modify | `app/controllers/ingestions_controller.rb` |
| Modify | `app/controllers/documents_controller.rb` |
| Modify | `app/controllers/estimations_controller.rb` |
| Modify | `app/controllers/search_controller.rb` |
| Modify | `app/helpers/application_helper.rb` |
| Modify | `app/controllers/application_controller.rb` (include Pagy) |
| Create | `app/views/shared/_flash.html.erb` |
| Modify | All view files (add turbo_frame_tags, wire up data) |

---

## Verification

1. Dashboard loads with real aggregate data from seed
2. Ingestions page lists current user's documents
3. Creating an ingestion with valid JSON creates a document
4. Creating an ingestion with invalid JSON shows error
5. Documents page lists with search filtering working
6. Documents page pagination works
7. Document deletion removes the record
8. Estimation creation persists nested blocks/tasks
9. Estimation detail shows blocks with tasks
10. Currency formatting displays correctly
11. Turbo Frame IDs are present in HTML output
