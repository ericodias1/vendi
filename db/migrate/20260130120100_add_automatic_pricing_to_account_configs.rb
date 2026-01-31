# frozen_string_literal: true

class AddAutomaticPricingToAccountConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :account_configs, :automatic_pricing_enabled, :boolean, default: false, null: false
    add_column :account_configs, :automatic_pricing_markup_percent, :decimal, precision: 5, scale: 2
    add_column :account_configs, :automatic_pricing_rounding_mode, :string
    add_column :account_configs, :automatic_pricing_use_csv_when_cost_empty, :boolean, default: false, null: false
  end
end
