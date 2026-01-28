class AddCostPriceToSaleItems < ActiveRecord::Migration[8.1]
  def change
    add_column :sale_items, :cost_price, :decimal, precision: 10, scale: 2

    # Popular dados existentes
    reversible do |dir|
      dir.up do
        SaleItem.find_each do |item|
          item.update_column(:cost_price, item.product&.cost_price) if item.product
        end
      end
    end
  end
end

