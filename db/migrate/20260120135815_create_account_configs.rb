class CreateAccountConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :account_configs do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.decimal :daily_goal, precision: 10, scale: 2, default: 0
      t.decimal :weekly_goal, precision: 10, scale: 2
      t.decimal :monthly_goal, precision: 10, scale: 2
      t.boolean :stock_alerts_enabled, default: true
      t.integer :stock_alert_threshold, default: 3
      t.boolean :pix_enabled, default: true
      t.boolean :card_enabled, default: true
      t.boolean :cash_enabled, default: true
      t.boolean :credit_enabled, default: false
      t.boolean :require_customer, default: false
      t.boolean :auto_send_payment_link, default: false
      t.jsonb :additional_settings, default: {}

      t.timestamps
    end

    add_index :account_configs, :account_id, unique: true
  end
end
