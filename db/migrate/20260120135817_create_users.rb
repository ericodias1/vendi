class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name
      t.string :phone
      t.string :role, default: "employee"
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :users, [:email, :account_id], unique: true
    add_index :users, :account_id
    add_index :users, :active
  end
end
