class AddDiscardedAtToProductVariants < ActiveRecord::Migration[8.1]
  def up
    # Adicionar coluna discarded_at
    add_column :product_variants, :discarded_at, :datetime

    # Migrar dados de deleted_at para discarded_at
    execute <<-SQL
      UPDATE product_variants
      SET discarded_at = deleted_at
      WHERE deleted_at IS NOT NULL
    SQL

    # Remover índice antigo de deleted_at
    remove_index :product_variants, :deleted_at

    # Remover índice único que usa deleted_at
    remove_index :product_variants, name: "index_product_variants_on_product_id_and_size_and_color"

    # Remover coluna deleted_at
    remove_column :product_variants, :deleted_at

    # Adicionar índice de discarded_at
    add_index :product_variants, :discarded_at

    # Recriar índice único usando discarded_at
    add_index :product_variants, [:product_id, :size, :color], 
              unique: true, 
              name: "index_product_variants_on_product_id_and_size_and_color",
              where: "discarded_at IS NULL"
  end

  def down
    # Adicionar coluna deleted_at
    add_column :product_variants, :deleted_at, :datetime

    # Migrar dados de discarded_at para deleted_at
    execute <<-SQL
      UPDATE product_variants
      SET deleted_at = discarded_at
      WHERE discarded_at IS NOT NULL
    SQL

    # Remover índice de discarded_at
    remove_index :product_variants, :discarded_at

    # Remover índice único que usa discarded_at
    remove_index :product_variants, name: "index_product_variants_on_product_id_and_size_and_color"

    # Remover coluna discarded_at
    remove_column :product_variants, :discarded_at

    # Adicionar índice de deleted_at
    add_index :product_variants, :deleted_at

    # Recriar índice único usando deleted_at
    add_index :product_variants, [:product_id, :size, :color], 
              unique: true, 
              name: "index_product_variants_on_product_id_and_size_and_color",
              where: "deleted_at IS NULL"
  end
end
