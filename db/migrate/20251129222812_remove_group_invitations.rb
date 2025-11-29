class RemoveGroupInvitations < ActiveRecord::Migration[8.1]
  def up
    drop_table :group_invitations
  end

  def down
    create_table :group_invitations do |t|
      t.references :group, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.string :invitee_email, null: false
      t.string :status, null: false, default: 'pending'
      t.string :token, null: false

      t.timestamps
    end

    add_index :group_invitations, :token, unique: true
    add_index :group_invitations, [:group_id, :invitee_email, :status]
  end
end
