# frozen_string_literal: true

class AddProductImportIdToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :product_import, null: true, foreign_key: true
  end
end
