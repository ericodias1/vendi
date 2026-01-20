class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :whatsapp
      t.string :store_type
      t.string :logo_url
      t.string :timezone, default: "America/Sao_Paulo"
      t.boolean :active, default: true, null: false
      t.datetime :onboarding_completed_at

      t.timestamps
    end

    add_index :accounts, :slug, unique: true
    add_index :accounts, :active
  end
end
