class CreateReferences < ActiveRecord::Migration[8.0]
  def change
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
  end
end
