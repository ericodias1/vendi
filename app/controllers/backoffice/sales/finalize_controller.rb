# frozen_string_literal: true

module Backoffice
  module Sales
    class FinalizeController < BaseController
      before_action :set_sale

      def edit
        # Validar se há itens antes de permitir avançar
        redirect_to edit_backoffice_sale_products_path(@sale) if @sale.sale_items.empty?
        redirect_to edit_backoffice_sale_details_path(@sale) if @sale.payment.blank?
      end

      def update
        service = Backoffice::Sales::FinalizeService.new(
          sale: @sale,
          current_user: current_user,
          send_payment_link: params[:send_payment_link] == '1',
          payment_received: params[:payment_received] == '1'
        )

        if service.call
          redirect_to backoffice_sale_path(@sale), notice: "Venda registrada com sucesso! 🎉"
        else
          flash.now[:alert] = "Erro ao finalizar venda: #{service.errors.full_messages.join(', ')}"
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def set_sale
        @sale = current_account.sales.with_drafts.draft.find(params[:sale_id])
      end
    end
  end
end
