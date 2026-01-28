class AddLastSoldAtToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :last_sold_at, :datetime
    add_index :products, :last_sold_at

    # Popular dados existentes
    reversible do |dir|
      dir.up do
        Product.find_each do |product|
          last_sale = product.stock_movements
                             .where(movement_type: 'sale')
                             .order(created_at: :desc)
                             .first
          if last_sale
            product.update_column(:last_sold_at, last_sale.created_at)
          end
        end
      end
    end
  end
end

