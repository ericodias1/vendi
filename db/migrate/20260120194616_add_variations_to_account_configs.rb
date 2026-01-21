class AddVariationsToAccountConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :account_configs, :enabled_sizes, :text, array: true, default: []
    add_column :account_configs, :enabled_colors, :text, array: true, default: []
  end
end
