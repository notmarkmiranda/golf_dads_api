class AddInviteCodeToGroups < ActiveRecord::Migration[8.1]
  def up
    # Add the column (nullable for now)
    add_column :groups, :invite_code, :string

    # Generate invite codes for existing groups
    Group.reset_column_information
    Group.find_each do |group|
      group.update_column(:invite_code, generate_invite_code)
    end

    # Make it not nullable and add unique index
    change_column_null :groups, :invite_code, false
    add_index :groups, :invite_code, unique: true
  end

  def down
    remove_index :groups, :invite_code
    remove_column :groups, :invite_code
  end

  private

  def generate_invite_code
    # Generate a random 8-character alphanumeric code
    SecureRandom.alphanumeric(8).upcase
  end
end
