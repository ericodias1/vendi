class AddParameterizedCategoryToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :parameterized_category, :string
    add_index :products, :parameterized_category

    # Popular dados existentes
    reversible do |dir|
      dir.up do
        Product.find_each do |product|
          product.update_column(:parameterized_category, product.category&.parameterize)
        end
      end
    end
  end
end

