class AddSupplierToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :supplier, :string
    add_column :products, :parameterized_supplier, :string
    add_index :products, :parameterized_supplier
  end
end
