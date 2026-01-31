# frozen_string_literal: true

class AddNameNormalizationToProductImports < ActiveRecord::Migration[8.0]
  def change
    add_column :product_imports, :name_normalization, :string
  end
end
