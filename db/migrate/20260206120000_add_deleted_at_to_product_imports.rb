# frozen_string_literal: true

class AddDeletedAtToProductImports < ActiveRecord::Migration[8.0]
  def change
    add_column :product_imports, :deleted_at, :datetime
    add_index :product_imports, :deleted_at
  end
end
