class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :tee_time_posting, null: false, foreign_key: { on_delete: :cascade }
      t.integer :spots_reserved, null: false

      t.timestamps
    end

    add_index :reservations, [ :user_id, :tee_time_posting_id ], unique: true
  end
end
