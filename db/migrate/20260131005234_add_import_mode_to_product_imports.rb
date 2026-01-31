class AddImportModeToProductImports < ActiveRecord::Migration[8.1]
  def change
    add_column :product_imports, :import_mode, :string, default: "create_only", null: false
  end
end
