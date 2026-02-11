class CreateProductLabelSelections < ActiveRecord::Migration[8.1]
  def change
    create_table :product_label_selections do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end

    add_index :product_label_selections, %i[account_id product_id], unique: true
  end
end
