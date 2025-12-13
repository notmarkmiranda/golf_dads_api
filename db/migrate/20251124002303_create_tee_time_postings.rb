class CreateTeeTimePostings < ActiveRecord::Migration[8.1]
  def change
    create_table :tee_time_postings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: true, foreign_key: true
      t.datetime :tee_time, null: false
      t.string :course_name, null: false
      t.integer :available_spots, null: false
      t.integer :total_spots
      t.text :notes

      t.timestamps
    end

    add_index :tee_time_postings, :tee_time
    add_index :tee_time_postings, [ :user_id, :tee_time ]
    add_index :tee_time_postings, [ :group_id, :tee_time ]
  end
end
