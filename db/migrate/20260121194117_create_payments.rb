class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :sale, null: false, foreign_key: true, index: { unique: true }
      
      # Método e status
      t.string :method, null: false
      t.string :status, null: false, default: "pending"
      
      # Valor
      t.decimal :amount, precision: 10, scale: 2, null: false
      
      # Campos específicos por método
      t.integer :installments # Para cartão
      t.string :card_last_digits # Para cartão
      t.text :pix_code # Para PIX
      
      # Dados adicionais
      t.datetime :paid_at
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :payments, :method
    add_index :payments, :status
  end
end
