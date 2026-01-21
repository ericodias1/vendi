class RemoveProductVariants < ActiveRecord::Migration[8.1]
  def up
    # Remover foreign key de stock_movements -> product_variants (se existir)
    if foreign_key_exists?(:stock_movements, :product_variants)
      remove_foreign_key :stock_movements, :product_variants
    end

    # Remover índice de product_variant_id em stock_movements (se existir)
    if index_exists?(:stock_movements, :product_variant_id)
      remove_index :stock_movements, :product_variant_id
    end

    # Remover coluna product_variant_id de stock_movements (se existir)
    if column_exists?(:stock_movements, :product_variant_id)
      remove_column :stock_movements, :product_variant_id
    end

    # Remover foreign key de product_variants -> products (se existir)
    if foreign_key_exists?(:product_variants, :products)
      remove_foreign_key :product_variants, :products
    end

    # Remover tabela product_variants completamente
    drop_table :product_variants if table_exists?(:product_variants)
  end

  def down
    # Recriar tabela product_variants (estrutura básica para rollback)
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
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :product_variants, :active
    add_index :product_variants, :discarded_at
    add_index :product_variants, [:product_id, :size, :color], unique: true, where: "discarded_at IS NULL"

    # Recriar coluna product_variant_id em stock_movements (se necessário)
    # Nota: Esta migration assume que product_id já existe em stock_movements
    # Se não existir, será necessário executar as migrations anteriores primeiro
  end
end
