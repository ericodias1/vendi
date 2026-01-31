# frozen_string_literal: true

module Backoffice
  module ProductImports
    class AutomaticPricingController < Backoffice::BaseController
      before_action :set_product_import
      before_action :set_account_config

      def show
        # Link "Configurar" usa data-turbo-frame="pricing_modal_placeholder" → retorna o modal.
        # O frame "pricing_modal_content" dentro do modal faz src=pricing_path → retorna o form.
        if request.headers["Turbo-Frame"] == "pricing_modal_content"
          render :show, layout: false
        else
          render :show_modal, layout: false
        end
      end

      def close
        # Link "Fechar" usa data-turbo-frame="pricing_modal_placeholder" → retorna frame vazio
        render :close, layout: false
      end

      def update
        if @account_config.update(account_config_pricing_params)
          @account_config.update(automatic_pricing_enabled: true)
          streams = [
            turbo_stream.replace("pricing_modal_content", partial: "backoffice/product_imports/automatic_pricing/saved", locals: { product_import: @product_import }),
            turbo_stream.append("toast-container", partial: "shared/ui/toast", locals: { type: :success, message: "Configuração salva." })
          ]
          if params[:then_apply] == "1"
            apply_service = Backoffice::ProductImports::ApplyPricingService.new(
              product_import: @product_import,
              account_config: @account_config
            )
            if apply_service.call
              @product_import.reload
              streams << turbo_stream.replace(
                "import-rows-data",
                partial: "backoffice/product_imports/import_rows_data",
                locals: { rows: @product_import.parsed_data }
              )
            end
          end
          respond_to do |format|
            format.turbo_stream { render turbo_stream: streams, status: :ok }
            format.html { redirect_to backoffice_product_import_path(@product_import), notice: "Configuração salva." }
          end
        else
          render :show, layout: false, status: :unprocessable_entity
        end
      end

      def apply
        service = Backoffice::ProductImports::ApplyPricingService.new(
          product_import: @product_import,
          account_config: @account_config
        )

        if service.call
          @product_import.reload
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.replace(
                "import-rows-data",
                partial: "backoffice/product_imports/import_rows_data",
                locals: { rows: @product_import.parsed_data }
              ), status: :ok
            end
            format.html { redirect_to backoffice_product_import_path(@product_import), notice: "Precificação aplicada." }
          end
        else
          redirect_to backoffice_product_import_path(@product_import), alert: "Não foi possível aplicar a precificação."
        end
      end

      private

      def set_product_import
        @product_import = current_account.product_imports.find(params[:product_import_id])
      end

      def set_account_config
        @account_config = current_account.account_config || current_account.build_account_config
      end

      def account_config_pricing_params
        params.require(:account_config).permit(
          :automatic_pricing_markup_percent,
          :automatic_pricing_rounding_mode,
          :automatic_pricing_use_csv_when_cost_empty
        )
      end
    end
  end
end
