class AddErrorMessageToEstimations < ActiveRecord::Migration[8.0]
  def change
    add_column :estimations, :error_message, :text
  end
end
