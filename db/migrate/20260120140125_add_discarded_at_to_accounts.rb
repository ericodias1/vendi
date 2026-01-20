class AddDiscardedAtToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :discarded_at, :datetime
  end
end
