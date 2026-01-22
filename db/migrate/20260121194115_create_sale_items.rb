class CreateSaleItems < ActiveRecord::Migration[8.1]
  def change
    create_table :sale_items do |t|
      t.references :sale, null: false, foreign_key: true, index: false
      t.references :product, null: false, foreign_key: true, index: false
      
      # Snapshot do produto (dados históricos)
      t.string :product_name, null: false
      t.string :product_size
      t.string :product_color
      t.string :product_sku
      
      # Valores
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :subtotal, precision: 10, scale: 2, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      
      t.timestamps
    end
    
    add_index :sale_items, :sale_id
    add_index :sale_items, :product_id
  end
end
