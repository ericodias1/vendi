class AddParameterizedNameToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :parameterized_name, :string
    add_index :products, [:account_id, :parameterized_name], name: 'index_products_on_account_id_and_parameterized_name'
  end
end
