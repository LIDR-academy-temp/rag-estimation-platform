class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :functional_block, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :hours_optimistic, precision: 8, scale: 2, default: 0
      t.decimal :hours_expected, precision: 8, scale: 2, default: 0
      t.decimal :hours_pessimistic, precision: 8, scale: 2, default: 0
      t.decimal :rate, precision: 10, scale: 2
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
