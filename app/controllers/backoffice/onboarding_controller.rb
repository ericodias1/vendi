# frozen_string_literal: true

module Backoffice
  class OnboardingController < BaseController
    skip_before_action :authorize_resource

    def show
      redirect_to backoffice_root_path if current_account.onboarding_completed_at.present?

      @step = (params[:step].presence || "0").to_i
      @account = current_account
      @account_config = ensure_account_config!

      case @step
      when 1
        render :step_1
      when 2
        render :step_2
      else
        render :show
      end
    end

    def complete_step_1
      @account = current_account
      @account_config = ensure_account_config!

      if @account.update(account_step_1_params)
        @account_config.update(stock_alerts_enabled: params.dig(:account_config, :stock_alerts_enabled) == "1")
        redirect_to backoffice_onboarding_path(step: 2), notice: "Configuração salva. Vamos personalizar sua loja."
      else
        @step = 1
        render :step_1, status: :unprocessable_entity
      end
    end

    def complete_step_2
      @account = current_account
      @account_config = ensure_account_config!

      Account.transaction do
        @account_config.update!(account_config_step_2_params)
        @account.update!(onboarding_completed_at: Time.current)
      end

      redirect_to backoffice_root_path, notice: "Pronto! Vamos registrar sua primeira venda."
    rescue ActiveRecord::RecordInvalid
      @step = 2
      render :step_2, status: :unprocessable_entity
    end

    private

    def ensure_account_config!
      current_account.account_config || current_account.create_account_config!
    end

    def account_step_1_params
      params.require(:account).permit(:name, :whatsapp, :store_type)
    end

    def account_config_step_2_params
      params.require(:account_config).permit(
        :daily_goal,
        :stock_alert_threshold,
        :pix_enabled,
        :card_enabled,
        :cash_enabled,
        :fiado_enabled
      )
    end
  end
end

