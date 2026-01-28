class AddHighProfitMarginThresholdToAccountConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :account_configs, :high_profit_margin_threshold, :decimal, precision: 5, scale: 2, default: 50.0
  end
end
