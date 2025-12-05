class ChangeAvailableSpotsToNullable < ActiveRecord::Migration[8.1]
  def change
    # Remove null constraint and set default to 0
    # The available_spots column is still used but we calculate it dynamically in the model
    # Setting a default of 0 ensures legacy code doesn't break
    change_column_null :tee_time_postings, :available_spots, true
    change_column_default :tee_time_postings, :available_spots, from: nil, to: 0
  end
end
