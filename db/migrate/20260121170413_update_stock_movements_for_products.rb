class UpdateStockMovementsForProducts < ActiveRecord::Migration[8.1]
  def up
    # Adicionar product_id (nullable inicialmente)
    add_reference :stock_movements, :product, null: true, foreign_key: true, index: true

    # Migrar dados: product_id = product_variant.product_id
    execute <<-SQL
      UPDATE stock_movements
      SET product_id = (
        SELECT product_id
        FROM product_variants
        WHERE product_variants.id = stock_movements.product_variant_id
      )
      WHERE product_variant_id IS NOT NULL;
    SQL

    # Tornar product_variant_id nullable (manter para histórico)
    change_column_null :stock_movements, :product_variant_id, true

    # Remover foreign key constraint de product_variant_id (manter coluna)
    if foreign_key_exists?(:stock_movements, :product_variants)
      remove_foreign_key :stock_movements, :product_variants
    end
  end

  def down
    # Restaurar foreign key
    unless foreign_key_exists?(:stock_movements, :product_variants)
      add_foreign_key :stock_movements, :product_variants
    end

    # Tornar product_variant_id NOT NULL novamente
    execute <<-SQL
      UPDATE stock_movements
      SET product_variant_id = (
        SELECT id
        FROM product_variants
        WHERE product_variants.product_id = stock_movements.product_id
        LIMIT 1
      )
      WHERE product_variant_id IS NULL AND product_id IS NOT NULL;
    SQL
    change_column_null :stock_movements, :product_variant_id, false

    # Remover product_id
    remove_reference :stock_movements, :product, foreign_key: true
  end
end
