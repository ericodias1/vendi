# frozen_string_literal: true

module Backoffice
  class AccountConfigsController < BaseController
    before_action :set_account_config

    def show
    end

    def edit
    end

    def update
      if @account_config.update(account_config_params)
        redirect_to backoffice_account_config_path, notice: "Configurações atualizadas com sucesso"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_account_config
      @account_config = current_account.account_config || current_account.create_account_config
    end

    def account_config_params
      params.require(:account_config).permit(
        :daily_goal,
        :weekly_goal,
        :monthly_goal,
        :stock_alerts_enabled,
        :stock_alert_threshold,
        :high_profit_margin_threshold,
        :pix_enabled,
        :card_enabled,
        :cash_enabled,
        :fiado_enabled,
        :require_customer,
        :auto_send_payment_link,
        enabled_sizes: [],
        enabled_colors: []
      )
    end
  end
end
