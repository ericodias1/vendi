class AddProductsViewModeToAccountConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :account_configs, :products_view_mode, :string, default: "cards", null: false
  end
end
