# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_27_133416) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chunks_breakdowns", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.integer "project_overview", default: 0
    t.integer "scope_block", default: 0
    t.integer "line_item", default: 0
    t.integer "phase", default: 0
    t.integer "team_conditions", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_chunks_breakdowns_on_document_id"
  end

  create_table "documents", force: :cascade do |t|
    t.uuid "external_document_id"
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "pending", null: false
    t.integer "chunks_count", default: 0
    t.decimal "budget", precision: 12, scale: 2
    t.string "currency", default: "EUR"
    t.jsonb "technologies", default: []
    t.string "duration"
    t.text "raw_json"
    t.bigint "user_id", null: false
    t.datetime "ingested_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_documents_on_created_at"
    t.index ["external_document_id"], name: "index_documents_on_external_document_id", unique: true
    t.index ["status"], name: "index_documents_on_status"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "estimations", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "draft", null: false
    t.bigint "user_id", null: false
    t.decimal "global_rate", precision: 10, scale: 2, default: "150.0"
    t.string "currency", default: "EUR"
    t.float "confidence_score"
    t.string "confidence_level"
    t.jsonb "technologies", default: []
    t.decimal "total_hours_optimistic", precision: 10, scale: 2
    t.decimal "total_hours_expected", precision: 10, scale: 2
    t.decimal "total_hours_pessimistic", precision: 10, scale: 2
    t.decimal "total_cost_optimistic", precision: 12, scale: 2
    t.decimal "total_cost_expected", precision: 12, scale: 2
    t.decimal "total_cost_pessimistic", precision: 12, scale: 2
    t.jsonb "raw_transcriptions", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "error_message"
    t.index ["created_at"], name: "index_estimations_on_created_at"
    t.index ["status"], name: "index_estimations_on_status"
    t.index ["user_id"], name: "index_estimations_on_user_id"
  end

  create_table "functional_blocks", force: :cascade do |t|
    t.bigint "estimation_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estimation_id"], name: "index_functional_blocks_on_estimation_id"
  end

  create_table "references", force: :cascade do |t|
    t.bigint "estimation_id", null: false
    t.string "title"
    t.float "similarity_score"
    t.decimal "cost", precision: 12, scale: 2
    t.jsonb "technologies", default: []
    t.uuid "chunk_id"
    t.string "chunk_type"
    t.text "content_preview"
    t.string "currency", default: "EUR"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estimation_id"], name: "index_references_on_estimation_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "functional_block_id", null: false
    t.string "name", null: false
    t.decimal "hours_optimistic", precision: 8, scale: 2, default: "0.0"
    t.decimal "hours_expected", precision: 8, scale: 2, default: "0.0"
    t.decimal "hours_pessimistic", precision: 8, scale: 2, default: "0.0"
    t.decimal "rate", precision: 10, scale: 2
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["functional_block_id"], name: "index_tasks_on_functional_block_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "chunks_breakdowns", "documents"
  add_foreign_key "documents", "users"
  add_foreign_key "estimations", "users"
  add_foreign_key "functional_blocks", "estimations"
  add_foreign_key "references", "estimations"
  add_foreign_key "tasks", "functional_blocks"
end
