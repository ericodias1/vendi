# frozen_string_literal: true

class AddProductImportSettingsToAccountConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :account_configs, :product_import_auto_generate_sku, :boolean, default: false, null: false
    add_column :account_configs, :product_import_ignore_errors, :boolean, default: true, null: false
    add_column :account_configs, :product_import_prevent_duplicate_names, :boolean, default: true, null: false
  end
end
