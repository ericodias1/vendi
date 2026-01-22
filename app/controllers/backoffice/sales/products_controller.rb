# frozen_string_literal: true

module Backoffice
  module Sales
    class ProductsController < BaseController
      before_action :set_sale

      def edit
        # IDs dos produtos que já estão na venda
        product_ids_in_sale = @sale.sale_items.pluck(:product_id)
        
        # Lista de produtos (excluindo os que já estão na venda)
        @products = current_account.products.active.includes(:images_attachments)
        @products = @products.where.not(id: product_ids_in_sale) if product_ids_in_sale.any?
        @products = @products.search(params[:search]) if params[:search].present?
        @products = @products.limit(50)
        
        # Produtos recentes (mais vendidos nos últimos 7 dias)
        # Excluir produtos que já estão na venda
        @recent_products = current_account.products
                                          .joins(:stock_movements)
                                          .where(stock_movements: { movement_type: 'sale' })
                                          .where('stock_movements.created_at >= ?', 7.days.ago)
        @recent_products = @recent_products.where.not(id: product_ids_in_sale) if product_ids_in_sale.any?
        @recent_products = @recent_products.group('products.id')
                                           .order('COUNT(stock_movements.id) DESC')
                                           .limit(5)
      end

      def update
        # Validar se há itens antes de permitir avançar
        if @sale.sale_items.empty?
          redirect_to edit_backoffice_sale_products_path(@sale), alert: "Adicione pelo menos um produto"
          return
        end

        # Recalcular totais
        @sale.calculate_totals

        # Redirecionar para próximo step
        redirect_to edit_backoffice_sale_details_path(@sale)
      end

      private

      def set_sale
        @sale = current_account.sales.with_drafts.draft.find(params[:sale_id])
      end
    end
  end
end
