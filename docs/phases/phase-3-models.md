# Phase 3 — Data Modeling & Migrations

**Status: ✅ Completed**

**Objective:** Create all ActiveRecord models and database tables representing the domain entities visible across the UI and the RAG service responses.

**Dependencies:** Phase 2 (User model exists)

**Reference:**
- `project-blueprint-studio` for UI data shapes (`EstimationDetailPage.tsx`, `DocumentsPage.tsx`, `Index.tsx`)
- `rag-estimation-service` for API response schemas (`app/api/schemas/`)

---

## 3.1 Entity Relationship Overview

```
User
 ├── has_many :documents
 └── has_many :estimations

Document
 ├── belongs_to :user
 └── has_one :chunks_breakdown

ChunksBreakdown
 └── belongs_to :document

Estimation
 ├── belongs_to :user
 ├── has_many :functional_blocks
 └── has_many :references

FunctionalBlock
 ├── belongs_to :estimation
 └── has_many :tasks

Task
 └── belongs_to :functional_block

Reference
 └── belongs_to :estimation
```

---

## 3.2 Documents Table

Represents ingested budget/quote JSON files processed by the RAG service.

```ruby
create_table :documents do |t|
  t.uuid :external_document_id, null: true          # UUID from RAG service
  t.string :title, null: false
  t.text :description
  t.string :status, null: false, default: "pending"  # pending, processing, completed, failed
  t.integer :chunks_count, default: 0
  t.decimal :budget, precision: 12, scale: 2
  t.string :currency, default: "EUR"
  t.jsonb :technologies, default: []
  t.string :duration
  t.text :raw_json                                    # Original quote JSON
  t.references :user, null: false, foreign_key: true
  t.datetime :ingested_at

  t.timestamps
end

add_index :documents, :external_document_id, unique: true
add_index :documents, :status
add_index :documents, :created_at
```

### Model

```ruby
class Document < ApplicationRecord
  belongs_to :user
  has_one :chunks_breakdown, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }
  scope :search_by_title, ->(q) { where("title ILIKE ?", "%#{q}%") if q.present? }
end
```

---

## 3.3 Chunks Breakdowns Table

Stores the per-type chunk counts after ingestion.

```ruby
create_table :chunks_breakdowns do |t|
  t.references :document, null: false, foreign_key: true
  t.integer :project_overview, default: 0
  t.integer :scope_block, default: 0
  t.integer :line_item, default: 0
  t.integer :phase, default: 0
  t.integer :team_conditions, default: 0

  t.timestamps
end
```

### Model

```ruby
class ChunksBreakdown < ApplicationRecord
  belongs_to :document

  def total
    project_overview + scope_block + line_item + phase + team_conditions
  end
end
```

---

## 3.4 Estimations Table

Represents a complete estimation generated from transcriptions via the RAG service.

```ruby
create_table :estimations do |t|
  t.string :title, null: false
  t.text :description
  t.string :status, null: false, default: "draft"    # draft, processing, completed, failed
  t.references :user, null: false, foreign_key: true
  t.decimal :global_rate, precision: 10, scale: 2, default: 150.0
  t.string :currency, default: "EUR"
  t.float :confidence_score
  t.string :confidence_level                          # low, medium, high
  t.jsonb :technologies, default: []
  t.decimal :total_hours_optimistic, precision: 10, scale: 2
  t.decimal :total_hours_expected, precision: 10, scale: 2
  t.decimal :total_hours_pessimistic, precision: 10, scale: 2
  t.decimal :total_cost_optimistic, precision: 12, scale: 2
  t.decimal :total_cost_expected, precision: 12, scale: 2
  t.decimal :total_cost_pessimistic, precision: 12, scale: 2
  t.jsonb :raw_transcriptions, default: []            # Array of transcription strings

  t.timestamps
end

add_index :estimations, :status
add_index :estimations, :created_at
```

### Model

```ruby
class Estimation < ApplicationRecord
  belongs_to :user
  has_many :functional_blocks, -> { order(:position) }, dependent: :destroy
  has_many :tasks, through: :functional_blocks
  has_many :references, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: %w[draft processing completed failed] }

  accepts_nested_attributes_for :functional_blocks, allow_destroy: true

  scope :recent, -> { order(created_at: :desc) }
end
```

---

## 3.5 Functional Blocks Table

Groups of tasks within an estimation (e.g., "Frontend", "Backend", "Infrastructure").

```ruby
create_table :functional_blocks do |t|
  t.references :estimation, null: false, foreign_key: true
  t.string :name, null: false
  t.integer :position, default: 0

  t.timestamps
end
```

### Model

```ruby
class FunctionalBlock < ApplicationRecord
  belongs_to :estimation
  has_many :tasks, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true

  accepts_nested_attributes_for :tasks, allow_destroy: true

  def total_hours_optimistic
    tasks.sum(:hours_optimistic)
  end

  def total_hours_expected
    tasks.sum(:hours_expected)
  end

  def total_hours_pessimistic
    tasks.sum(:hours_pessimistic)
  end

  def total_cost(estimate_type = :expected)
    tasks.sum { |t| t.send("hours_#{estimate_type}") * t.rate }
  end
end
```

---

## 3.6 Tasks Table

Individual tasks within a functional block, with 3-point estimates.

```ruby
create_table :tasks do |t|
  t.references :functional_block, null: false, foreign_key: true
  t.string :name, null: false
  t.decimal :hours_optimistic, precision: 8, scale: 2, default: 0
  t.decimal :hours_expected, precision: 8, scale: 2, default: 0
  t.decimal :hours_pessimistic, precision: 8, scale: 2, default: 0
  t.decimal :rate, precision: 10, scale: 2                          # Per-task rate override
  t.integer :position, default: 0

  t.timestamps
end
```

### Model

```ruby
class Task < ApplicationRecord
  belongs_to :functional_block

  validates :name, presence: true

  def cost(estimate_type = :expected)
    send("hours_#{estimate_type}") * effective_rate
  end

  def effective_rate
    rate || functional_block.estimation.global_rate
  end
end
```

---

## 3.7 References Table

Historical similar projects found during estimation.

```ruby
create_table :references do |t|
  t.references :estimation, null: false, foreign_key: true
  t.string :title
  t.float :similarity_score
  t.decimal :cost, precision: 12, scale: 2
  t.jsonb :technologies, default: []
  t.uuid :chunk_id
  t.string :chunk_type
  t.text :content_preview
  t.string :currency, default: "EUR"

  t.timestamps
end
```

### Model

```ruby
class Reference < ApplicationRecord
  belongs_to :estimation

  scope :by_similarity, -> { order(similarity_score: :desc) }
end
```

---

## 3.8 Seed Data

**db/seeds.rb** — Create demo data matching the React mockups:

- 1 demo user: `demo@lidr.co` / `password123`
- 4 documents with varied statuses (completed, completed, processing, failed)
- Chunks breakdowns for completed documents
- 2 completed estimations with:
  - 3-4 functional blocks each
  - 3-5 tasks per block with 3-point estimates
  - 5+ references each
- Realistic Spanish project names matching the React app data

---

## Files to Create

| Action | File |
|--------|------|
| Create | `db/migrate/xxx_create_documents.rb` |
| Create | `db/migrate/xxx_create_chunks_breakdowns.rb` |
| Create | `db/migrate/xxx_create_estimations.rb` |
| Create | `db/migrate/xxx_create_functional_blocks.rb` |
| Create | `db/migrate/xxx_create_tasks.rb` |
| Create | `db/migrate/xxx_create_references.rb` |
| Create | `app/models/document.rb` |
| Create | `app/models/chunks_breakdown.rb` |
| Create | `app/models/estimation.rb` |
| Create | `app/models/functional_block.rb` |
| Create | `app/models/task.rb` |
| Create | `app/models/reference.rb` |
| Modify | `app/models/user.rb` (add associations) |
| Create | `db/seeds.rb` |

---

## Verification

1. `rails db:migrate` runs all 6 migrations without errors
2. `rails db:seed` creates demo data
3. `rails console`: verify associations work (`User.first.documents`, `Estimation.first.functional_blocks.first.tasks`, etc.)
4. All validations pass for valid data, reject invalid data
5. Indexes are present on foreign keys and status columns
