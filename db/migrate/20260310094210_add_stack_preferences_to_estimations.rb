class AddStackPreferencesToEstimations < ActiveRecord::Migration[8.0]
  def change
    add_column :estimations, :frontend_stack, :jsonb, default: []
    add_column :estimations, :backend_stack, :jsonb, default: []
  end
end
