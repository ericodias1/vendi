class ChangeSalesSaleNumberIndexToScopedByAccount < ActiveRecord::Migration[8.1]
  def up
    remove_index :sales, name: "index_sales_on_sale_number"
    add_index :sales, %i[account_id sale_number], unique: true, name: "index_sales_on_account_id_and_sale_number"
  end

  def down
    remove_index :sales, name: "index_sales_on_account_id_and_sale_number"
    add_index :sales, :sale_number, unique: true, name: "index_sales_on_sale_number"
  end
end
