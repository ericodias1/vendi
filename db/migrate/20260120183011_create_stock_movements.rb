class CreateStockMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_movements do |t|
      t.references :product_variant, null: false, foreign_key: true, index: true
      t.references :account, null: false, foreign_key: true, index: true
      t.references :user, null: true, foreign_key: true
      t.string :movement_type, null: false
      t.integer :quantity_change, null: false
      t.integer :quantity_before, null: false
      t.integer :quantity_after, null: false
      t.text :observations
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :stock_movements, :movement_type
    add_index :stock_movements, :created_at
  end
end
