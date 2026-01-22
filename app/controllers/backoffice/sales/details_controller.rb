# frozen_string_literal: true

module Backoffice
  module Sales
    class DetailsController < BaseController
      before_action :set_sale

      def edit
        # Validar se há itens antes de permitir avançar
        redirect_to edit_backoffice_sale_products_path(@sale) if @sale.sale_items.empty?
        
        @account_config = current_account.account_config
      end

      def update_payment
        payment_method = params[:payment_method]
        
        # Validação: se método de pagamento for "fiado", cliente é obrigatório
        if payment_method == "fiado" && @sale.customer_id.blank?
          @sale.errors.add(:customer_id, "é obrigatório para pagamento em fiado")
          render :edit, status: :unprocessable_entity
          return
        end

        # Criar ou atualizar payment
        if @sale.payment.blank?
          @sale.create_payment!(
            method: payment_method,
            status: "pending",
            amount: @sale.total_amount
          )
        else
          @sale.payment.update!(
            method: payment_method,
            amount: @sale.total_amount
          )
        end

        # Recalcular totais
        @sale.calculate_totals

        head :ok
      end

      def update_discount
        update_params = sale_params
        
        if @sale.update(update_params)
          # Recalcular totais
          @sale.calculate_totals
          head :ok
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def update_customer
        customer_id = params[:sale].present? ? params[:sale][:customer_id] : nil
        # Permitir remover cliente (customer_id vazio ou nil)
        customer_id = nil if customer_id.blank?
        
        if @sale.update(customer_id: customer_id)
          head :ok
        else
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def set_sale
        @sale = current_account.sales.with_drafts.draft.find(params[:sale_id])
      end

      def sale_params
        params.require(:sale).permit(:discount_amount, :discount_percentage)
      end
    end
  end
end
