class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
      t.references :customer, null: true, foreign_key: true, index: false
      t.string :sale_number, null: false
      t.string :status, default: "draft", null: false
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :discount_percentage, precision: 5, scale: 2
      t.decimal :total_amount, precision: 10, scale: 2, default: 0
      t.integer :total_items, default: 0
      t.text :observations
      t.string :payment_link_token
      t.datetime :payment_link_sent_at
      t.datetime :completed_at
      t.datetime :cancelled_at
      t.text :cancellation_reason

      t.timestamps
    end

    add_index :sales, :account_id
    add_index :sales, :user_id
    add_index :sales, :customer_id
    add_index :sales, :sale_number, unique: true
    add_index :sales, :status
    add_index :sales, :created_at
  end
end
