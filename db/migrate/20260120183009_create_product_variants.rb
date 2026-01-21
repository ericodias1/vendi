class CreateProductVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true, index: true
      t.string :size
      t.string :color
      t.string :sku
      t.decimal :price_adjustment, precision: 10, scale: 2, default: 0.0
      t.integer :stock_quantity, default: 0, null: false
      t.integer :reserved_quantity, default: 0, null: false
      t.boolean :active, default: true, null: false
      t.integer :position
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :product_variants, :active
    add_index :product_variants, :deleted_at
    add_index :product_variants, [:product_id, :size, :color], unique: true, where: "deleted_at IS NULL"
  end
end
