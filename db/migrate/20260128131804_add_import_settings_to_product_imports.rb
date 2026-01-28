class AddImportSettingsToProductImports < ActiveRecord::Migration[8.1]
  def change
    add_column :product_imports, :auto_generate_sku, :boolean, default: false, null: false
    add_column :product_imports, :ignore_errors, :boolean, default: true, null: false
    add_column :product_imports, :prevent_duplicate_names, :boolean, default: true, null: false
  end
end
