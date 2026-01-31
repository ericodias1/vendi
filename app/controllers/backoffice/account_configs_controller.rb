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
        respond_to do |format|
          format.html { redirect_to backoffice_account_config_path, notice: "Configurações atualizadas com sucesso" }
          format.json { render json: automatic_pricing_json, status: :ok }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: { errors: @account_config.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_account_config
      @account_config = current_account.account_config || current_account.create_account_config
    end

    def automatic_pricing_json
      {
        automatic_pricing_enabled: @account_config.automatic_pricing_enabled,
        automatic_pricing_markup_percent: @account_config.automatic_pricing_markup_percent&.to_f,
        automatic_pricing_rounding_mode: @account_config.automatic_pricing_rounding_mode,
        automatic_pricing_use_csv_when_cost_empty: @account_config.automatic_pricing_use_csv_when_cost_empty
      }
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
        :automatic_pricing_enabled,
        :automatic_pricing_markup_percent,
        :automatic_pricing_rounding_mode,
        :automatic_pricing_use_csv_when_cost_empty,
        :product_import_auto_generate_sku,
        :product_import_ignore_errors,
        :product_import_prevent_duplicate_names,
        :product_import_name_normalization,
        enabled_sizes: [],
        enabled_colors: []
      )
    end
  end
end
