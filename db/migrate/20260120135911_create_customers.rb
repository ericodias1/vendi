class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :cpf
      t.string :street
      t.string :number
      t.string :complement
      t.string :neighborhood
      t.string :city
      t.string :state
      t.string :zipcode
      t.text :observations
      t.boolean :active, default: true, null: false
      t.integer :total_purchases, default: 0
      t.decimal :total_spent, precision: 10, scale: 2, default: 0
      t.datetime :last_purchase_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :customers, :account_id
    add_index :customers, :active
    add_index :customers, :deleted_at
  end
end
