class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.uuid :external_document_id, null: true
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "pending"
      t.integer :chunks_count, default: 0
      t.decimal :budget, precision: 12, scale: 2
      t.string :currency, default: "EUR"
      t.jsonb :technologies, default: []
      t.string :duration
      t.text :raw_json
      t.references :user, null: false, foreign_key: true
      t.datetime :ingested_at
      t.timestamps
    end
    add_index :documents, :external_document_id, unique: true
    add_index :documents, :status
    add_index :documents, :created_at
  end
end
