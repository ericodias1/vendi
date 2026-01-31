# frozen_string_literal: true

class AddProductImportNameNormalizationToAccountConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :account_configs, :product_import_name_normalization, :string
  end
end
