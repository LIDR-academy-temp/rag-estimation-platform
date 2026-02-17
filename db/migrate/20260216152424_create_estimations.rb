class CreateEstimations < ActiveRecord::Migration[8.0]
  def change
    create_table :estimations do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.references :user, null: false, foreign_key: true
      t.decimal :global_rate, precision: 10, scale: 2, default: 150.0
      t.string :currency, default: "EUR"
      t.float :confidence_score
      t.string :confidence_level
      t.jsonb :technologies, default: []
      t.decimal :total_hours_optimistic, precision: 10, scale: 2
      t.decimal :total_hours_expected, precision: 10, scale: 2
      t.decimal :total_hours_pessimistic, precision: 10, scale: 2
      t.decimal :total_cost_optimistic, precision: 12, scale: 2
      t.decimal :total_cost_expected, precision: 12, scale: 2
      t.decimal :total_cost_pessimistic, precision: 12, scale: 2
      t.jsonb :raw_transcriptions, default: []
      t.timestamps
    end
    add_index :estimations, :status
    add_index :estimations, :created_at
  end
end
