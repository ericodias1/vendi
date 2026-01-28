class CreateProductImports < ActiveRecord::Migration[8.1]
  def change
    create_table :product_imports do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :source_type, null: false
      t.string :status, default: 'pending', null: false
      t.jsonb :parsed_data, default: []
      t.jsonb :import_errors, default: []
      t.integer :total_rows
      t.integer :processed_rows, default: 0
      t.integer :successful_rows, default: 0
      t.integer :failed_rows, default: 0
      t.text :observations

      t.timestamps
    end

    add_index :product_imports, :status
    add_index :product_imports, :source_type
  end
end
