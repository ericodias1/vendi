# frozen_string_literal: true

module Backoffice
  class SalesController < BaseController
    before_action :set_sale, only: [:show, :destroy, :complete, :send_payment_link]

    def index
      @active_period = params[:period] || 'today'
      
      # Vendas finalizadas (excluindo drafts)
      @sales = current_account.sales
                              .includes(:customer, :payment, :sale_items)
                              .search(params[:search])
                              .by_period(@active_period)
                              .recent
      
      # Drafts (separados)
      @drafts = current_account.sales.with_drafts
                               .draft
                               .where(user: current_user)
                               .includes(:sale_items)
                               .order(created_at: :desc)
                               .limit(10)
    end

    def show
      # Permitir visualizar drafts (caso esteja editando)
      @sale = current_account.sales.with_drafts.includes(:sale_items, :payment, :customer).find(params[:id])
    end

    def new
      # Validar que current_account existe
      unless current_account
        redirect_to backoffice_root_path, alert: "Conta não encontrada. Entre em contato com o suporte."
        return
      end

      # Sempre criar novo draft
      @sale = current_account.sales.with_drafts.create!(
        account: current_account,
        user: current_user,
        status: "draft"
      )

      redirect_to edit_backoffice_sale_products_path(@sale)
    end


    def complete
      @sale.complete!
      redirect_to backoffice_sale_path(@sale), notice: "Pagamento confirmado com sucesso!"
    rescue StandardError => e
      redirect_to backoffice_sale_path(@sale), alert: "Erro ao confirmar pagamento: #{e.message}"
    end

    def destroy
      if @sale.can_cancel? || @sale.draft?
        @sale.cancel!(reason: params[:cancellation_reason], user: current_user) unless @sale.cancelled?
        redirect_to backoffice_sales_path, notice: "Venda cancelada com sucesso"
      else
        redirect_to backoffice_sale_path(@sale), alert: "Não é possível cancelar esta venda"
      end
    end

    def send_payment_link
      # TODO: Implementar envio de link de pagamento via WhatsApp
      redirect_to backoffice_sale_path(@sale), notice: "Link de pagamento enviado!"
    end

    private

    def set_sale
      @sale = current_account.sales.with_drafts.find(params[:id])
    end
  end
end
