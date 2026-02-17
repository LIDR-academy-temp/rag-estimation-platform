class CreateChunksBreakdowns < ActiveRecord::Migration[8.0]
  def change
    create_table :chunks_breakdowns do |t|
      t.references :document, null: false, foreign_key: true
      t.integer :project_overview, default: 0
      t.integer :scope_block, default: 0
      t.integer :line_item, default: 0
      t.integer :phase, default: 0
      t.integer :team_conditions, default: 0
      t.timestamps
    end
  end
end
