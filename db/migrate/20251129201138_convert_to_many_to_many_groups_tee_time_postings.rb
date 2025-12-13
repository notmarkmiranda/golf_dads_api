class ConvertToManyToManyGroupsTeeTimePostings < ActiveRecord::Migration[8.1]
  def up
    # Create join table for has_and_belongs_to_many relationship
    create_table :groups_tee_time_postings, id: false do |t|
      t.belongs_to :group, null: false, foreign_key: true
      t.belongs_to :tee_time_posting, null: false, foreign_key: true
    end

    # Add indexes for better query performance
    add_index :groups_tee_time_postings, [ :group_id, :tee_time_posting_id ],
              unique: true,
              name: 'index_groups_tee_time_postings_on_group_and_posting'
    add_index :groups_tee_time_postings, [ :tee_time_posting_id, :group_id ],
              name: 'index_groups_tee_time_postings_on_posting_and_group'

    # Migrate existing data from group_id column to join table
    # Only migrate records that have a group_id
    execute <<-SQL
      INSERT INTO groups_tee_time_postings (group_id, tee_time_posting_id)
      SELECT group_id, id
      FROM tee_time_postings
      WHERE group_id IS NOT NULL
    SQL

    # Remove the old group_id column and its index
    remove_index :tee_time_postings, name: 'index_tee_time_postings_on_group_id_and_tee_time'
    remove_foreign_key :tee_time_postings, :groups
    remove_column :tee_time_postings, :group_id
  end

  def down
    # Add back the group_id column
    add_reference :tee_time_postings, :group, null: true, foreign_key: true
    add_index :tee_time_postings, [ :group_id, :tee_time ]

    # Migrate data back from join table to group_id column
    # Note: This will only preserve ONE group per posting (the first one)
    # Data loss is expected when rolling back a many-to-many relationship
    execute <<-SQL
      UPDATE tee_time_postings
      SET group_id = (
        SELECT group_id
        FROM groups_tee_time_postings
        WHERE groups_tee_time_postings.tee_time_posting_id = tee_time_postings.id
        LIMIT 1
      )
    SQL

    # Drop the join table
    drop_table :groups_tee_time_postings
  end
end
