class AddFiadoEnabledToAccountConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :account_configs, :fiado_enabled, :boolean, default: false
  end
end
