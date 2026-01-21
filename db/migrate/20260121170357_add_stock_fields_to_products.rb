class AddStockFieldsToProducts < ActiveRecord::Migration[8.1]
  def up
    # Adicionar campos
    add_column :products, :size, :string
    add_column :products, :stock_quantity, :integer, default: 0, null: false

    # Migrar dados de product_variants para products
    # Para produtos com variants: somar estoque, pegar primeiro size/color
    execute <<-SQL
      UPDATE products
      SET 
        size = (
          SELECT size 
          FROM product_variants 
          WHERE product_variants.product_id = products.id 
            AND product_variants.discarded_at IS NULL
            AND product_variants.size IS NOT NULL
          ORDER BY product_variants.position NULLS LAST, product_variants.created_at
          LIMIT 1
        ),
        color = COALESCE(
          products.color,
          (
            SELECT color 
            FROM product_variants 
            WHERE product_variants.product_id = products.id 
              AND product_variants.discarded_at IS NULL
              AND product_variants.color IS NOT NULL
            ORDER BY product_variants.position NULLS LAST, product_variants.created_at
            LIMIT 1
          )
        ),
        stock_quantity = COALESCE(
          (
            SELECT SUM(stock_quantity)
            FROM product_variants
            WHERE product_variants.product_id = products.id
              AND product_variants.discarded_at IS NULL
          ),
          0
        )
      WHERE EXISTS (
        SELECT 1 
        FROM product_variants 
        WHERE product_variants.product_id = products.id
          AND product_variants.discarded_at IS NULL
      );
    SQL

    # Para produtos sem variants, stock_quantity já é 0 por default
  end

  def down
    remove_column :products, :size
    remove_column :products, :stock_quantity
  end
end
