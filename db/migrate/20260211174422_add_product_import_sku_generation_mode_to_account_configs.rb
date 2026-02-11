class AddProductImportSkuGenerationModeToAccountConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :account_configs, :product_import_sku_generation_mode, :string, default: "name_prefix"
  end
end
