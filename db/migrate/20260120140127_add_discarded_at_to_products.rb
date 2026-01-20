class AddDiscardedAtToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :discarded_at, :datetime
  end
end
