class CreateFunctionalBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :functional_blocks do |t|
      t.references :estimation, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, default: 0
      t.timestamps
    end
  end
end
