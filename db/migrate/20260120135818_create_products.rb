class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.text :description
      t.string :sku
      t.string :supplier_code
      t.decimal :base_price, precision: 10, scale: 2
      t.decimal :cost_price, precision: 10, scale: 2
      t.string :category
      t.string :brand
      t.string :color
      t.string :material
      t.boolean :active, default: true, null: false
      t.integer :position
      t.jsonb :custom_fields, default: {}
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :products, :account_id
    add_index :products, [:account_id, :sku], unique: true, where: "sku IS NOT NULL"
    add_index :products, :active
    add_index :products, :deleted_at
  end
end
